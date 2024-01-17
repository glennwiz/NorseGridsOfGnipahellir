package gnipahellir

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"

TITLE :: "Gnipahellir"
TITLE_BAR_HEIGHT :: 30



WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC
WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
TARGET_DT :: 1000 / 60

CELL_SIZE :: 5
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE

zoom_level := 1.0
zoom_step := 0.1

GridState :: [NUM_CELLS_X][NUM_CELLS_Y]bool
grid_state : GridState 
Game :: struct {
    perf_frequency: f64,
    renderer: ^SDL.Renderer,
}

CellState :: struct {
    x: i32,
    y: i32,
    is_alive: bool
}

game := Game{}

main :: proc() {

    // Initialize the grid state
    // Initialize the grid state
    
    // Initialize the grid state    
    
    for x := 0; x < len(grid_state) ; x += 1 {
       for y := 0; y < len(grid_state[x]); y += 1 {        
            grid_state[x][y] = false // Initially, all cells are off
        }
    }

    assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
    assert(SDL_Image.Init(SDL_Image.INIT_PNG) != nil, SDL.GetErrorString())
    defer SDL.Quit()

    window := SDL.CreateWindow(
        "Norse grids!",
        SDL.WINDOWPOS_CENTERED,
        SDL.WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_FLAGS| SDL.WINDOW_BORDERLESS  // Window flags with borderless option
        
    )
    assert(window != nil, SDL.GetErrorString())
    defer SDL.DestroyWindow(window)

    game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
    assert(game.renderer != nil, SDL.GetErrorString())
    defer SDL.DestroyRenderer(game.renderer)

    game.perf_frequency = f64(SDL.GetPerformanceFrequency())
    start : f64
    end : f64
	counter : u32 = 0
    event : SDL.Event

    is_mouse_button_down : bool = false

    game_loop : for {
        start = get_time()       

        // Handle events
        if SDL.PollEvent(&event) {
            if event.type == SDL.EventType.QUIT {
                break game_loop
            }
            if event.type == SDL.EventType.KEYDOWN {
                #partial switch event.key.keysym.scancode {
                    case .ESCAPE:
                        break game_loop
                    case .X:
                        zoom_level += zoom_step
                        if zoom_level > 2.0 { 
                            zoom_level = 2.0
                        }
                    case .Z:
                        zoom_level -= zoom_step
                        if zoom_level < 0.5 { 
                            zoom_level = 0.5
                        }
                }
            }
            
            // Handle Mouse Clicks    
            if event.type == SDL.EventType.MOUSEBUTTONDOWN {
                is_mouse_button_down = true
                mouse_x, mouse_y : i32
                SDL.GetMouseState(&mouse_x, &mouse_y)
                handle_mouse_input(mouse_x, mouse_y)
            }

            if event.type == SDL.EventType.MOUSEBUTTONUP {
                is_mouse_button_down = false
            }

            if event.type == SDL.EventType.MOUSEMOTION {
                if is_mouse_button_down {
                    // Get mouse position
                    mouse_x, mouse_y : i32
                    SDL.GetMouseState(&mouse_x, &mouse_y)
                    handle_mouse_input(mouse_x, mouse_y)
    
                }
            }
        }       

        // Drawing gradient from black to green
        for x := 0; x < WINDOW_WIDTH; x += 1 {
            fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
            SDL.SetRenderDrawColor(game.renderer, fade, fade, fade, 255)
            SDL.RenderDrawLine(game.renderer, cast(i32) x, 0, cast(i32) x, cast(i32) WINDOW_HEIGHT)
        } 

        // Get the center cell
        center := CellState{
            x = 64,
            y = 32,
            is_alive = true
        }
                // X  Y
        grid_state[1][1] = true
        grid_state[2][1] = true
        grid_state[3][1] = true
        grid_state[4][1] = true
     
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
        grid_state[center.x - 10] [center.y - 10] = true 
        grid_state[center.x - 11] [center.y - 9] = true; grid_state[center.x - 9] [center.y -9] = true
        grid_state[center.x - 12] [center.y - 8] = true; grid_state[center.x - 8] [center.y - 8] = true
        grid_state[center.x - 13] [center.y - 7] = true; grid_state[center.x - 7] [center.y - 7] = true
        grid_state[center.x - 12] [center.y - 6] = true; grid_state[center.x - 8] [center.y - 6] = true
        grid_state[center.x - 11] [center.y - 5] = true; grid_state[center.x - 9] [center.y - 5] = true
        grid_state[center.x - 10] [center.y - 4] = true; 
        grid_state[center.x - 11] [center.y - 3] = true; grid_state[center.x - 9] [center.y - 3] = true
        grid_state[center.x - 12] [center.y - 2] = true; grid_state[center.x - 8] [center.y - 2] = true
        grid_state[center.x - 13] [center.y - 1] = true; grid_state[center.x - 7] [center.y - 1] = true

        // Drawing the grid based on the grid_state         
        for x := 0; x < NUM_CELLS_X; x += 1 {
            for y := 0; y < NUM_CELLS_Y; y += 1 {
                if grid_state[x][y] {
                    // Cell is on, draw it as a filled square
                    scaled_cell_size := cast(i32)(f32(CELL_SIZE) * cast(f32)zoom_level)
                    posX := cast(i32)(f32(x * CELL_SIZE) * cast(f32)zoom_level)
                    posY := cast(i32)(f32(y * CELL_SIZE) * cast(f32)zoom_level)
                            
                    rect := SDL.Rect{
                        x = posX,
                        y = posY,
                        w = CELL_SIZE,
                        h = CELL_SIZE
                    }

                    SDL.RenderFillRect(game.renderer, &rect)
                }
            }
        }

        // Drawing black vertical lines spaced 5 pixels apart
        SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255) // Set color to black
        for x := 0; x < WINDOW_WIDTH; x += 5 {
            SDL.RenderDrawLine(game.renderer, cast(i32) x, 0, cast(i32) x, cast(i32) WINDOW_HEIGHT)
        }

        // Drawing black horizontal lines spaced 5 pixels apart
        for y := 0; y < WINDOW_HEIGHT; y += 5 {
            SDL.RenderDrawLine(game.renderer, 0, cast(i32) y, cast(i32) WINDOW_WIDTH, cast(i32) y)
        }


        // Present the renderer's content
        SDL.RenderPresent(game.renderer)

        // Frame rate management
        end = get_time()
        for end - start < TARGET_DT {
            end = get_time()
        }

		if counter == 60
		{
            fmt.println("Mouse state : ", is_mouse_button_down)
            fmt.println("---------------------------")
            fmt.println("Drawing grid")
            fmt.println("NUM_CELLS_X : ", NUM_CELLS_X)
            fmt.println("NUM_CELLS_Y : ", NUM_CELLS_Y)
            fmt.println("---------------------------")
			fmt.println("Start : ", start)
			fmt.println("End : ", end)
			fmt.println("FPS : ", 1000 / (end - start))
			counter = 0   
            fmt.println("---------------------------")
            continue game_loop         
		}
		
		counter += 1		        
    }
}

get_time :: proc() -> f64 {
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}

handle_mouse_input :: proc(mouse_x, mouse_y : i32) {
    grid_x := mouse_x / CELL_SIZE
    grid_y := mouse_y / CELL_SIZE

    if grid_x < NUM_CELLS_X && grid_y < NUM_CELLS_Y {
        grid_state[grid_x][grid_y] = !grid_state[grid_x][grid_y]
    }    
}