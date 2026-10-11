package gnipahellir


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
