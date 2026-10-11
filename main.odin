package gnipahellir

import "core:fmt"
import rl "vendor:raylib"

TITLE :: "Gnipahellir"
WINDOW_WIDTH, WINDOW_HEIGHT :: 500, 500
TARGET_FPS :: 60

NUM_CELLS_X :: WINDOW_WIDTH
NUM_CELLS_Y :: WINDOW_HEIGHT

GRID_STATE :: [NUM_CELLS_X][NUM_CELLS_Y]Cell

ZOOM_MIN :: 1
ZOOM_MAX :: 60
GRID_LINES_MIN_ZOOM :: 6

cell_life: bool
is_set: bool
zoom_level: i32 = 20
sim_running: bool

sim_speed: f32 = 1
SIM_SPEED_MIN :: 1
SIM_SPEED_MAX :: 32

delta_time: f32

grid: GRID_STATE
buffer_grid: GRID_STATE

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

Static_rune_render := Runes.Empty

offset_x: i32
offset_y: i32

main :: proc() {

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	setup()

	for !rl.WindowShouldClose() {

		handle_input()

		draw_loop()

		if sim_running {
			delta_time += rl.GetFrameTime()
			if delta_time >= 1.0 / sim_speed {

				run_conways_rules()

				delta_time = 0
			}
		}
	}
}

run_conways_rules :: proc() {
	for x: i32 = 1; x < NUM_CELLS_X - 1; x += 1 {
		for y: i32 = 1; y < NUM_CELLS_Y - 1; y += 1 {
			cell := grid[x][y]
			neighbours := count_live_neighbours(&grid, x, y)

			alive := neighbours == 3 || (cell.alive && neighbours == 2)
			age: u8 = 0

			if alive && cell.alive {
				age = min(cell.age + 1, AGE_MAX)
			}

			buffer_grid[x][y] = Cell{alive, age}
		}
	}

	grid = buffer_grid
}

//(-1,-1), (0, -1), (1,-1)
//(-1, 0), (0,  0), (1, 0)
//(-1, 1), (0,  1), (1, 1)
count_live_neighbours :: proc(cells: ^GRID_STATE, x, y: i32) -> i32 {
	count: i32 = 0

	for dx: i32 = -1; dx <= 1; dx += 1 {
		for dy: i32 = -1; dy <= 1; dy += 1 {
			if (dx != 0 || dy != 0) && cells[x + dx][y + dy].alive {
				count += 1
			}
		}
	}

	return count
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

setup :: proc() {
	build_age_palette()
	print_commands()
	update_camera()
}
