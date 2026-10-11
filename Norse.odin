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
sim_speed: f64 = 1 // generations per second, COMMA / PERIOD double or halve it
SIM_SPEED_MIN :: 1
SIM_SPEED_MAX :: 32 // far past any CPU, so the top speed is whatever the budget allows
time_since_step: f64 // seconds passed since the last generation

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

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_loop()
		rl.EndDrawing()

		if sim_running {
			run_sim(rl.GetFrameTime())
		}
	}
}

step :: proc() {
	run_next_generation(&board.cells, &scratch)
	board.cells = scratch
	board.generation += 1
}

run_sim :: proc(dt: f32) {
	time_since_step += f64(dt)

	if time_since_step >= 1.0 / f64(sim_speed) {
		step()
		time_since_step = 0
	}
}

run_next_generation :: proc(src, dst: ^GRID_STATE) {
	for x: i32 = 1; x < NUM_CELLS_X - 1; x += 1 {
		for y: i32 = 1; y < NUM_CELLS_Y - 1; y += 1 {
			cell := src[x][y]
			neighbours := count_live_neighbours(src, x, y)

			alive := neighbours == 3 || (cell.alive && neighbours == 2)
			age: u8 = 0

			if alive && cell.alive {
				age = min(cell.age + 1, AGE_MAX)
			}

			dst[x][y] = Cell{alive, age}
		}
	}
}

count_live_neighbours :: proc(grid: ^GRID_STATE, x, y: i32) -> i32 {
	count: i32 = 0

	for dx: i32 = -1; dx <= 1; dx += 1 {
		for dy: i32 = -1; dy <= 1; dy += 1 {
			if (dx != 0 || dy != 0) && grid[x + dx][y + dy].alive {
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
