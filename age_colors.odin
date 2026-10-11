package gnipahellir

import rl "vendor:raylib"

// Cells older than this all get the last colour
AGE_MAX :: 100

CELL_COLOR :: rl.Color{100, 0, 0, 255} // used when age colours are off

show_age_colors := true

// Newborns are hot and bright, survivors cool down: gliders and chaos stay
// yellow/orange, oscillators flicker, still lifes settle into blue.
Age_Color :: struct {
	age:   int,
	color: rl.Color,
}

AGE_GRADIENT :: [?]Age_Color {
	{0, {255, 255, 210, 255}}, // white-yellow
	{2, {255, 220, 0, 255}}, // yellow
	{6, {255, 120, 0, 255}}, // orange
	{15, {220, 20, 20, 255}}, // red
	{40, {200, 0, 200, 255}}, // magenta
	{AGE_MAX, {60, 90, 255, 255}}, // blue
}

age_palette: [AGE_MAX + 1]rl.Color

// Fill age_palette by blending along AGE_GRADIENT
build_age_palette :: proc() {
	grad := AGE_GRADIENT
	for i in 0 ..< len(grad) - 1 {
		a, b := grad[i], grad[i + 1]
		for age in a.age ..= b.age {
			t := f32(age - a.age) / f32(b.age - a.age)
			age_palette[age] = rl.ColorLerp(a.color, b.color, t)
		}
	}
}

cell_color :: proc(cell: Cell) -> rl.Color {
	if !show_age_colors {
		return CELL_COLOR
	}
	return age_palette[cell.age]
}
