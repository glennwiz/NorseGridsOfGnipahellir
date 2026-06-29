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
