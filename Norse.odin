package gnipahellir

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC
WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
TARGET_DT :: 1000 / 60

CELL_SIZE :: 5
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE

GridState :: [NUM_CELLS_X][NUM_CELLS_Y]bool

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
    grid_state : GridState 
    for x := 0; x < len(grid_state) ; x += 1 {
       for y := 0; y < len(grid_state[x]); y += 1 {        
            grid_state[x][y] = false // Initially, all cells are off
        }
    }

    assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
    assert(SDL_Image.Init(SDL_Image.INIT_PNG) != nil, SDL.GetErrorString())
    defer SDL.Quit()

    window := SDL.CreateWindow(
        "Odin Hello World!",
        SDL.WINDOWPOS_CENTERED,
        SDL.WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_FLAGS
    )
    assert(window != nil, SDL.GetErrorString())
    defer SDL.DestroyWindow(window)

    game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
    assert(game.renderer != nil, SDL.GetErrorString())
    defer SDL.DestroyRenderer(game.renderer)

    game.perf_frequency = f64(SDL.GetPerformanceFrequency())
    start : f64
    end : f64
	counter :  u32  = 0

    event : SDL.Event

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
                }
            }
        }

        // Drawing gradient from black to green
        for x := 0; x < WINDOW_WIDTH; x += 1 {
            greenIntensity := u8(f32(x) / f32(WINDOW_WIDTH) * 255)
            SDL.SetRenderDrawColor(game.renderer, 0, greenIntensity, 100, 255)
            SDL.RenderDrawLine(game.renderer, cast(i32) x, 0, cast(i32) x, cast(i32) WINDOW_HEIGHT)
        }

        fmt.println("Drawing grid")
        fmt.println("NUM_CELLS_X : ", NUM_CELLS_X)
        fmt.println("NUM_CELLS_Y : ", NUM_CELLS_Y)

        // Get the center cell
        center := CellState{
            x = 64,//cast(i32) (NUM_CELLS_X / 2),
            y = 32,//cast(i32) (NUM_CELLS_Y / 2),
            is_alive = true
        }
                // X  Y
        grid_state[1][1] = true
        grid_state[2][1] = true
        grid_state[3][1] = true
        grid_state[4][1] = true

        //  o
        // o o
        //  o
        // o o
        grid_state[center.x] [center.y] = true
        grid_state[center.x - 1][center.y + 1] = true; grid_state[center.x + 1][center.y + 1] = true
        grid_state[center.x][center.y + 2] = true
        grid_state[center.x - 1][center.y + 3] = true; grid_state[center.x + 1][center.y + 3] = true
        
         

         // Drawing the grid based on the grid_state
         
        for x := 0; x < NUM_CELLS_X; x += 1 {
            for y := 0; y < NUM_CELLS_Y; y += 1 {
                if grid_state[x][y] {
                    // Cell is on, draw it as a filled square
                    SDL.SetRenderDrawColor(game.renderer, 255, 255, 255, 255) // White color for "on" cells
                    posX := cast(i32)(x * CELL_SIZE)
                    posY := cast(i32)(y * CELL_SIZE)
                    
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
			fmt.println("Start : ", start)
			fmt.println("End : ", end)
			fmt.println("FPS : ", 1000 / (end - start))
			counter = 0
		}
		else
		{
			counter += 1
		}        
    }
}

get_time :: proc() -> f64 {
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}

