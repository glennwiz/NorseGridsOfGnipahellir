package gnipahellir

import "core:fmt"
import rl "vendor:raylib"

TITLE :: "Gnipahellir"
WINDOW_WIDTH, WINDOW_HEIGHT :: 1024, 768
TARGET_FPS :: 60
CELL_SIZE :: 1

NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE
GRID_STATE :: [NUM_CELLS_X][NUM_CELLS_Y]Cell

ZOOM_MIN :: 1 // the whole board fits the window
ZOOM_MAX :: 60
GRID_LINES_MIN_ZOOM :: 6 // below this the lines would hide the cells
PAN_SPEED :: 10 // pixels per frame for the arrow keys


cell_life: bool
is_set: bool
zoom_level: i32 = 20 // pixels per cell

sim_running: bool
sim_speed: f64 = 30 // generations per second, COMMA / PERIOD double or halve it
SIM_SPEED_MIN :: 1
SIM_SPEED_MAX :: 1 << 20 // far past any CPU, so the top speed is whatever the budget allows
SIM_BUDGET :: 0.75 // share of each frame the simulation may use, the rest is for drawing
sim_debt: f64 // generations owed but not yet run, carried between frames
REVERSE_SPEED :: 8 // frames per generation when running backwards (7.5 generations/sec)

// One moment of the simulation. Earlier ones are kept in history (see history.odin).
Board :: struct {
	cells:      GRID_STATE,
	generation: int,
}

board: Board // the live board, drawn and edited
scratch: GRID_STATE // next generation is built here, then copied into board

Cell :: struct {
	alive: bool,
	age:   u8,
}

Runes :: enum {
	F,
	O,
	R,
	Empty,
}

Static_rune_render := Runes.O


offset_x: i32
offset_y: i32

main :: proc() {

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	reverse_counter: i32 = 0
	build_age_palette()
	print_commands()
	update_camera()

	for !rl.WindowShouldClose() {

		handle_input()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_background()
		draw_cells()
		draw_grid()

		rl.EndDrawing()

		// Tap BACKSPACE for one generation back, hold it to keep going
		if rl.IsKeyPressed(.BACKSPACE) {
			sim_running = false
			reverse_counter = 0
		}
		if rl.IsKeyDown(.BACKSPACE) {
			if reverse_counter % REVERSE_SPEED == 0 {
				step_back()
			}
			reverse_counter += 1
		} else if sim_running {
			run_sim(rl.GetFrameTime())
		}
	}
}

// Run the generations sim_speed asks for this frame, but stop once the frame's
// time budget is spent so drawing and input stay smooth. Whatever doesn't fit
// is dropped, so at high speeds this runs as fast as the CPU can go.
run_sim :: proc(dt: f32) {
	sim_debt += f64(dt) * sim_speed
	deadline := rl.GetTime() + SIM_BUDGET / TARGET_FPS
	for sim_debt >= 1 {
		step()
		sim_debt -= 1
		if rl.GetTime() > deadline {
			sim_debt = 0
			break
		}
	}
}


run_next_generation :: proc(src, dst: ^GRID_STATE) {
	// Skip the outermost ring of cells so every neighbour is inside the grid.
	// The ring is never written, so it stays dead and acts as the board's edge.
	for x: i32 = 1; x < NUM_CELLS_X - 1; x += 1 {
		for y: i32 = 1; y < NUM_CELLS_Y - 1; y += 1 {
			/*
            Any live cell with two or three live neighbours survives too the next generation.
            Any dead cell with exactly three live neighbours becomes a live cell.
            */
			live_neighbours := count_live_neighbours(src, x, y)
			cell := src[x][y]
			alive := update_cell_state(cell.alive, live_neighbours)

			// Survivors get one generation older, newborns start at 0
			age: u8 = 0
			if alive && cell.alive {
				age = min(cell.age + 1, AGE_MAX)
			}
			dst[x][y] = Cell{alive, age}
		}
	}
}

/*
    function count_live_neighbours calculates the number of live neighbors around a cell in grid.
    It uses nested loops to examine a 3x3 cell neighborhood centered at (x, y).
    (x, y) must not be on the edge of the grid, see run_next_generation.
    The function returns the count of live neighbors for the specified cell.
    The grid is passed by pointer to avoid copying the whole (large) grid on every call.
*/
count_live_neighbours := proc(grid: ^GRID_STATE, x, y: i32) -> i32 {
	live_neighbours: i32 = 0
	for nx := x - 1; nx <= x + 1; nx += 1 {
		for ny := y - 1; ny <= y + 1; ny += 1 {
			if !(nx == x && ny == y) && grid[nx][ny].alive {
				live_neighbours += 1
			}
		}
	}

	return live_neighbours
}

update_cell_state := proc(is_alive: bool, live_neighbours: i32) -> bool {
	if is_alive {
		if live_neighbours == 2 || live_neighbours == 3 {
			return true
		}
		return false
	} else {
		if live_neighbours == 3 {
			return true
		}
		return false
	}
}

handle_mouse_input :: proc(mouse_x, mouse_y: i32) {
	// Check if the mouse is outside the grid (before dividing, since
	// integer division rounds -0.5 cells to 0)
	if mouse_x < offset_x || mouse_y < offset_y {
		return
	}

	// Screen pixel -> world cell (inverse of draw_cell_run).
	cell_x := (mouse_x - offset_x) / zoom_level
	cell_y := (mouse_y - offset_y) / zoom_level
	if cell_x >= NUM_CELLS_X || cell_y >= NUM_CELLS_Y {
		return
	}

	// On the first cell of a drag, decide whether we are drawing or erasing
	// based on the cell under the cursor, then keep that for the whole drag.
	if !is_set {
		cell_life = !board.cells[cell_x][cell_y].alive
		is_set = true
	}
	board.cells[cell_x][cell_y] = Cell {
		alive = cell_life,
	}
}

draw_cell_run :: proc(x, y, width: i32, color: rl.Color) {
	rect_x := x * zoom_level + offset_x
	rect_y := y * zoom_level + offset_y
	rect_w := width * zoom_level
	rect_h := zoom_level

	rl.DrawRectangle(rect_x, rect_y, rect_w, rect_h, color)
}

// Centre the view on the focus cell
update_camera :: proc() {
	offset_x = WINDOW_WIDTH / 2 - RUNE_CENTER_X * zoom_level
	offset_y = WINDOW_HEIGHT / 2 - RUNE_CENTER_Y * zoom_level
}

// Zoom in (steps > 0) or out, keeping the world point under the
// screen pixel (anchor_x, anchor_y) in place.
zoom_at :: proc(steps: i32, anchor_x, anchor_y: i32) {
	// Step size grows with the zoom so the wheel feels even at every level
	new_zoom := clamp(zoom_level + steps * max(1, zoom_level / 5), ZOOM_MIN, ZOOM_MAX)
	if new_zoom == zoom_level {
		return
	}

	world_x := f32(anchor_x - offset_x) / f32(zoom_level)
	world_y := f32(anchor_y - offset_y) / f32(zoom_level)
	zoom_level = new_zoom
	offset_x = anchor_x - i32(world_x * f32(zoom_level))
	offset_y = anchor_y - i32(world_y * f32(zoom_level))
	clamp_camera()
}

pan :: proc(dx, dy: i32) {
	offset_x += dx
	offset_y += dy
	clamp_camera()
}

// Keep the screen centre over the board so it can't be panned out of sight
clamp_camera :: proc() {
	offset_x = clamp(offset_x, WINDOW_WIDTH / 2 - NUM_CELLS_X * zoom_level, WINDOW_WIDTH / 2)
	offset_y = clamp(offset_y, WINDOW_HEIGHT / 2 - NUM_CELLS_Y * zoom_level, WINDOW_HEIGHT / 2)
}

print_commands :: proc() {
	fmt.println("Available Commands:")
	fmt.println("------------------")
	fmt.println("Keyboard Commands:")
	fmt.println("1. ESCAPE: Exit the game loop")
	fmt.println("2. X / Z: Zoom in / out (around the screen centre)")
	fmt.println("3. Arrow keys: Pan the camera")
	fmt.println("   C: Re-centre the camera")
	fmt.println("4. SPACE: Toggle simulation running state")
	fmt.println("5. COMMA: Double simulation speed (keeps going up to what the CPU can handle)")
	fmt.println("6. PERIOD: Halve simulation speed")
	fmt.println("7. O: Set Static_rune_render to Runes.O")
	fmt.println("8. F: Set Static_rune_render to Runes.F")
	fmt.println("9. R: Set Static_rune_render to Runes.R")
	fmt.println("10. F1: Clear the grid")
	fmt.println("11. G: Toggle age colours")
	fmt.println("12. BACKSPACE: Step backwards, hold to keep going (pauses the simulation)")
	fmt.println()
	fmt.println("Pattern Keys:")
	for pk in PATTERN_KEYS {
		fmt.printfln("%v: %s", pk.key, pk.name)
	}
	fmt.println()
	fmt.println("Mouse Commands:")
	fmt.println("Left mouse button click: Toggle cell state")
	fmt.println("Left mouse button drag: Draw cells")
	fmt.println("Mouse wheel: Zoom in / out around the cursor")
	fmt.println("Right mouse button drag: Pan the camera")
}

handle_input :: proc() {

	// Camera
	if rl.IsKeyPressed(.X) {
		zoom_at(1, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)
	}
	if rl.IsKeyPressed(.Z) {
		zoom_at(-1, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)
	}
	if wheel := rl.GetMouseWheelMove(); wheel != 0 {
		zoom_at(wheel > 0 ? 1 : -1, rl.GetMouseX(), rl.GetMouseY())
	}
	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		pan(i32(delta.x), i32(delta.y))
	}
	if rl.IsKeyDown(.LEFT) {pan(PAN_SPEED, 0)}
	if rl.IsKeyDown(.RIGHT) {pan(-PAN_SPEED, 0)}
	if rl.IsKeyDown(.UP) {pan(0, PAN_SPEED)}
	if rl.IsKeyDown(.DOWN) {pan(0, -PAN_SPEED)}
	if rl.IsKeyPressed(.C) {
		update_camera()
	}

	if rl.IsKeyPressed(.SPACE) {
		sim_running = !sim_running
	}
	if rl.IsKeyPressed(.COMMA) {
		sim_speed = min(sim_speed * 2, SIM_SPEED_MAX)
		fmt.printfln("speed: %v generations/sec", sim_speed)
	}
	if rl.IsKeyPressed(.PERIOD) {
		sim_speed = max(sim_speed / 2, SIM_SPEED_MIN)
		fmt.printfln("speed: %v generations/sec", sim_speed)
	}
	if rl.IsKeyPressed(.O) {
		clear()
		Static_rune_render = Runes.O
	}
	if rl.IsKeyPressed(.F) {
		clear()
		Static_rune_render = Runes.F
	}
	if rl.IsKeyPressed(.R) {
		clear()
		Static_rune_render = Runes.R
	}
	for pk in PATTERN_KEYS {
		if rl.IsKeyPressed(pk.key) {
			clear()
			place_pattern(pk.key)
		}
	}
	if rl.IsKeyPressed(.F1) {
		clear()
	}
	if rl.IsKeyPressed(.G) {
		show_age_colors = !show_age_colors
	}

	// Handle Mouse Input
	if rl.IsMouseButtonDown(.LEFT) {
		handle_mouse_input(rl.GetMouseX(), rl.GetMouseY())
	}
	if rl.IsMouseButtonReleased(.LEFT) {
		is_set = false
	}

}

draw_cells :: proc() {
	#partial switch Static_rune_render {
	case .O:
		get_rune_o()
	case .F:
		get_rune_f()
	case .R:
		get_rune_r()
	}

	// Draw the cells, batching each row into runs of the same colour
	for y: i32 = 0; y < NUM_CELLS_Y; y += 1 {

		batch_start_x: i32 = -1
		batch_color: rl.Color

		// x == NUM_CELLS_X is one past the row, so the last run gets flushed
		for x: i32 = 0; x <= NUM_CELLS_X; x += 1 {
			alive := x < NUM_CELLS_X && board.cells[x][y].alive
			color: rl.Color
			if alive {
				color = cell_color(board.cells[x][y])
			}

			if batch_start_x != -1 && (!alive || color != batch_color) {
				draw_cell_run(batch_start_x, y, x - batch_start_x, batch_color)
				batch_start_x = -1
			}
			if alive && batch_start_x == -1 {
				batch_start_x = x
				batch_color = color
			}
		}
	}
}

draw_grid :: proc() {
	if zoom_level < GRID_LINES_MIN_ZOOM {
		return // the lines would hide the cells
	}
	for x := offset_x %% zoom_level; x < WINDOW_WIDTH; x += zoom_level {
		rl.DrawLine(x, 0, x, WINDOW_HEIGHT, rl.BLACK)
	}
	for y := offset_y %% zoom_level; y < WINDOW_HEIGHT; y += zoom_level {
		rl.DrawLine(0, y, WINDOW_WIDTH, y, rl.BLACK)
	}
}

draw_background :: proc() {
	rl.DrawRectangleGradientH(
		0,
		0,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		rl.Color{0, 0, 0, 255},
		rl.Color{60, 60, 60, 255},
	)
}

clear :: proc() { 	// Clear the grid and reset all related variables
	Static_rune_render = Runes.Empty
	board = {}
	clear_history()

	sim_running = false

	update_camera() // recentre the view
}
