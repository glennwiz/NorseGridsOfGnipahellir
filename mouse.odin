package gnipahellir


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
