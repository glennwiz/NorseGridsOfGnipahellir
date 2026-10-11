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
	grid[153][115] = Cell {
		alive = true,
	}
	grid[153][116] = Cell {
		alive = true,
	}
	grid[153][117] = Cell {
		alive = true,
	}
	grid[153][118] = Cell {
		alive = true,
	}
	grid[153][119] = Cell {
		alive = true,
	}
	grid[153][120] = Cell {
		alive = true,
	}
	grid[153][121] = Cell {
		alive = true,
	}
	grid[153][122] = Cell {
		alive = true,
	}
	grid[153][123] = Cell {
		alive = true,
	}
	grid[153][124] = Cell {
		alive = true,
	}
	grid[153][125] = Cell {
		alive = true,
	}

	grid[156][115] = Cell {
		alive = true,
	}
	grid[155][116] = Cell {
		alive = true,
	}
	grid[154][117] = Cell {
		alive = true,
	}
	grid[153][118] = Cell {
		alive = true,
	}

	grid[159][115] = Cell {
		alive = true,
	}
	grid[158][116] = Cell {
		alive = true,
	}
	grid[157][117] = Cell {
		alive = true,
	}
	grid[154][120] = Cell {
		alive = true,
	}
	grid[155][119] = Cell {
		alive = true,
	}
	grid[156][118] = Cell {
		alive = true,
	}

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

	grid[154][115] = Cell {
		alive = true,
	}
	grid[154][116] = Cell {
		alive = true,
	}; grid[155][116] = Cell {
		alive = true,
	}
	grid[154][117] = Cell {
		alive = true,
	}; grid[156][117] = Cell {
		alive = true,
	}
	grid[154][119] = Cell {
		alive = true,
	}; grid[157][118] = Cell {
		alive = true,
	}
	grid[154][120] = Cell {
		alive = true,
	}; grid[158][119] = Cell {
		alive = true,
	}
	grid[154][118] = Cell {
		alive = true,
	}; grid[157][120] = Cell {
		alive = true,
	}
	grid[154][121] = Cell {
		alive = true,
	}; grid[156][121] = Cell {
		alive = true,
	}
	grid[154][122] = Cell {
		alive = true,
	}; grid[155][122] = Cell {
		alive = true,
	}
	grid[154][123] = Cell {
		alive = true,
	}; grid[156][123] = Cell {
		alive = true,
	}
	grid[154][124] = Cell {
		alive = true,
	}; grid[157][124] = Cell {
		alive = true,
	}
	grid[154][125] = Cell {
		alive = true,
	}; grid[158][125] = Cell {
		alive = true,
	}
}

// Cell the O rune is centred on. The camera focuses here too (see update_camera).
RUNE_CENTER_X :: 156
RUNE_CENTER_Y :: 120

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

	ox :: RUNE_CENTER_X
	oy :: RUNE_CENTER_Y

	grid[ox + 0][oy - 5] = Cell {
		alive = true,
	}
	grid[ox - 1][oy - 4] = Cell {
		alive = true,
	}; grid[ox + 1][oy - 4] = Cell {
		alive = true,
	}
	grid[ox - 2][oy - 3] = Cell {
		alive = true,
	}; grid[ox + 2][oy - 3] = Cell {
		alive = true,
	}
	grid[ox - 3][oy - 2] = Cell {
		alive = true,
	}; grid[ox + 3][oy - 2] = Cell {
		alive = true,
	}
	grid[ox - 2][oy - 1] = Cell {
		alive = true,
	}; grid[ox + 2][oy - 1] = Cell {
		alive = true,
	}
	grid[ox - 1][oy + 0] = Cell {
		alive = true,
	}; grid[ox + 1][oy + 0] = Cell {
		alive = true,
	}
	grid[ox + 0][oy + 1] = Cell {
		alive = true,
	}
	grid[ox - 1][oy + 2] = Cell {
		alive = true,
	}; grid[ox + 1][oy + 2] = Cell {
		alive = true,
	}
	grid[ox - 2][oy + 3] = Cell {
		alive = true,
	}; grid[ox + 2][oy + 3] = Cell {
		alive = true,
	}
	grid[ox - 3][oy + 4] = Cell {
		alive = true,
	}; grid[ox + 3][oy + 4] = Cell {
		alive = true,
	}

}
