package gnipahellir

import "core:fmt"
import "core:mem"
import "core:os"

get_rune_f :: proc() {

	//     o      o    o
	//     o    o    o
	//     o o     o
	//     o     o
	//     o   o
	//     o o
	//     o
	//     o
	//     o
	//     o
	//     o
	//X     Y
	grid_state[153][115] = Cell{true}
	grid_state[153][116] = Cell{true}
	grid_state[153][117] = Cell{true}
	grid_state[153][118] = Cell{true}
	grid_state[153][119] = Cell{true}
	grid_state[153][120] = Cell{true}
	grid_state[153][121] = Cell{true}
	grid_state[153][122] = Cell{true}
	grid_state[153][123] = Cell{true}
	grid_state[153][124] = Cell{true}
	grid_state[153][125] = Cell{true}

	grid_state[156][115] = Cell{true}
	grid_state[155][116] = Cell{true}
	grid_state[154][117] = Cell{true}
	grid_state[153][118] = Cell{true}

	grid_state[159][115] = Cell{true}
	grid_state[158][116] = Cell{true}
	grid_state[157][117] = Cell{true}
	grid_state[154][120] = Cell{true}
	grid_state[155][119] = Cell{true}
	grid_state[156][118] = Cell{true}

}

get_rune_r :: proc() {

	//     o
	//     o o
	//     o   o
	//     o     o
	//     o       o
	//     o     o
	//     o   o
	//     o o
	//     o   o
	//     o     o
	//     o       o
	//     o         o

	grid_state[154][115] = Cell{true}
	grid_state[154][116] = Cell{true}; grid_state[155][116] = Cell{true}
	grid_state[154][117] = Cell{true}; grid_state[156][117] = Cell{true}
	grid_state[154][119] = Cell{true}; grid_state[157][118] = Cell{true}
	grid_state[154][120] = Cell{true}; grid_state[158][119] = Cell{true}
	grid_state[154][118] = Cell{true}; grid_state[157][120] = Cell{true}
	grid_state[154][121] = Cell{true}; grid_state[156][121] = Cell{true}
	grid_state[154][122] = Cell{true}; grid_state[155][122] = Cell{true}
	grid_state[154][123] = Cell{true}; grid_state[156][123] = Cell{true}
	grid_state[154][124] = Cell{true}; grid_state[157][124] = Cell{true}
	grid_state[154][125] = Cell{true}; grid_state[158][125] = Cell{true}
}

// Cell the O rune is centred on. The camera focuses here too (see FOCUS_X/Y).
RUNE_O_X :: 156
RUNE_O_Y :: 120

get_rune_o :: proc() {

	//     o
	//    o o
	//   o   o
	//  o     o
	//   o   o
	//    o o
	//     o
	//    o o
	//   o   o
	//  o     o

	ox :: RUNE_O_X
	oy :: RUNE_O_Y
	grid_state[ox + 0][oy - 5] = Cell{true}
	grid_state[ox - 1][oy - 4] = Cell{true}; grid_state[ox + 1][oy - 4] = Cell{true}
	grid_state[ox - 2][oy - 3] = Cell{true}; grid_state[ox + 2][oy - 3] = Cell{true}
	grid_state[ox - 3][oy - 2] = Cell{true}; grid_state[ox + 3][oy - 2] = Cell{true}
	grid_state[ox - 2][oy - 1] = Cell{true}; grid_state[ox + 2][oy - 1] = Cell{true}
	grid_state[ox - 1][oy + 0] = Cell{true}; grid_state[ox + 1][oy + 0] = Cell{true}
	grid_state[ox + 0][oy + 1] = Cell{true}
	grid_state[ox - 1][oy + 2] = Cell{true}; grid_state[ox + 1][oy + 2] = Cell{true}
	grid_state[ox - 2][oy + 3] = Cell{true}; grid_state[ox + 2][oy + 3] = Cell{true}
	grid_state[ox - 3][oy + 4] = Cell{true}; grid_state[ox + 3][oy + 4] = Cell{true}

}

// Blocks, ships and gliders from the reference screenshot, as {x, y} cell
// offsets from the pattern's top-left corner.
PATTERN_A :: [?][2]i32 {
	// block
	{0, 3}, {1, 3}, {0, 4}, {1, 4},
	// ship
	{9, 3}, {10, 3}, {8, 4}, {10, 4}, {8, 5}, {9, 5},
	// glider
	{16, 5}, {17, 5}, {16, 6}, {18, 6}, {16, 7},
	// ship
	{23, 1}, {24, 1}, {22, 2}, {24, 2}, {22, 3}, {23, 3},
	// block
	{34, 1}, {35, 1}, {34, 2}, {35, 2},
	// glider
	{35, 8}, {36, 8}, {35, 9}, {37, 9}, {35, 10},
	// glider
	{24, 13}, {25, 13}, {26, 13}, {24, 14}, {25, 15},
}
PATTERN_A_W :: 38
PATTERN_A_H :: 16

// Stamped once (not every frame like the runes) so the pattern evolves.
place_pattern_a :: proc() {
	ox :: FOCUS_X - PATTERN_A_W / 2
	oy :: FOCUS_Y - PATTERN_A_H / 2
	for p in PATTERN_A {
		grid_state[ox + p.x][oy + p.y] = Cell{true}
	}
}
