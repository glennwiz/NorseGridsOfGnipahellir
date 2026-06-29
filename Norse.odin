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

bug_mode_flipper: bool = false
bug_mode_flipper_count := 0
bug_mode: bool = false
sim_running: bool
sim_speed: i32 = 60
sim_speed_step: i32 = 5
grid_show: bool = false

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

offset_x_o: i32 = -2800
offset_y_o: i32 = -2160

offset_x: i32 = -2800
offset_y: i32 = -2160

main :: proc() {
	grid_state = &grid_buffer_a
	next_grid_state = &grid_buffer_b

	rl.SetConfigFlags({.WINDOW_UNDECORATED, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()
	rl.SetTargetFPS(TARGET_FPS)

	counter: i32 = 0
	print_commands()
	run_draw_sync() // initialise zoom-derived offset and grid visibility

	for !rl.WindowShouldClose() {
		// Handle Keyboard Input
		if rl.IsKeyPressed(.X) {
			zoom_level += zoom_step
			if zoom_level > 20 {
				zoom_level = 20
			}
			run_draw_sync()
		}
		if rl.IsKeyPressed(.Z) {
			zoom_level -= zoom_step
			if zoom_level < 2 {
				zoom_level = 2
			}
			run_draw_sync()
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
		if rl.IsKeyPressed(.M) {
			bug_mode = !bug_mode
		}
		if rl.IsKeyPressed(.N) {
			if bug_mode_flipper {
				bug_mode_flipper_count += 1
			} else {
				bug_mode_flipper = !bug_mode_flipper
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

		// Drawing black grid lines spaced by the zoom level
		if (grid_show) {
			for x: i32 = 0; x < WINDOW_WIDTH; x += zoom_level {
				rl.DrawLine(x, 0, x, WINDOW_HEIGHT, rl.BLACK)
			}

			for y: i32 = 0; y < WINDOW_HEIGHT; y += zoom_level {
				rl.DrawLine(0, y, WINDOW_WIDTH, y, rl.BLACK)
			}
		}

		rl.EndDrawing()

		if sim_running && counter % sim_speed == 0 {

			run_next_generation()

			if !bug_mode {
				// swap the buffers (O(1) pointer swap)
				grid_state, next_grid_state = next_grid_state, grid_state
			}
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
	bug_mode = false
	bug_mode_flipper = false
	bug_mode_flipper_count = 0
	offset_x = offset_x_o
	offset_y = offset_y_o

	run_draw_sync() // Update the display
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

			if bug_mode {
				grid_state[x][y].alive = update_cell_state(grid_state[x][y].alive, live_neighbours)
				next_grid_state[x][y].alive = update_cell_state(
					grid_state[x][y].alive,
					live_neighbours,
				)

			} else {

				next_grid_state[x][y].alive = update_cell_state(
					grid_state[x][y].alive,
					live_neighbours,
				)
			}
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
	scaled_mouse_x := mouse_x / zoom_level
	scaled_mouse_y := mouse_y / zoom_level

	scaled_mouse_x -= offset_x / zoom_level
	scaled_mouse_y -= offset_y / zoom_level

	// Check if the mouse is outside the grid
	if scaled_mouse_x < 0 ||
	   scaled_mouse_x >= NUM_CELLS_X ||
	   scaled_mouse_y < 0 ||
	   scaled_mouse_y >= NUM_CELLS_Y {
		return
	}

	// On the first cell of a drag, decide whether we are drawing or erasing
	// based on the cell under the cursor, then keep that for the whole drag.
	if !is_set {
		cell_life = !grid_state[scaled_mouse_x][scaled_mouse_y].alive
		is_set = true
	}
	grid_state[scaled_mouse_x][scaled_mouse_y].alive = cell_life
}

draw_cell_run :: proc(x, y, width: i32) {
	rect_x := x * CELL_SIZE * zoom_level + offset_x
	rect_y := y * CELL_SIZE * zoom_level + offset_y
	rect_w := width * CELL_SIZE * zoom_level
	rect_h := CELL_SIZE * zoom_level

	rl.DrawRectangle(rect_x, rect_y, rect_w, rect_h, rl.Color{100, 0, 0, 255})
}

run_draw_sync :: proc() {
	calc_offset()
	turn_on_off_grid()
}

calc_offset := proc() {
	offset_x = i32(map_range_value(f32(zoom_level), -2800.0))
	offset_y = i32(map_range_value(f32(zoom_level), -2160.0))
}

map_range_value :: proc(
	input_value: f32,
	value_end: f32,
	range_start: f32 = 2.0,
	range_end: f32 = 20.0,
	value_start: f32 = 0.0,
) -> f32 {
	proportion := (input_value - range_start) / (range_end - range_start)
	mapped_value := proportion * (value_end - value_start) + value_start
	return mapped_value
}

turn_on_off_grid :: proc() {
	if (zoom_level == 2 || zoom_level == 4 || zoom_level == 20) {
		grid_show = true
	} else {
		grid_show = false
	}
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
	fmt.println("7. M: Toggle bug mode")
	fmt.println("8. N: Toggle bug mode flipper")
	fmt.println("9. O: Set Static_rune_render to Runes.O")
	fmt.println("10. F: Set Static_rune_render to Runes.F")
	fmt.println("11. R: Set Static_rune_render to Runes.R")
	fmt.println("12. F1: Clear the grid")
	fmt.println()
	fmt.println("Mouse Commands:")
	fmt.println("13. Left mouse button click: Toggle cell state")
	fmt.println("14. Left mouse button drag: Draw cells")
}
