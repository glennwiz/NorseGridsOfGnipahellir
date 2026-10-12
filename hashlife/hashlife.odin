package hashlife

// Hashlife (Bill Gosper, 1984).
//
// The universe is a quadtree. A node at level k covers a 2^k x 2^k square and
// is made of four level k-1 nodes; level 0 is a single cell.
//
// Two tricks make it fast:
//  1. Hash consing: join() never builds the same node twice, so identical
//     regions anywhere in space (or time) are one shared node.
//  2. Memoisation: every node remembers its "result", the centre half of
//     itself some generations later. A shared node is only ever simulated once.
//
// The result of a level k node is 2^(k-2) generations ahead, so big nodes
// leap exponentially far into the future.

Node :: struct {
	nw, ne, sw, se: ^Node,
	result:         ^Node, // centre of this node, advanced (see advance)
	next:           ^Node, // hash bucket chain, or the free list
	population:     u64,
	level:          u8,
	marked:         bool, // used by the garbage collector
}

// The only two level 0 nodes
dead_cell := Node{}
live_cell := Node {
	population = 1,
}

MAX_LEVEL :: 200
STEP_EXP_MAX :: 120 // the generation counter is a u128

BLOCK_SIZE :: 1 << 16
TABLE_START_SIZE :: 1 << 16
GC_START_LIMIT :: 8_000_000 // nodes, ~64 bytes each
NODE_LIMIT :: 24_000_000 // a step that needs more than this is given up on

root: ^Node
generation: u128
step_exp: int // each step() advances 2^step_exp generations

blocks: [dynamic][]Node
free_list: ^Node
table: []^Node
node_count: int
out_of_memory: bool
gc_limit := GC_START_LIMIT
empties: [MAX_LEVEL + 1]^Node

alloc_node :: proc() -> ^Node {
	if free_list == nil {
		block := make([]Node, BLOCK_SIZE)
		append(&blocks, block)
		for &n in block {
			n.next = free_list
			free_list = &n
		}
	}
	n := free_list
	free_list = n.next
	return n
}

hash_children :: proc(nw, ne, sw, se: ^Node) -> u64 {
	K :: 0x9E3779B97F4A7C15
	h := u64(uintptr(nw))
	h = h * K + u64(uintptr(ne))
	h = h * K + u64(uintptr(sw))
	h = h * K + u64(uintptr(se))
	h *= K
	return h ~ (h >> 29)
}

// The one and only node with these four children
join :: proc(nw, ne, sw, se: ^Node) -> ^Node {
	if len(table) == 0 {
		table = make([]^Node, TABLE_START_SIZE)
	}

	h := hash_children(nw, ne, sw, se)
	slot := h & u64(len(table) - 1)
	for n := table[slot]; n != nil; n = n.next {
		if n.nw == nw && n.ne == ne && n.sw == sw && n.se == se {
			return n
		}
	}

	if node_count >= len(table) {
		grow_table()
		slot = h & u64(len(table) - 1)
	}

	n := alloc_node()
	n^ = Node {
		nw         = nw,
		ne         = ne,
		sw         = sw,
		se         = se,
		next       = table[slot],
		population = nw.population + ne.population + sw.population + se.population,
		level      = nw.level + 1,
	}
	table[slot] = n
	node_count += 1
	if node_count > NODE_LIMIT {
		out_of_memory = true
	}
	return n
}

grow_table :: proc() {
	old := table
	table = make([]^Node, len(old) * 2)
	for bucket in old {
		next: ^Node
		for n := bucket; n != nil; n = next {
			next = n.next
			slot := hash_children(n.nw, n.ne, n.sw, n.se) & u64(len(table) - 1)
			n.next = table[slot]
			table[slot] = n
		}
	}
	delete(old)
}

empty_node :: proc(level: int) -> ^Node {
	if level == 0 {
		return &dead_cell
	}
	if empties[level] == nil {
		e := empty_node(level - 1)
		empties[level] = join(e, e, e, e)
	}
	return empties[level]
}

// The centre half of n
centre :: proc(n: ^Node) -> ^Node {
	return join(n.nw.se, n.ne.sw, n.sw.ne, n.se.nw)
}

// The centre half of the square straddling west | east
centre_h :: proc(w, e: ^Node) -> ^Node {
	return join(w.ne.se, e.nw.sw, w.se.ne, e.sw.nw)
}

// The centre half of the square straddling north / south
centre_v :: proc(n, s: ^Node) -> ^Node {
	return join(n.sw.se, n.se.sw, s.nw.ne, s.ne.nw)
}

// n with a border of dead cells around it, one level up
expand :: proc(n: ^Node) -> ^Node {
	e := empty_node(int(n.level) - 1)
	return join(join(e, e, e, n.nw), join(e, e, n.ne, e), join(e, n.sw, e, e), join(n.se, e, e, e))
}

// Base case: a 4x4 node, brute forced one generation into its 2x2 centre
life_4x4 :: proc(n: ^Node) -> ^Node {
	quads := [4]^Node{n.nw, n.ne, n.sw, n.se}
	c: [4][4]u64 // c[y][x]
	for q, i in quads {
		x := (i & 1) * 2
		y := (i >> 1) * 2
		c[y][x] = q.nw.population
		c[y][x + 1] = q.ne.population
		c[y + 1][x] = q.sw.population
		c[y + 1][x + 1] = q.se.population
	}

	out: [4]^Node
	for y in 1 ..= 2 {
		for x in 1 ..= 2 {
			neighbours: u64
			for dy in -1 ..= 1 {
				for dx in -1 ..= 1 {
					if dx != 0 || dy != 0 {
						neighbours += c[y + dy][x + dx]
					}
				}
			}
			alive := neighbours == 3 || (c[y][x] == 1 && neighbours == 2)
			out[(y - 1) * 2 + (x - 1)] = alive ? &live_cell : &dead_cell
		}
	}
	return join(out[0], out[1], out[2], out[3])
}

// The centre half of n, min(2^(level-2), 2^step_exp) generations later.
//
// n is cut into nine overlapping half-size squares. Each gives a quarter-size
// piece, and those are glued into four half-size squares whose results make up
// the answer:
//
//   n00 n01 n02
//   n10 n11 n12
//   n20 n21 n22
advance :: proc(n: ^Node) -> ^Node {
	if n.result != nil {
		return n.result
	}
	if out_of_memory {
		return n.nw // unwind quickly, step() throws the answer away
	}

	r: ^Node
	if n.population == 0 {
		r = n.nw // empty stays empty
	} else if n.level == 2 {
		r = life_4x4(n)
	} else {
		n00, n01, n02, n10, n11, n12, n20, n21, n22: ^Node
		if int(n.level) - 2 <= step_exp {
			// Full speed: time advances in both halves of the recursion
			n00 = advance(n.nw)
			n01 = advance(join(n.nw.ne, n.ne.nw, n.nw.se, n.ne.sw))
			n02 = advance(n.ne)
			n10 = advance(join(n.nw.sw, n.nw.se, n.sw.nw, n.sw.ne))
			n11 = advance(centre(n))
			n12 = advance(join(n.ne.sw, n.ne.se, n.se.nw, n.se.ne))
			n20 = advance(n.sw)
			n21 = advance(join(n.sw.ne, n.se.nw, n.sw.se, n.se.sw))
			n22 = advance(n.se)
		} else {
			// Too big for the step size: the first half only shrinks
			n00 = centre(n.nw)
			n01 = centre_h(n.nw, n.ne)
			n02 = centre(n.ne)
			n10 = centre_v(n.nw, n.sw)
			n11 = join(n.nw.se.se, n.ne.sw.sw, n.sw.ne.ne, n.se.nw.nw)
			n12 = centre_v(n.ne, n.se)
			n20 = centre(n.sw)
			n21 = centre_h(n.sw, n.se)
			n22 = centre(n.se)
		}
		r = join(
			advance(join(n00, n01, n10, n11)),
			advance(join(n01, n02, n11, n12)),
			advance(join(n10, n11, n20, n21)),
			advance(join(n11, n12, n21, n22)),
		)
	}

	if !out_of_memory {
		n.result = r
	}
	return r
}

// True if every live cell is inside the centre quarter of n (level >= 3)
fits_in_centre :: proc(n: ^Node) -> bool {
	return(
		n.nw.population == n.nw.se.se.population &&
		n.ne.population == n.ne.sw.sw.population &&
		n.sw.population == n.sw.ne.ne.population &&
		n.se.population == n.se.nw.nw.population \
	)
}

// Advance the universe 2^step_exp generations. Returns false, leaving the
// universe as it was, if the step needed more than NODE_LIMIT nodes.
step :: proc() -> bool {
	// The result is only the centre half of the root, and the pattern can grow
	// by one cell per generation, so pad until nothing can escape.
	for int(root.level) < step_exp + 3 || !fits_in_centre(root) {
		root = expand(root)
	}

	next := advance(root)
	if out_of_memory {
		collect_garbage()
		out_of_memory = false
		return false
	}
	root = next
	generation += u128(1) << uint(step_exp)

	if node_count > gc_limit {
		collect_garbage()
		if node_count > gc_limit / 2 {
			gc_limit = min(gc_limit * 2, NODE_LIMIT)
		}
	}
	return true
}

set_step_exp :: proc(exp: int) {
	new_exp := clamp(exp, 0, STEP_EXP_MAX)
	if new_exp == step_exp {
		return
	}

	// Results of nodes small enough to run at full speed under both step
	// sizes are still right, the rest are for the wrong number of generations.
	keep := min(new_exp, step_exp)
	for bucket in table {
		for n := bucket; n != nil; n = n.next {
			if int(n.level) - 2 > keep {
				n.result = nil
			}
		}
	}
	step_exp = new_exp
}

mark :: proc(n: ^Node) {
	if n == nil || n.marked || n.level == 0 {
		return
	}
	n.marked = true
	mark(n.nw)
	mark(n.ne)
	mark(n.sw)
	mark(n.se)
	mark(n.result)
}

// Free every node the root can't reach, through children or cached results
collect_garbage :: proc() {
	empties = {}
	mark(root)

	for &bucket in table {
		kept: ^Node
		next: ^Node
		for n := bucket; n != nil; n = next {
			next = n.next
			if n.marked {
				n.marked = false
				n.next = kept
				kept = n
			} else {
				n^ = Node {
					next = free_list,
				}
				free_list = n
				node_count -= 1
			}
		}
		bucket = kept
	}
}

reset :: proc() {
	for block in blocks {
		delete(block)
	}
	delete(blocks)
	blocks = nil
	delete(table)
	table = nil
	free_list = nil
	node_count = 0
	out_of_memory = false
	gc_limit = GC_START_LIMIT
	empties = {}
	root = nil
	generation = 0
}

// x, y are relative to the top left corner of n
set_cell :: proc(n: ^Node, x, y: u64) -> ^Node {
	if n.level == 0 {
		return &live_cell
	}
	half := u64(1) << (n.level - 1)
	switch {
	case x < half && y < half:
		return join(set_cell(n.nw, x, y), n.ne, n.sw, n.se)
	case y < half:
		return join(n.nw, set_cell(n.ne, x - half, y), n.sw, n.se)
	case x < half:
		return join(n.nw, n.ne, set_cell(n.sw, x, y - half), n.se)
	case:
		return join(n.nw, n.ne, n.sw, set_cell(n.se, x - half, y - half))
	}
}

// x, y are relative to the top left corner of n
get_cell :: proc(n: ^Node, x, y: u64) -> bool {
	if n.population == 0 {
		return false
	}
	if n.level == 0 {
		return true
	}
	half := u64(1) << (n.level - 1)
	switch {
	case x < half && y < half:
		return get_cell(n.nw, x, y)
	case y < half:
		return get_cell(n.ne, x - half, y)
	case x < half:
		return get_cell(n.sw, x, y - half)
	case:
		return get_cell(n.se, x - half, y - half)
	}
}
