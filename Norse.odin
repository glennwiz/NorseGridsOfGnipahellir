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

cell_life: bool
is_set: bool

zoom_level: i32 = 20
zoom_step: i32 = 2
ZOOM_MIN :: 2
ZOOM_MAX :: 20

sim_running: bool
sim_speed: i32 = 60
sim_speed_step: i32 = 5

grid_buffer_a: GRID_STATE
grid_buffer_b: GRID_STATE
grid_state: ^GRID_STATE
next_grid_state: ^GRID_STATE

Cell :: struct {
	alive: bool,
}

Runes :: enum {
	F,
	O,
	R,
	Empty,
}

Static_rune_render := Runes.O

// Camera: the world cell kept centred on screen, plus the derived
// pixel offset used when drawing. update_camera() recomputes the offset
// from the current zoom so the focus stays put while zooming.
FOCUS_X :: 156
FOCUS_Y :: 120

offset_x: i32
offset_y: i32

main :: proc() {
	grid_state = &grid_buffer_a
	next_grid_state = &grid_buffer_b

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	counter: i32 = 0
	print_commands()
	update_camera()

	for !rl.WindowShouldClose() {

		handle_input()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		// Drawing gradient from black to grey
		rl.DrawRectangleGradientH(
			0,
			0,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			rl.Color{0, 0, 0, 255},
			rl.Color{60, 60, 60, 255},
		)

		#partial switch Static_rune_render {
		case .O:
			get_rune_o()
		case .F:
			get_rune_f()
		case .R:
			get_rune_r()
		}

		// Draw the cell at locations by the grid
		for y: i32 = 0; y < NUM_CELLS_Y; y += 1 {

			batch_start_x: i32 = -1
			batch_width: i32 = 0

			for x: i32 = 0; x < NUM_CELLS_X; x += 1 {
				if grid_state[x][y].alive {
					if batch_start_x == -1 {
						batch_start_x = x
					}
					batch_width += 1
				} else {
					if batch_start_x != -1 {
						draw_cell_run(batch_start_x, y, batch_width)
						batch_start_x = -1
						batch_width = 0
					}
				}
			}
			if batch_start_x != -1 {
				// Draw the last run in the row if it ends with alive cells
				draw_cell_run(batch_start_x, y, batch_width)
			}
		}

		// Grid lines on cell boundaries (aligned to the camera offset)
		for x := offset_x %% zoom_level; x < WINDOW_WIDTH; x += zoom_level {
			rl.DrawLine(x, 0, x, WINDOW_HEIGHT, rl.BLACK)
		}

		for y := offset_y %% zoom_level; y < WINDOW_HEIGHT; y += zoom_level {
			rl.DrawLine(0, y, WINDOW_WIDTH, y, rl.BLACK)
		}


		rl.EndDrawing()

		if sim_running && counter % sim_speed == 0 {
			run_next_generation()
			// swap the buffers (O(1) pointer swap)
			grid_state, next_grid_state = next_grid_state, grid_state
		}

		counter += 1
		if counter >= sim_speed {
			counter = 0
		}
	}
}

Clear :: proc() { 	// Clear the grid and reset all related variables
	Static_rune_render = Runes.Empty
	for x: i32 = 0; x < NUM_CELLS_X; x += 1 {
		for y: i32 = 0; y < NUM_CELLS_Y; y += 1 {
			grid_state[x][y].alive = false
			next_grid_state[x][y].alive = false
		}
	}

	sim_running = false

	update_camera() // recentre the view
}

run_next_generation :: proc() {
	//simulate the next generation
	for x: i32 = 0; x < NUM_CELLS_X; x += 1 {
		for y: i32 = 0; y < NUM_CELLS_Y; y += 1 {
			/*
            Any live cell with fewer than two live neighbours dies, as if by underpopulation.
            Any live cell with two or three live neighbours lives on to the next generation.
            Any live cell with more than three live neighbours dies, as if by overpopulation.
            Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
            */
			live_neighbours := count_live_neighbours(grid_state, x, y)
			next_grid_state[x][y].alive = update_cell_state(
				grid_state[x][y].alive,
				live_neighbours,
			)
		}
	}
}

/*
    function count_live_neighbours calculates the number of live neighbors around a cell in a toroidal grid represented by grid.
    It uses nested loops to examine a 3x3 cell neighborhood centered at (x, y) while handling boundary wrapping.
    The function returns the count of live neighbors for the specified cell.
    The grid is passed by pointer to avoid copying the whole (large) grid on every call.
*/
count_live_neighbours := proc(grid: ^GRID_STATE, x, y: i32) -> i32 {
	live_neighbours: i32 = 0
	// Handle Keyboard Input
	for nx := x - 1; nx <= x + 1; nx += 1 {
		for ny := y - 1; ny <= y + 1; ny += 1 {
			// Wrap around horizontally
			wrapped_nx := (nx + NUM_CELLS_X) % NUM_CELLS_X
			// Wrap around vertically
			wrapped_ny := (ny + NUM_CELLS_Y) % NUM_CELLS_Y

			if !(wrapped_nx == x && wrapped_ny == y) && grid[wrapped_nx][wrapped_ny].alive {
				live_neighbours += 1
			}
		}
	}

	return live_neighbours
}

update_cell_state := proc(is_alive: bool, live_neighbours: i32) -> bool {
	if is_alive {

		if live_neighbours < 2 || live_neighbours > 3 {

			return false
		}
		return true
	} else {

		if live_neighbours == 3 {

			return true
		}
		return false
	}
}

handle_mouse_input :: proc(mouse_x, mouse_y: i32) {
	// Screen pixel -> world cell (inverse of draw_cell_run).
	cell_x := (mouse_x - offset_x) / zoom_level
	cell_y := (mouse_y - offset_y) / zoom_level

	// Check if the mouse is outside the grid
	if cell_x < 0 || cell_x >= NUM_CELLS_X || cell_y < 0 || cell_y >= NUM_CELLS_Y {
		return
	}

	// On the first cell of a drag, decide whether we are drawing or erasing
	// based on the cell under the cursor, then keep that for the whole drag.
	if !is_set {
		cell_life = !grid_state[cell_x][cell_y].alive
		is_set = true
	}
	grid_state[cell_x][cell_y].alive = cell_life
}

draw_cell_run :: proc(x, y, width: i32) {
	rect_x := x * zoom_level + offset_x
	rect_y := y * zoom_level + offset_y
	rect_w := width * zoom_level
	rect_h := zoom_level

	rl.DrawRectangle(rect_x, rect_y, rect_w, rect_h, rl.Color{100, 0, 0, 255})
}

// Keep the focus cell centred on screen and show grid lines
update_camera :: proc() {
	offset_x = WINDOW_WIDTH / 2 - FOCUS_X * zoom_level
	offset_y = WINDOW_HEIGHT / 2 - FOCUS_Y * zoom_level
}

print_commands :: proc() {
	fmt.println("Available Commands:")
	fmt.println("------------------")
	fmt.println("Keyboard Commands:")
	fmt.println("1. ESCAPE: Exit the game loop")
	fmt.println("2. X: Increase zoom level")
	fmt.println("3. Z: Decrease zoom level")
	fmt.println("4. SPACE: Toggle simulation running state")
	fmt.println("5. COMMA: Increase simulation speed")
	fmt.println("6. PERIOD: Decrease simulation speed")
	fmt.println("7. O: Set Static_rune_render to Runes.O")
	fmt.println("8. F: Set Static_rune_render to Runes.F")
	fmt.println("9. R: Set Static_rune_render to Runes.R")
	fmt.println("10. F1: Clear the grid")
	fmt.println()
	fmt.println("Mouse Commands:")
	fmt.println("11. Left mouse button click: Toggle cell state")
	fmt.println("12. Left mouse button drag: Draw cells")
}

handle_input :: proc() {

	if rl.IsKeyPressed(.X) {
		zoom_level += zoom_step
		if zoom_level > ZOOM_MAX {
			zoom_level = ZOOM_MAX
		}
		update_camera()
	}
	if rl.IsKeyPressed(.Z) {
		zoom_level -= zoom_step
		if zoom_level < ZOOM_MIN {
			zoom_level = ZOOM_MIN
		}
		update_camera()
	}
	if rl.IsKeyPressed(.SPACE) {
		sim_running = !sim_running
	}
	if rl.IsKeyPressed(.COMMA) {
		sim_speed += sim_speed_step
		if sim_speed > 100 {
			sim_speed = 100
		}
	}
	if rl.IsKeyPressed(.PERIOD) {
		sim_speed -= sim_speed_step
		if sim_speed < 1 {
			sim_speed = 1
		}
	}
	if rl.IsKeyPressed(.O) {
		Clear()
		Static_rune_render = Runes.O
	}
	if rl.IsKeyPressed(.F) {
		Clear()
		Static_rune_render = Runes.F
	}
	if rl.IsKeyPressed(.R) {
		Clear()
		Static_rune_render = Runes.R
	}
	if rl.IsKeyPressed(.F1) {
		Clear()
	}

	// Handle Mouse Input
	if rl.IsMouseButtonDown(.LEFT) {
		handle_mouse_input(rl.GetMouseX(), rl.GetMouseY())
	}
	if rl.IsMouseButtonReleased(.LEFT) {
		is_set = false
	}

}
