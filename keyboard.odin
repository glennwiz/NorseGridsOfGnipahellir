package gnipahellir

import "core:fmt"
import rl "vendor:raylib"
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
	if rl.IsKeyPressed(.PERIOD) {
		sim_speed = min(sim_speed * 2, SIM_SPEED_MAX)
		fmt.printfln("speed: %v generations/sec", sim_speed)
	}
	if rl.IsKeyPressed(.COMMA) {
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
