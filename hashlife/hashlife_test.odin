package hashlife

import "core:testing"

// Run with: odin test hashlife
// Everything is in one test because the universe is global state.

R_PENTOMINO :: "b2o$2o$bo!"
ACORN :: "bo$3bo$2o2b3o!"

run_until :: proc(rle: string, exp: int, target: u128) -> u64 {
	load_pattern(rle)
	set_step_exp(exp)
	for generation < target {
		step()
	}
	return root.population
}

@(test)
hashlife_matches_known_results :: proc(t: ^testing.T) {
	defer reset()

	// Well known methuselahs: the R-pentomino settles at generation 1103 with
	// 116 cells, the acorn at 5206 with 633. Every step size must agree.
	for exp in ([]int{0, 1, 4, 7, 11, 20}) {
		testing.expect_value(t, run_until(R_PENTOMINO, exp, 1103), 116)
	}
	for exp in ([]int{2, 13}) {
		testing.expect_value(t, run_until(ACORN, exp, 5206), 633)
	}

	// Changing the step size mid run must not reuse stale results
	load_pattern(R_PENTOMINO)
	for exp in ([]int{9, 0, 5, 2, 10, 3}) {
		set_step_exp(exp)
		step()
		step()
	}
	testing.expect_value(t, generation, 2 * (512 + 1 + 32 + 4 + 1024 + 8))
	testing.expect_value(t, root.population, 116)

	// Surviving a garbage collection
	load_pattern(ACORN)
	set_step_exp(3)
	for generation < 5206 {
		step()
		collect_garbage()
	}
	testing.expect_value(t, root.population, 633)

	// Cell for cell against a brute force simulation of a random soup
	SIZE :: 256
	SOUP :: 24
	GENERATIONS :: 100
	Grid :: [SIZE][SIZE]bool
	grid := new(Grid)
	buffer := new(Grid)
	defer free(grid)
	defer free(buffer)

	reset()
	root = empty_node(8)
	seed: u32 = 12345
	for y in 0 ..< SOUP {
		for x in 0 ..< SOUP {
			seed = seed * 1664525 + 1013904223
			if seed >> 31 == 1 {
				gx := x + (SIZE - SOUP) / 2
				gy := y + (SIZE - SOUP) / 2
				grid[gx][gy] = true
				root = set_cell(root, u64(gx), u64(gy))
			}
		}
	}

	for _ in 0 ..< GENERATIONS {
		for x in 1 ..< SIZE - 1 {
			for y in 1 ..< SIZE - 1 {
				neighbours := 0
				for dx in -1 ..= 1 {
					for dy in -1 ..= 1 {
						if (dx != 0 || dy != 0) && grid[x + dx][y + dy] {
							neighbours += 1
						}
					}
				}
				buffer[x][y] = neighbours == 3 || (grid[x][y] && neighbours == 2)
			}
		}
		grid^ = buffer^
	}

	set_step_exp(2)
	for generation < GENERATIONS {
		step()
	}

	// The root stays centred on the same point, but may end up smaller than
	// the brute force grid
	root_size := 1 << root.level
	offset := (root_size - SIZE) / 2
	mismatches := 0
	for x in 0 ..< SIZE {
		for y in 0 ..< SIZE {
			rx := x + offset
			ry := y + offset
			inside := rx >= 0 && rx < root_size && ry >= 0 && ry < root_size
			if (inside && get_cell(root, u64(rx), u64(ry))) != grid[x][y] {
				mismatches += 1
			}
		}
	}
	testing.expect_value(t, mismatches, 0)
}
