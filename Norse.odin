package gnipahellir

import "core:fmt"
import "core:os"
import "core:mem"
import "core:runtime"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"
import "core:time"

TITLE :: "Gnipahellir"
TITLE_BAR_HEIGHT :: 30
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC
WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
TARGET_DT :: 1000 / 100
GRID_STATE :: [NUM_CELLS_X][NUM_CELLS_Y]bool
CELL_SIZE :: 1
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE


cellLife :bool
isSet :bool
isDebug := true

zoom_level :i32 = 20
zoom_step :i32 = 1

sim_running :bool
sim_speed :i32 = 60
sim_speed_step :i32 = 10

grid_state : GRID_STATE 
grid_state_history := make([dynamic]GRID_STATE, 5, 5)
//TODO: implement history and fix sim bug

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

    logger("Starting Norse Grids!")
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
	counter : i32 = 0
    event : SDL.Event

    is_mouse_button_down : bool = false

    game_loop : for {
        start = get_time()       
        
        // Input Handling
        if SDL.PollEvent(&event) {
            if event.type == SDL.EventType.QUIT {
                break game_loop
            }

            // Handle Keyboard Input
            if event.type == SDL.EventType.KEYDOWN {
                #partial switch event.key.keysym.scancode {
                    case .ESCAPE:
                        break game_loop
                    case .X:
                        zoom_level += zoom_step
                        if zoom_level > 10 { 
                            zoom_level = 20
                        }
                    case .Z:
                        zoom_level -= zoom_step
                        if zoom_level < 1 { 
                            zoom_level = 1
                        }
                    case .A:
                        //if A is pressed dump the grid state to file for debugging
                        dump_grid_state()
                        break game_loop
                    case .SPACE:
                        sim_running = !sim_running
                    case .LEFT:
                        sim_speed += sim_speed_step
                        if sim_speed > 60 { 
                            sim_speed = 60
                        }
                    case .RIGHT:
                        sim_speed -= sim_speed_step
                        if sim_speed < 1 { 
                            sim_speed = 1
                        } 
                    case .D:
                        isDebug = !isDebug  
                }
            }

            // Handle Mouse Input  
            if event.type == SDL.EventType.MOUSEBUTTONDOWN {
                is_mouse_button_down = true
                mouse_x, mouse_y : i32
                SDL.GetMouseState(&mouse_x, &mouse_y)
                handle_mouse_input(mouse_x, mouse_y, false)
            }

            if event.type == SDL.EventType.MOUSEBUTTONUP {
                is_mouse_button_down = false
                isSet = false
            }

            if event.type == SDL.EventType.MOUSEMOTION {
                if is_mouse_button_down {
                    mouse_x, mouse_y : i32
                    SDL.GetMouseState(&mouse_x, &mouse_y)
                    handle_mouse_input(mouse_x, mouse_y, true)    
                }
            }
        }       

        // Drawing gradient from black to grey
        for x :i32= 0; x < WINDOW_WIDTH; x += 1 {
            fade := u8(f32(x) / f32(WINDOW_WIDTH) * 60)
            SDL.SetRenderDrawColor(game.renderer, fade, fade, fade, 255)
            SDL.RenderDrawLine(game.renderer, x, 0, x, WINDOW_HEIGHT)
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
       //grid_state[16] [2] = true 
       //grid_state[15] [3] = true; grid_state[17] [3] = true
       //grid_state[14] [4] = true; grid_state[18] [4] = true
       //grid_state[13] [5] = true; grid_state[19] [5] = true
       //grid_state[14] [6] = true; grid_state[18] [6] = true
       //grid_state[15] [7] = true; grid_state[17] [7] = true
       //grid_state[16] [8] = true; 
       //grid_state[15] [9] = true; grid_state[17] [9] = true
       //grid_state[14] [10] = true; grid_state[18] [10] = true
       //grid_state[13] [11] = true; grid_state[19] [11] = true     

        append(&grid_state_history, grid_state)

        // Draw the cell at locations by the grid       
        for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
            batch_start_x :i32= -1
            batch_width :i32= 0
        
            for x :i32= 0; x < NUM_CELLS_X; x += 1 {
                if grid_state[x][y] {
                    if batch_start_x == -1 {
                        batch_start_x = x
                    }
                    batch_width += 1
                } else {
                    if batch_start_x != -1 {
                        draw_batch(batch_start_x, y, batch_width, 1, game.renderer)
                        batch_start_x = -1
                        batch_width = 0
                    }
                }
            }
            if batch_start_x != -1 {
                // Draw the last batch in the row if it ends with alive cells
                draw_batch(batch_start_x, y, batch_width, 1, game.renderer)
            }
        }
        
        
        // Drawing black vertical lines spaced 5 pixels apart
        SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255) // Set color to black
        for x :i32= 0; x < WINDOW_WIDTH; x += zoom_level {
            SDL.RenderDrawLine(game.renderer,  x, 0, x, WINDOW_HEIGHT)
        }

        // Drawing black horizontal lines spaced 5 pixels apart
        for y :i32= 0; y < WINDOW_HEIGHT; y +=  zoom_level {
            SDL.RenderDrawLine(game.renderer, 0, y, WINDOW_WIDTH, y)
        }

        // Present the renderer's conte
        SDL.RenderPresent(game.renderer)

        // Frame rate management
        end = get_time()
        for end - start < TARGET_DT {
            end = get_time()
        }

		if isDebug && counter % 60 == 0	{
            perf_frequency := game.perf_frequency; // The frequency of the performance counter

            duration_ticks := end - start; // Duration in ticks
            fmt.println("Duration in ticks: ", duration_ticks);
            duration_seconds := duration_ticks / perf_frequency; // Convert ticks to seconds

            fmt.println("Duration: ", duration_seconds, " seconds");
            minutes := i64(duration_seconds / 60);
            seconds := i64(duration_seconds) % 60;
            milliseconds := i64((duration_seconds - f64(i64(duration_seconds))) * 1000);
            
            fmt.printf("Duration: %02d:%02d.%03d\n", minutes, seconds, milliseconds);

            logger("dsdfsdfsdf")

            fmt.println("---------------------------")
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
		}
		
		counter += 1

        // we can have thees in a || or check but it's reads better this way
        if !sim_running { continue game_loop }        
        if counter % sim_speed != 0  { continue game_loop }
        
        //simulate the next generation
        for x :i32= 0; x < NUM_CELLS_X; x += 1 {
            for y :i32= 0; y < NUM_CELLS_Y; y += 1 {  
                /*  
                Any live cell with fewer than two live neighbours dies, as if by underpopulation.
                Any live cell with two or three live neighbours lives on to the next generation.
                Any live cell with more than three live neighbours dies, as if by overpopulation.
                Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction. 
                */         
                live_neighbours := count_live_neighbours(grid_state, x , y );
                grid_state[x][y] = update_cell_state(grid_state[x][y], live_neighbours);
                    
            }
        }
        
        append(&grid_state_history, grid_state)
    }
}

count_live_neighbours := proc(grid_state: [NUM_CELLS_X][NUM_CELLS_Y]bool, x, y: i32) -> i32 {
    live_neighbours :i32= 0
    for nx := x-1; nx <= x+1; nx += 1 {
        for ny := y-1; ny <= y+1; ny += 1 {
            if nx >= 0 && ny >= 0 && nx < NUM_CELLS_X && ny < NUM_CELLS_Y && !(nx == x && ny == y) {
                if grid_state[nx][ny] {
                    live_neighbours += 1
                }
            }
        }
    }

    return live_neighbours
}

update_cell_state := proc(is_alive: bool, live_neighbours: i32) -> bool {
    if is_alive {
        return live_neighbours == 2 || live_neighbours == 3;
    } else {
       
        if live_neighbours == 3 {
            //fmt.println("Cell is born")
            return true
        }
        return live_neighbours == 3;
    }
}

get_time :: proc() -> f64 {
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}

dump_grid_state :: proc() {      
   
}

handle_mouse_input :: proc(mouse_x, mouse_y : i32, is_mouse_button_down : bool) {
    scaled_mouse_x := mouse_x / zoom_level
    scaled_mouse_y := mouse_y / zoom_level

    fmt.println("Mouse X : ", scaled_mouse_x)
    fmt.println("Mouse Y : ", scaled_mouse_y)

    //printe cell life and isSet
    fmt.println("Cell life : ", cellLife)
    fmt.println("Is set : ", isSet)

    if grid_state[scaled_mouse_x][scaled_mouse_y] {
        fmt.println("Cell is alive")
    }
    else {
        fmt.println("Cell is dead")
    }   

    // Check if the mouse loc is false
    if !grid_state[scaled_mouse_x][scaled_mouse_y] {
        
        if !isSet {
            fmt.println("Cell is dead------------")
            fmt.println("Cell Life : ", cellLife)
            cellLife = true
            isSet = true
        }   
        
        if isSet{
            grid_state[scaled_mouse_x][scaled_mouse_y] = cellLife
        }  
        return 
    }

    // Check if the mouse loc is true
    if grid_state[scaled_mouse_x][scaled_mouse_y] {

        if !isSet {
            fmt.println("Cell is alive-----------")
            fmt.println("Cell Life : ", cellLife)
            cellLife = false
            isSet = true
        }   
        
        if isSet{
            grid_state[scaled_mouse_x][scaled_mouse_y] = cellLife
        }  

        return
    }

    if isSet{
        grid_state[scaled_mouse_x][scaled_mouse_y] = cellLife
    }    
}

draw_batch :: proc(x, y, width, height: i32, renderer: ^SDL.Renderer) {
    rect := SDL.Rect{
        x = x * CELL_SIZE * zoom_level,
        y = y * CELL_SIZE * zoom_level,
        w = width * CELL_SIZE * zoom_level,
        h = height * CELL_SIZE * zoom_level,
    }
    SDL.SetRenderDrawColor(renderer, 100, 0, 0, 255) 
    SDL.RenderFillRect(renderer, &rect)
}

logger :: proc(msg: string, logFilePath : string = "log.txt") {
    fmt.println(msg)
    // Open or create the log file for appending
    file, err := os.open(logFilePath, os.O_WRONLY | os.O_APPEND | os.O_CREATE, 0666) // Adjust the mode flags and permissions as needed
    if err != os.ERROR_NONE {
        fmt.eprintln("Failed to open log file:", err)
        os.exit(1)
    }
    defer os.close(file)

    // Attempt to get the current time
    current_time := time.now()

    // Write the message to the log file along with the current time
    fmt.fprintf(file, "%s: %s\n", current_time, msg)  
}
