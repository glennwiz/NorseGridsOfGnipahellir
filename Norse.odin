package Gnipahellir

import "core:fmt"
import "core:math/linalg"
import "vendor:sdl2"

WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 320
GRID_STATE :: [dynamic][dynamic]Cell
CELL_SIZE :: 5
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE

Game :: struct {
	renderer: ^sdl2.Renderer,
	keyboard: []u8,
	time:     f64,
	dt:       f64,
}

Vec4 :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Cell :: struct {
    x: i32,
    y: i32,
    is_alive: bool,
	color: Vec4
}

zoom_level :i32 = 20

get_time :: proc() -> f64 {
	return f64(sdl2.GetPerformanceCounter()) * 1000 / f64(sdl2.GetPerformanceFrequency())
}

main :: proc() {
	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

	window := sdl2.CreateWindow(
		"Norse Grids",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		sdl2.WINDOW_SHOWN,
	)
	assert(window != nil, sdl2.GetErrorString())
	defer sdl2.DestroyWindow(window)

	// Must not do VSync because we run the tick loop on the same thread as rendering.
	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, sdl2.GetErrorString())
	defer sdl2.DestroyRenderer(renderer)

	tickrate := 10.0
	ticktime := 1000.0 / tickrate

	game := Game {
		renderer = renderer,
		time     = get_time(),
		dt       = ticktime,	
	}

	dt := 0.0
    cell_grid:= make([dynamic][dynamic]Cell, 100, 100)
		
    dyn := make([dynamic]int, 5, 5)

	fmt.println("screen_width: ", WINDOW_WIDTH)
	fmt.println("screen_height: ", WINDOW_HEIGHT)
	fmt.println("cell_size: ", CELL_SIZE)
	fmt.println("num_cells_x: ", NUM_CELLS_X)
	fmt.println("num_cells_y: ", NUM_CELLS_Y)
	
    for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
        for x :i32= 0; x < NUM_CELLS_X; x += 1 {       
            cell_grid[y][x].is_alive = false
        }
    }

	// Calculate middle cell coordinates
	middle_x := NUM_CELLS_X / 2
	middle_y := NUM_CELLS_Y / 2

	// Set the middle cell's color to red (RGBA: 255, 0, 0, 255)
	cell_grid[middle_y][middle_x].color = Vec4{255, 0, 0, 255}
	cell_grid[middle_y][middle_x].is_alive = true 

	game_loop : for {

		// we need to check cell states and update them here
		// we also need to draw the cells here

		//the game loop updates a freaking lot so lets some % modulo to update the cells every 60th frame or so, oh and lets add pluss and minus for update speed
		//also lets add a pause button 'space' and a clear button 'c'

		//lets loop over the cells and draw them		

		for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
			for x :i32= 0; x < NUM_CELLS_X; x += 1 {
				cell := cell_grid[y][x]
				if cell.is_alive {
					// Convert Vec4 color to SDL color and set it
					sdl2.SetRenderDrawColor(game.renderer, u8(cell.color.r), u8(cell.color.g), u8(cell.color.b), 255) // Adjust the fields based on your Vec4 structure
					
					rect := sdl2.Rect{
						x = x * CELL_SIZE * zoom_level,
						y = y * CELL_SIZE * zoom_level,     
				
						w = 5 * CELL_SIZE * zoom_level,
						h = 5 * CELL_SIZE * zoom_level,
					}					
					
					sdl2.RenderFillRect(game.renderer, &rect)
				}
			}
		}
		


	
		fmt.printf("FPS: {}\n", 1000.0 / game.dt)
		//fmt.printf("cellstate: {}\n", cell_grid[0][0].is_alive)




		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				if event.key.keysym.scancode == sdl2.SCANCODE_ESCAPE {
					return
				}
			}
		}

        // Drawing gradient from black to grey
        for x :i32= 0; x < WINDOW_WIDTH; x += 1 {
            fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
            sdl2.SetRenderDrawColor(game.renderer, fade, fade, fade, 255)
            sdl2.RenderDrawLine(game.renderer, x, 0, x, WINDOW_HEIGHT)
        } 

        sdl2.SetRenderDrawColor(game.renderer, 0, 0, 0, 255) // Set color to black

        for x :i32= 0; x < WINDOW_WIDTH; x += zoom_level {
            sdl2.RenderDrawLine(game.renderer,  x, 0, x, WINDOW_HEIGHT)       
        }

        // Drawing black horizontal lines spaced 5 pixels apart
        for y :i32= 0; y < WINDOW_HEIGHT; y +=  zoom_level {
            sdl2.RenderDrawLine(game.renderer, 0, y, WINDOW_WIDTH, y)       
        }

		time := get_time()
		dt += time - game.time

		game.keyboard = sdl2.GetKeyboardStateAsSlice()
		game.time = time

		// Running on the same thread as rendering so in the end still limited by the rendering FPS.
		for dt >= ticktime {
			dt -= ticktime

			fmt.printf("FPS: {}\n", 1000.0 / game.dt)
		}
	
		sdl2.RenderPresent(renderer)
	}
}