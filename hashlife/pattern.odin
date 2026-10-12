package hashlife

import "core:strings"

// Replace the universe with a pattern, in either RLE or Golly's macrocell format
load_pattern :: proc(data: string) {
	reset()
	if strings.has_prefix(data, "[M2]") {
		load_macrocell(data)
	} else {
		load_rle(data)
	}
	for root.level < 3 {
		root = expand(root)
	}
}

// RLE, the standard Life notation:
// o = alive, b = dead, $ = end of row, a number repeats the next symbol.
load_rle :: proc(data: string) {
	cells: [dynamic][2]i64
	defer delete(cells)

	x, y, run, w: i64
	text := data
	parse: for line in strings.split_lines_iterator(&text) {
		if len(line) == 0 || line[0] == '#' || line[0] == 'x' {
			continue // comments and the "x = .., y = .., rule = .." header
		}
		for ch in line {
			count := max(run, 1)
			switch ch {
			case '0' ..= '9':
				run = run * 10 + i64(ch - '0')
				continue
			case 'o':
				for _ in 0 ..< count {
					append(&cells, [2]i64{x, y})
					x += 1
				}
			case 'b':
				x += count
			case '$':
				y += count
				x = 0
			case '!':
				break parse
			}
			w = max(w, x)
			run = 0
		}
	}
	h := y + 1

	// Centre the pattern on the middle of the root
	level := 3
	for (i64(1) << uint(level)) < max(w, h) {
		level += 1
	}
	size := i64(1) << uint(level)
	ox := (size - w) / 2
	oy := (size - h) / 2

	root = empty_node(level)
	for c in cells {
		root = set_cell(root, u64(c.x + ox), u64(c.y + oy))
	}
}

// Macrocell is a quadtree written out one node per line, children first:
//
//   $$..*$...        an 8x8 leaf (. = dead, * = alive, $ = end of row)
//   1 0 1 1 0        a 2x2 node listing its four cell states
//   5 12 0 7 3       a level 5 node and the line numbers of its nw ne sw se
//                    children (0 = empty)
//
// The last line is the root. This is hashlife's own structure, so it loads
// straight into the node table.
load_macrocell :: proc(data: string) {
	nodes: [dynamic]^Node
	defer delete(nodes)
	append(&nodes, nil) // line numbers start at 1

	text := data
	for line in strings.split_lines_iterator(&text) {
		if len(line) == 0 || line[0] == '[' {
			continue
		}
		switch line[0] {
		case '#':
			if strings.has_prefix(line, "#G") {
				rest := line[2:]
				generation = u128(read_number(&rest))
			}
		case '.', '*', '$':
			append(&nodes, read_leaf(line))
		case:
			rest := line
			level := int(read_number(&rest))
			children: [4]^Node
			for &child in children {
				i := read_number(&rest)
				switch {
				case level == 1:
					child = i == 0 ? &dead_cell : &live_cell
				case i == 0:
					child = empty_node(level - 1)
				case:
					child = nodes[i]
				}
			}
			append(&nodes, join(children[0], children[1], children[2], children[3]))
		}
	}

	root = nodes[len(nodes) - 1]
}

// Read the next number off the front of text
read_number :: proc(text: ^string) -> (n: u64) {
	i := 0
	for i < len(text) && text[i] == ' ' {
		i += 1
	}
	for i < len(text) && text[i] >= '0' && text[i] <= '9' {
		n = n * 10 + u64(text[i] - '0')
		i += 1
	}
	text^ = text[i:]
	return
}

// An 8x8 macrocell leaf line -> a level 3 node
read_leaf :: proc(line: string) -> ^Node {
	cells: [8][8]^Node // cells[y][x]
	for &row in cells {
		for &cell in row {
			cell = &dead_cell
		}
	}

	x, y: int
	for ch in line {
		switch ch {
		case '.':
			x += 1
		case '*':
			cells[y][x] = &live_cell
			x += 1
		case '$':
			y += 1
			x = 0
		}
	}

	quads: [4][4]^Node // quads[y][x], 2x2 cells each
	for qy in 0 ..< 4 {
		for qx in 0 ..< 4 {
			cx := qx * 2
			cy := qy * 2
			quads[qy][qx] = join(cells[cy][cx], cells[cy][cx + 1], cells[cy + 1][cx], cells[cy + 1][cx + 1])
		}
	}
	return join(
		join(quads[0][0], quads[0][1], quads[1][0], quads[1][1]),
		join(quads[0][2], quads[0][3], quads[1][2], quads[1][3]),
		join(quads[2][0], quads[2][1], quads[3][0], quads[3][1]),
		join(quads[2][2], quads[2][3], quads[3][2], quads[3][3]),
	)
}
