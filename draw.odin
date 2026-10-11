package gnipahellir
import "core:fmt"
import rl "vendor:raylib"
draw_cell_run :: proc(x, y, width: i32, color: rl.Color) {
	rect_x := x * zoom_level + offset_x
	rect_y := y * zoom_level + offset_y
	rect_w := width * zoom_level
	rect_h := zoom_level

	rl.DrawRectangle(rect_x, rect_y, rect_w, rect_h, color)
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
			alive := x < NUM_CELLS_X && grid[x][y].alive
			color: rl.Color
			if alive {
				color = cell_color(grid[x][y])
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
	grid = {}

	sim_running = false

	update_camera() // recentre the view
}

draw_loop :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	draw_background()
	draw_cells()
	draw_grid()
	rl.EndDrawing()
}
