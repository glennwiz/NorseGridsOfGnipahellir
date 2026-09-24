package gnipahellir

import rl "vendor:raylib"

// Patterns are written in RLE, the standard Life notation:
// o = alive, b = dead, $ = end of row, a number repeats the next symbol.

// Blocks, ships and gliders from the reference screenshot.
PATTERN_A :: "23b2o9b2o$22bobo9b2o$2o7b2o11b2o$2o6bobo$8b2o6b2o$16bobo$16bo$35b2o$35bobo$35bo3$24b3o$24bo$25bo!"

GOSPER_GUN :: "24bo$22bobo$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o$2o8bo3bob2o4bobo$10bo5bo7bo$11bo3bo$12b2o!"
SIMKIN_GUN :: "2o5b2o$2o5b2o2$4b2o$4b2o5$22b2ob2o$21bo5bo$21bo6bo2b2o$21b3o3bo3b2o$26bo4$20b2o$20bo$21b3o$23bo!"
R_PENTOMINO :: "b2o$2o$bo!"
ACORN :: "bo$3bo$2o2b3o!"
DIEHARD :: "6bo$2o$bo3b3o!"
INFINITE_LINE :: "8ob5o3b3o6b7ob5o!"
LWSS :: "bo2bo$o$o3bo$4o!"
MWSS :: "3bo$bo3bo$o$o4bo$5o!"
HWSS :: "3b2o$bo4bo$o$o5bo$6o!"
PULSAR :: "2b3o3b3o2$o4bobo4bo$o4bobo4bo$o4bobo4bo$2b3o3b3o2$2b3o3b3o$o4bobo4bo$o4bobo4bo$o4bobo4bo2$2b3o3b3o!"
PENTADECATHLON :: "2bo4bo$2ob4ob2o$2bo4bo!"
PUFFER_TRAIN :: "3bo$4bo$o3bo$b4o4$o$b2o$2bo$2bo$bo3$3bo$4bo$o3bo$b4o!"

Pattern_Key :: struct {
	key:  rl.KeyboardKey,
	name: string,
}

PATTERN_KEYS :: [?]Pattern_Key {
	{.A, "Block/ship/glider scene"},
	{.ONE, "Gosper glider gun"},
	{.TWO, "Simkin glider gun"},
	{.THREE, "R-pentomino"},
	{.FOUR, "Acorn"},
	{.FIVE, "Diehard"},
	{.SIX, "Infinite growth line"},
	{.SEVEN, "Spaceship race (LWSS, MWSS, HWSS)"},
	{.EIGHT, "Pulsar + Pentadecathlon"},
	{.NINE, "Puffer train"},
}

// Stamp the pattern bound to key (see PATTERN_KEYS).
place_pattern :: proc(key: rl.KeyboardKey) {
	#partial switch key {
	case .A:
		place_rle(PATTERN_A)
	case .ONE:
		place_rle(GOSPER_GUN)
	case .TWO:
		place_rle(SIMKIN_GUN)
	case .THREE:
		place_rle(R_PENTOMINO)
	case .FOUR:
		place_rle(ACORN)
	case .FIVE:
		place_rle(DIEHARD)
	case .SIX:
		place_rle(INFINITE_LINE)
	case .SEVEN:
		// Lined up on the right so they race left across the screen
		place_rle(LWSS, 15, -8)
		place_rle(MWSS, 15, 0)
		place_rle(HWSS, 15, 8)
	case .EIGHT:
		place_rle(PULSAR, -10, 0)
		place_rle(PENTADECATHLON, 10, 0)
	case .NINE:
		place_rle(PUFFER_TRAIN, -15, 0)
	}
}

// Stamp an RLE pattern centred on the focus cell, shifted by (dx, dy) cells.
// Stamped once (not every frame like the runes) so the pattern evolves.
place_rle :: proc(rle: string, dx: i32 = 0, dy: i32 = 0) {
	cells, w, h := parse_rle(rle)
	defer delete(cells)

	ox := RUNE_CENTER_X + dx - w / 2
	oy := RUNE_CENTER_Y + dy - h / 2
	for c in cells {
		x := (ox + c.x) %% NUM_CELLS_X
		y := (oy + c.y) %% NUM_CELLS_Y
		grid_state[x][y] = Cell {
			alive = true,
		}
	}
}

parse_rle :: proc(rle: string) -> (cells: [dynamic][2]i32, w, h: i32) {
	x, y, run: i32
	for ch in rle {
		count := max(run, 1)
		switch ch {
		case '0' ..= '9':
			run = run * 10 + i32(ch - '0')
			continue
		case 'o':
			for _ in 0 ..< count {
				append(&cells, [2]i32{x, y})
				x += 1
			}
		case 'b':
			x += count
		case '$':
			y += count
			x = 0
		}
		w = max(w, x)
		run = 0
	}
	h = y + 1
	return
}
