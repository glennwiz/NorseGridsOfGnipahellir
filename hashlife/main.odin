package hashlife

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

TITLE :: "Gnipahellir - Hashlife"
WINDOW_WIDTH, WINDOW_HEIGHT :: 1200, 800
TARGET_FPS :: 60

// The zoom is a power of two: 2^zoom pixels per cell, negative when zoomed out
ZOOM_MIN :: -130
ZOOM_MAX :: 5
CELL_GAP_MIN_ZOOM :: 3 // from here cells are drawn with a gap between them

PAN_SPEED :: 10

Pattern :: struct {
	key:      rl.KeyboardKey,
	name:     string,
	data:     string,
	step_exp: int, // a step size that is nice to watch
}

// The computer is from https://github.com/nicolasloizeau/gol-computer and
// the Turing machine from Golly's pattern collection.
PATTERNS := [?]Pattern {
	{.ONE, "3-state Turing machine (Paul Rendell)", #load("patterns/turing-machine.rle", string), 6},
	{.TWO, "8-bit programmable computer (Nicolas Loizeau)", #load("patterns/computer.mc", string), 4},
	{.THREE, "Gosper glider gun", "24bo$22bobo$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o$2o8bo3bob2o4bobo$10bo5bo7bo$11bo3bo$12b2o!", 0},
	{.FOUR, "R-pentomino", "b2o$2o$bo!", 0},
	{.F1, "Switchengine meets backrake (Bill Gosper)", #load("patterns/switchengine-backrake.mc", string), 4},
	{.F2, "Two-digit hexadecimal counter (Brice Due)", #load("patterns/hexadecimal.mc", string), 12},
}

pattern_name: string
pattern_data: string
pattern_step_exp: int

sim_running: bool
step_ms: f64
step_failed: bool

// World position at the centre of the screen. (0, 0) is the centre of the root.
cam_x, cam_y: f64
zoom: int

pixels: []rl.Color
screen: rl.Texture2D

main :: proc() {
	if len(os.args) > 1 {
		data, err := os.read_entire_file(os.args[1], context.allocator)
		if err != nil {
			fmt.eprintfln("could not read %s: %v", os.args[1], err)
			return
		}
		pattern_name = os.args[1]
		pattern_data = string(data)
	} else {
		pattern_name = PATTERNS[0].name
		pattern_data = PATTERNS[0].data
		pattern_step_exp = PATTERNS[0].step_exp
	}

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	pixels = make([]rl.Color, WINDOW_WIDTH * WINDOW_HEIGHT)
	image := rl.GenImageColor(WINDOW_WIDTH, WINDOW_HEIGHT, rl.BLACK)
	screen = rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)

	print_commands()
	restart()

	for !rl.WindowShouldClose() {

		handle_input()

		if sim_running {
			timed_step()
		}

		draw_loop()
	}
}

restart :: proc() {
	sim_running = false
	step_ms = 0
	step_failed = false
	load_pattern(pattern_data)
	set_step_exp(pattern_step_exp)
	fit_view()
}

timed_step :: proc() {
	start := time.now()
	step_failed = !step()
	step_ms = time.duration_milliseconds(time.since(start))

	if step_failed {
		// Too many new nodes for one step: stop and try a smaller one
		sim_running = false
		set_step_exp(step_exp - 1)
	}
}

print_commands :: proc() {
	fmt.println("Available Commands:")
	fmt.println("------------------")
	fmt.println("ESCAPE: Exit")
	fmt.println("SPACE: Toggle simulation running state")
	fmt.println("S: Single step")
	fmt.println("PERIOD / COMMA: Double / halve the generations per step")
	fmt.println("X / Z, mouse wheel: Zoom in / out")
	fmt.println("Arrow keys, right mouse button drag: Pan the camera")
	fmt.println("C: Fit the pattern to the window")
	fmt.println("R: Restart the pattern")
	fmt.println()
	fmt.println("Pattern Keys:")
	for p in PATTERNS {
		fmt.printfln("%v: %s", p.key, p.name)
	}
	fmt.println()
	fmt.println("Or pass a .rle or .mc file: odin run hashlife -- my_pattern.mc")
}

handle_input :: proc() {
	if rl.IsKeyPressed(.X) {
		zoom_at(1, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)
	}
	if rl.IsKeyPressed(.Z) {
		zoom_at(-1, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)
	}
	if wheel := rl.GetMouseWheelMove(); wheel != 0 {
		zoom_at(wheel > 0 ? 1 : -1, f64(rl.GetMouseX()), f64(rl.GetMouseY()))
	}
	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		pan(f64(delta.x), f64(delta.y))
	}
	if rl.IsKeyDown(.LEFT) {pan(PAN_SPEED, 0)}
	if rl.IsKeyDown(.RIGHT) {pan(-PAN_SPEED, 0)}
	if rl.IsKeyDown(.UP) {pan(0, PAN_SPEED)}
	if rl.IsKeyDown(.DOWN) {pan(0, -PAN_SPEED)}
	if rl.IsKeyPressed(.C) {
		fit_view()
	}

	if rl.IsKeyPressed(.SPACE) {
		sim_running = !sim_running
	}
	if rl.IsKeyPressed(.S) {
		sim_running = false
		timed_step()
	}
	if rl.IsKeyPressed(.PERIOD) {
		set_step_exp(step_exp + 1)
	}
	if rl.IsKeyPressed(.COMMA) {
		set_step_exp(step_exp - 1)
	}
	if rl.IsKeyPressed(.R) {
		restart()
	}
	for p in PATTERNS {
		if rl.IsKeyPressed(p.key) {
			pattern_name = p.name
			pattern_data = p.data
			pattern_step_exp = p.step_exp
			restart()
		}
	}
}

// Pixels per cell
scale :: proc() -> f64 {
	return math.pow(2, f64(zoom))
}

// Zoom in (steps > 0) or out, keeping the world point under the
// screen pixel (anchor_x, anchor_y) in place.
zoom_at :: proc(steps: int, anchor_x, anchor_y: f64) {
	dx := anchor_x - WINDOW_WIDTH / 2
	dy := anchor_y - WINDOW_HEIGHT / 2

	world_x := cam_x + dx / scale()
	world_y := cam_y + dy / scale()
	zoom = clamp(zoom + steps, ZOOM_MIN, ZOOM_MAX)
	cam_x = world_x - dx / scale()
	cam_y = world_y - dy / scale()
}

pan :: proc(dx, dy: f64) {
	cam_x -= dx / scale()
	cam_y -= dy / scale()
}

Side :: enum {
	West,
	East,
	North,
	South,
}

FIT_DEPTH :: 12

// How far the nearest live cell is from one side of n (n is not empty).
// Only looks FIT_DEPTH levels down, which is plenty for framing a view.
edge_gap :: proc(n: ^Node, side: Side, depth := FIT_DEPTH) -> f64 {
	if n.level == 0 || depth == 0 {
		return 0
	}

	near, far: [2]^Node
	switch side {
	case .West:
		near, far = {n.nw, n.sw}, {n.ne, n.se}
	case .East:
		near, far = {n.ne, n.se}, {n.nw, n.sw}
	case .North:
		near, far = {n.nw, n.ne}, {n.sw, n.se}
	case .South:
		near, far = {n.sw, n.se}, {n.nw, n.ne}
	}

	half := math.pow(2, f64(n.level) - 1)
	pair := near
	skipped: f64
	if near[0].population == 0 && near[1].population == 0 {
		pair = far
		skipped = half
	}

	gap := half
	for child in pair {
		if child.population > 0 {
			gap = min(gap, edge_gap(child, side, depth - 1))
		}
	}
	return skipped + gap
}

// Centre on the live cells and zoom out until they are all on screen
fit_view :: proc() {
	cam_x = 0
	cam_y = 0
	zoom = 0
	if root.population == 0 {
		return
	}

	half := math.pow(2, f64(root.level) - 1)
	west := -half + edge_gap(root, .West)
	east := half - edge_gap(root, .East)
	north := -half + edge_gap(root, .North)
	south := half - edge_gap(root, .South)

	cam_x = (west + east) / 2
	cam_y = (north + south) / 2
	zoom = ZOOM_MAX
	for zoom > ZOOM_MIN && ((east - west) * scale() > WINDOW_WIDTH || (south - north) * scale() > WINDOW_HEIGHT) {
		zoom -= 1
	}
}

fill_rect :: proc(x0, y0, x1, y1: f64, color: rl.Color) {
	px0 := int(math.floor(clamp(x0, 0, WINDOW_WIDTH)))
	py0 := int(math.floor(clamp(y0, 0, WINDOW_HEIGHT)))
	px1 := int(math.floor(clamp(x1, 0, WINDOW_WIDTH)))
	py1 := int(math.floor(clamp(y1, 0, WINDOW_HEIGHT)))

	// Anything smaller than a pixel still lights one up
	px1 = min(max(px1, px0 + 1), WINDOW_WIDTH)
	py1 = min(max(py1, py0 + 1), WINDOW_HEIGHT)

	for y in py0 ..< py1 {
		for x in px0 ..< px1 {
			pixels[y * WINDOW_WIDTH + x] = color
		}
	}
}

// Draw n, whose top left corner is at world position (world_x, world_y).
// The tree is only followed down to nodes one pixel in size, so drawing costs
// the same however far the view is zoomed out.
draw_node :: proc(n: ^Node, world_x, world_y: f64) {
	if n.population == 0 {
		return
	}

	size := math.pow(2, f64(n.level))
	x0 := (world_x - cam_x) * scale() + WINDOW_WIDTH / 2
	y0 := (world_y - cam_y) * scale() + WINDOW_HEIGHT / 2
	x1 := x0 + size * scale()
	y1 := y0 + size * scale()
	if x1 <= 0 || y1 <= 0 || x0 >= WINDOW_WIDTH || y0 >= WINDOW_HEIGHT {
		return // off screen
	}

	if n.level == 0 {
		gap: f64 = zoom >= CELL_GAP_MIN_ZOOM ? 1 : 0
		fill_rect(x0, y0, x1 - gap, y1 - gap, rl.WHITE)
		return
	}
	if x1 - x0 <= 1 {
		// Brighter the more of the pixel is alive
		density := f64(n.population) / (size * size)
		shade := u8(130 + 125 * math.sqrt(density))
		fill_rect(x0, y0, x1, y1, rl.Color{shade, shade, shade, 255})
		return
	}

	half := size / 2
	draw_node(n.nw, world_x, world_y)
	draw_node(n.ne, world_x + half, world_y)
	draw_node(n.sw, world_x, world_y + half)
	draw_node(n.se, world_x + half, world_y + half)
}

draw_cells :: proc() {
	for &p in pixels {
		p = rl.BLACK
	}
	half := math.pow(2, f64(root.level) - 1)
	draw_node(root, -half, -half)

	rl.UpdateTexture(screen, raw_data(pixels))
	rl.DrawTexture(screen, 0, 0, rl.WHITE)
}

// 1234567 -> "1,234,567"
with_commas :: proc(n: u128) -> string {
	digits := fmt.tprint(n)
	b := strings.builder_make(context.temp_allocator)
	for ch, i in digits {
		if i > 0 && (len(digits) - i) % 3 == 0 {
			strings.write_byte(&b, ',')
		}
		strings.write_rune(&b, ch)
	}
	return strings.to_string(b)
}

draw_hud :: proc() {
	lines := [?]string {
		pattern_name,
		fmt.tprintf("generation: %s", with_commas(generation)),
		fmt.tprintf("population: %s", with_commas(u128(root.population))),
		fmt.tprintf("step: 2^%d = %s generations, took %.1f ms", step_exp, with_commas(u128(1) << uint(step_exp)), step_ms),
		fmt.tprintf("nodes: %s    universe: 2^%d cells wide    zoom: 2^%d", with_commas(u128(node_count)), root.level, zoom),
		step_failed ? "out of memory, step size halved (SPACE to run)" : sim_running ? "running" : "paused (SPACE to run)",
	}

	rl.DrawRectangle(0, 0, 820, i32(len(lines)) * 20 + 12, rl.Color{0, 0, 0, 190})
	for line, i in lines {
		rl.DrawText(strings.clone_to_cstring(line, context.temp_allocator), 8, i32(i) * 20 + 8, 16, rl.RAYWHITE)
	}
	free_all(context.temp_allocator)
}

draw_loop :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	draw_cells()
	draw_hud()
	rl.EndDrawing()
}
