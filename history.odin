package gnipahellir

// Life can't be run backwards (many boards lead to the same next board),
// so every step saves the board it replaced. Only live cells are kept,
// which is a few KB per generation instead of the full 1.5 MB grid.

HISTORY_MAX_BYTES :: 256 * 1024 * 1024 // oldest generations are dropped past this

Live_Cell :: struct {
	x, y: u16,
	age:  u8,
}

history: [dynamic][]Live_Cell // oldest first, the last one is the previous generation
history_bytes: int

// Advance the board one generation, saving the current one so it can be reversed.
step :: proc() {
	save_history()
	run_next_generation(&board.cells, &scratch)
	board.cells = scratch
	board.generation += 1
}

// Restore the previous generation. Returns false when there is none left.
step_back :: proc() -> bool {
	if len(history) == 0 {
		return false
	}
	snapshot := pop(&history)
	defer delete(snapshot)
	history_bytes -= len(snapshot) * size_of(Live_Cell)

	board.cells = {}
	for c in snapshot {
		board.cells[c.x][c.y] = Cell {
			alive = true,
			age   = c.age,
		}
	}
	board.generation -= 1
	return true
}

save_history :: proc() {
	live: [dynamic]Live_Cell
	for x in 0 ..< NUM_CELLS_X {
		for y in 0 ..< NUM_CELLS_Y {
			if cell := board.cells[x][y]; cell.alive {
				append(&live, Live_Cell{u16(x), u16(y), cell.age})
			}
		}
	}
	shrink(&live)
	append(&history, live[:])
	history_bytes += len(live) * size_of(Live_Cell)

	for history_bytes > HISTORY_MAX_BYTES && len(history) > 1 {
		oldest := history[0]
		history_bytes -= len(oldest) * size_of(Live_Cell)
		delete(oldest)
		ordered_remove(&history, 0)
	}
}

clear_history :: proc() {
	for snapshot in history {
		delete(snapshot)
	}
	delete(history)
	history = nil
	history_bytes = 0
}
