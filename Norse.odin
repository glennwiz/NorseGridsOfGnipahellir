package gnipahellir

import "core:fmt"
import "core:os"
import "core:mem"
import "base:runtime"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"
import "core:time"
//import file runes.odin    


TITLE :: "Gnipahellir"
TITLE_BAR_HEIGHT :: 30
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC
WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
TARGET_DT :: 1000 / 100
CELL_SIZE :: 1

NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE
GRID_STATE  :: [NUM_CELLS_X][NUM_CELLS_Y]bool

PERF_COUNT              :u64= 0

cell_life               :bool
is_set                  :bool
cell_count              :i32 = 0

zoom_level              :i32 = 20
zoom_step               :i32 = 2

bug_mode_flipper        :bool = false
bug_mode_flipper_count  := 0
bug_mode                :bool = false
sim_running             :bool
sim_speed               :i32 = 60
sim_speed_step          :i32 = 5
grid_show               :bool = false

center_x := WINDOW_WIDTH / 2
center_y := WINDOW_HEIGHT / 2

grid_state              : GRID_STATE 
next_grid_state         : GRID_STATE 
grid_state_history := make([dynamic]GRID_STATE, 5, 5)

Grid :: struct {
    cells: ^[NUM_CELLS_X * NUM_CELLS_Y]bool,
}

LogLevel :: enum {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
} 

Runes :: enum {
    F,
    O,
    R,
    Empty,
}

Static_rune_render := Runes.O
current_log_level := LogLevel.INFO

Game :: struct {
    perf_frequency: f64,
    renderer: ^SDL.Renderer,
}

CellState :: struct {
    x: i32,
    y: i32,
    is_alive: bool
}

offset_x_o :i32= -2800
offset_y_o :i32= -2160

offset_x :i32= -2800
offset_y :i32= -2160

range_start :i32= 2
range_end :i32= 20

game := Game{}

main :: proc() { 
    logger("Starting Norse grids!", LogLevel.INFO)

    assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
    assert(SDL_Image.Init(SDL_Image.INIT_PNG) != nil, SDL.GetErrorString())
    defer SDL.Quit()

    window := SDL.CreateWindow(
        "Norse grids!",
        SDL.WINDOWPOS_CENTERED,
        SDL.WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_FLAGS| SDL.WINDOW_BORDERLESS,   
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
    print_commands();
    game_loop : for {
        start = get_time()       
   
        run_draw_sync();

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
                        if zoom_level > 20 { 
                            zoom_level = 20                            
                        } 
                        run_draw_sync()   
                                     
                        fmt.println("zoom_level  ", zoom_level)
                    case .Z:
                        zoom_level -= zoom_step                       
                        if zoom_level < 2 { 
                            zoom_level = 2
                        }
                        run_draw_sync()
                        fmt.println("zoom_level  ", zoom_level)
                    case .SPACE:
                        sim_running = !sim_running
                        fmt.println("sim_running  ", sim_running)
                    case .COMMA:
                        sim_speed += sim_speed_step

                        if sim_speed > 100 { 
                            sim_speed = 100
                        }
                        fmt.println("sim_speed  ", 100 - sim_speed )
                    case .PERIOD:
                        sim_speed -= sim_speed_step
                        if sim_speed < 1 { 
                            sim_speed = 1
                        } 
                        fmt.println("sim_speed  ", 100 - sim_speed)
                    case .D:
                        current_log_level = LogLevel.DEBUG
                        fmt.println("current_log_level  ", current_log_level)
                    case .M:
                        if bug_mode {
                            grid_state = next_grid_state                            
                        }

                        if !bug_mode {
                            next_grid_state = grid_state
                        }

                        bug_mode = !bug_mode
                        fmt.println("bug_mode  ", bug_mode)
                    case .N:
                        if bug_mode_flipper {                            
                            bug_mode_flipper_count += 1
                            fmt.println("|||||Bug mode flipper count: ", bug_mode_flipper_count)
                        }

                        if !bug_mode_flipper {                            
                            bug_mode_flipper = !bug_mode_flipper
                            fmt.println("bug_mode_flipper  ", bug_mode_flipper)
                        }
                    case .O:
                        Clear();
                        Static_rune_render = Runes.O
                        fmt.println("Static_rune_render  ", Static_rune_render)
                    case .F:
                        Clear();
                        Static_rune_render = Runes.F
                        fmt.println("Static_rune_render  ", Static_rune_render)
                    case .R:
                        Clear();
                        Static_rune_render = Runes.R
                        fmt.println("Static_rune_render  ", Static_rune_render)     
                    case .F1:
                         Clear();
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
                is_set = false
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
    
        last_tick_rune := Static_rune_render
        dont_render := false
        if Static_rune_render != last_tick_rune
        {
            //clear the grid
            for x :i32= 0; x < NUM_CELLS_X; x += 1 {
                for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
                    grid_state[x][y] = false
                }
            }
            dont_render = true
        }

        if Static_rune_render == Runes.O && !dont_render
        {
            get_rune_o();
        }

        if Static_rune_render == Runes.F && !dont_render
        {
            //fmt.println("Static_rune_render  ", Static_rune_render)
            get_rune_f();
        }
                
        if Static_rune_render == Runes.R && !dont_render
        {
            get_rune_r();
        }

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
        if(grid_show) {
            SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255) // Set color to black

            for x :i32= 0; x < WINDOW_WIDTH; x += zoom_level {
                SDL.RenderDrawLine(game.renderer,  x, 0, x, WINDOW_HEIGHT)       
            }

            // Drawing black horizontal lines spaced 5 pixels apart
            for y :i32= 0; y < WINDOW_HEIGHT; y +=  zoom_level {
                SDL.RenderDrawLine(game.renderer, 0, y, WINDOW_WIDTH, y)       
            }
        }
    

        SDL.RenderPresent(game.renderer)       

        if sim_running && counter % sim_speed == 0 {
            
            run_next_generation()
            
            if !bug_mode {
                 // swap the grids
                temp_grid := grid_state
                grid_state = next_grid_state
                next_grid_state = temp_grid
            }

            append(&grid_state_history, grid_state)
        }

         // Frame rate management
         end = get_time()
         for end - start < TARGET_DT {
             end = get_time()
         }
 
         if current_log_level == LogLevel.DEBUG && counter % 60 == 0	{
             perf_frequency := game.perf_frequency; // The frequency of the performance counter           
             duration_ticks := end - start; // Duration in ticks         
             duration_seconds := duration_ticks / perf_frequency; // Convert ticks to seconds  
             logger(fmt.aprintf("Duration in seconds: ", duration_seconds))      
             minutes := i64(duration_seconds / 60)
             seconds := i64(duration_seconds) % 60
             milliseconds := i64((duration_seconds - f64(i64(duration_seconds))) * 1000)
             microseconds := i64((duration_seconds - f64(i64(duration_seconds))) * 1000000)
             nanoseconds := i64((duration_seconds - f64(i64(duration_seconds))) * 1000000000)
             logger(fmt.aprintf("Duration: ", milliseconds, " milliseconds", microseconds, " microseconds", nanoseconds," nanoseconds"))          
            
             alive_cells := count_alive_cells(grid_state) 

             //print dead and alive cells and log them
             logger(fmt.aprintf("Alive cells: ", alive_cells ))

             //log how much computation time was used per cell
             vec :f64= 0
             vec = f64(alive_cells) / f64(nanoseconds) 
             logger(fmt.aprintf("Average computation time per cell: ", vec, " nanoseconds"))

             counter = 0                       
         }
         
         counter += 1      
    }
}

Clear :: proc()   { // Clear the grid and reset all related variables
    //Print the Static_rune_render
    Static_rune_render = Runes.Empty
    for x :i32= 0; x < NUM_CELLS_X; x += 1 {
        for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
            grid_state[x][y] = false
            next_grid_state[x][y] = false
        }
    }

    sim_running = false
    bug_mode = false
    bug_mode_flipper = false
    bug_mode_flipper_count = 0 
    offset_x = offset_x_o
    offset_y = offset_y_o
    
    // Clear the grid state history
    clear(&grid_state_history)
    
    logger("Screen cleared and all settings reset", LogLevel.INFO)
    run_draw_sync()  // Update the display
}

run_next_generation :: proc() {
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

            if bug_mode {
                grid_state[x][y] = update_cell_state(grid_state[x][y], live_neighbours);
            }

            next_grid_state[x][y] = update_cell_state(grid_state[x][y], live_neighbours);
        }
    } 
}

count_alive_cells := proc(grid_state: [NUM_CELLS_X][NUM_CELLS_Y]bool) -> i32 {
    alive_cells :i32= 0
    for x :i32= 0; x < NUM_CELLS_X; x += 1 {
        for y :i32= 0; y < NUM_CELLS_Y; y += 1 {
            if grid_state[x][y] {
                alive_cells += 1
            }
        }
    }
    return alive_cells
}

/*
    function count_live_neighbours calculates the number of live neighbors around a cell in a toroidal grid represented by grid_state. 
    It uses nested loops to examine a 3x3 cell neighborhood centered at (x, y) while handling boundary wrapping. 
    The function returns the count of live neighbors for the specified cell.
*/
count_live_neighbours := proc(grid_state: [NUM_CELLS_X][NUM_CELLS_Y]bool, x, y: i32) -> i32 {
    live_neighbours :i32= 0
    for nx := x-1; nx <= x+1; nx += 1 {
        for ny := y-1; ny <= y+1; ny += 1 {
            // Wrap around horizontally
            wrapped_nx := (nx + NUM_CELLS_X) % NUM_CELLS_X
            // Wrap around vertically
            wrapped_ny := (ny + NUM_CELLS_Y) % NUM_CELLS_Y

            if !(wrapped_nx == x && wrapped_ny == y) && grid_state[wrapped_nx][wrapped_ny] {
                live_neighbours += 1
            }
        }
    }

    return live_neighbours
}

update_cell_state := proc(is_alive: bool, live_neighbours: i32) -> bool {
    if is_alive {
        
        if live_neighbours < 2 || live_neighbours > 3 {
            
            return false
        }
        return true
    } else {
       
        if live_neighbours == 3 {

            return true
        }       
        return false
    }
}

get_time :: proc() -> f64 {
    PERF_COUNT = SDL.GetPerformanceCounter()   
    return f64(PERF_COUNT) * 1000 / game.perf_frequency
}

handle_mouse_input :: proc(mouse_x, mouse_y : i32, is_mouse_button_down : bool) {
    scaled_mouse_x := mouse_x / zoom_level 
    scaled_mouse_y := mouse_y / zoom_level

    scaled_mouse_x -= offset_x / zoom_level
    scaled_mouse_y -= offset_y / zoom_level
    
    // Check if the mouse is outside the grid
    if scaled_mouse_x < 0 || scaled_mouse_x >= NUM_CELLS_X || scaled_mouse_y < 0 || scaled_mouse_y >= NUM_CELLS_Y {
        return
    }    

    //print location of the mouse
    fmt.println("Mouse location: ", scaled_mouse_x, scaled_mouse_y)

    if grid_state[scaled_mouse_x][scaled_mouse_y] {

        fmt.println("Cell is alive")
    }
    else {
        fmt.println("Cell is dead")
    }   

    // Check if the mouse loc is false
    if !grid_state[scaled_mouse_x][scaled_mouse_y] {
        
        if !is_set {
            fmt.println("Cell is dead------------")
            fmt.println("Cell Life : ", cell_life)
            cell_life = true
            is_set = true
        }   
        
        if is_set{
            grid_state[scaled_mouse_x][scaled_mouse_y] = cell_life
        }  
        return 
    }

    // Check if the mouse loc is true
    if grid_state[scaled_mouse_x][scaled_mouse_y] {

        if !is_set {
            fmt.println("Cell is alive-----------")
            fmt.println("Cell Life : ", cell_life)
            cell_life = false
            is_set = true
        }   
        
        if is_set{
            grid_state[scaled_mouse_x][scaled_mouse_y] = cell_life
        }  

        return
    }

    if is_set{
        grid_state[scaled_mouse_x][scaled_mouse_y] = cell_life
    }    
}

draw_batch :: proc(x, y, width, height: i32, renderer: ^SDL.Renderer) {
    rect := SDL.Rect{
        x = x * CELL_SIZE * zoom_level,
        y = y * CELL_SIZE * zoom_level,     

        w = width * CELL_SIZE * zoom_level,
        h = height * CELL_SIZE * zoom_level,
    }

    rect.x += offset_x; // Adjust x position by offset_x
    rect.y += offset_y; // Adjust y position by offset_y if needed

    SDL.SetRenderDrawColor(renderer, 100, 0, 0, 255) 
    SDL.RenderFillRect(renderer, &rect)
}

logger :: proc(msg: string, level: LogLevel = LogLevel.INFO, logFilePath : string = "log.txt") {
    
    if level < current_log_level {
        return // This message's level is below the current threshold; ignore it.
    }
    
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

run_draw_sync :: proc(){
    calc_offset()
    turn_on_off_grid()  
}

calc_offset := proc() {    
        
    offset_x = i32(map_range_x_to_value(f32(zoom_level)))
    offset_y = i32(map_range_y_to_value(f32(zoom_level)))
}

map_range_x_to_value :: proc(input_value: f32, range_start: f32 = 2.0, range_end: f32 = 20.0, value_start: f32 = 0.0, value_end: f32 = -2800.0) -> f32 {
    proportion := (input_value - range_start) / (range_end - range_start)
    mapped_value := proportion * (value_end - value_start) + value_start
    return mapped_value
}

map_range_y_to_value :: proc(input_value: f32, range_start: f32 = 2.0, range_end: f32 = 20.0, value_start: f32 = 0.0, value_end: f32 = -2160.0) -> f32 {
    proportion := (input_value - range_start) / (range_end - range_start)
    mapped_value := proportion * (value_end - value_start) + value_start
    return mapped_value
}

turn_on_off_grid :: proc(){
    if(zoom_level == 2 || zoom_level ==4 ||zoom_level == 20){
        grid_show = true
    }
    else{
        grid_show = false
    }
}

print_commands :: proc() {
    fmt.println("Available Commands:")
    fmt.println("------------------")
    fmt.println("Keyboard Commands:")
    fmt.println("1. ESCAPE: Exit the game loop")
    fmt.println("2. X: Increase zoom level")
    fmt.println("3. Z: Decrease zoom level")
    fmt.println("4. SPACE: Toggle simulation running state")
    fmt.println("5. COMMA: Increase simulation speed")
    fmt.println("6. PERIOD: Decrease simulation speed")
    fmt.println("7. D: Set log level to DEBUG")
    fmt.println("8. M: Toggle bug mode")
    fmt.println("9. N: Toggle bug mode flipper")
    fmt.println("10. O: Set Static_rune_render to Runes.O")
    fmt.println("11. F: Set Static_rune_render to Runes.F")
    fmt.println("12. R: Set Static_rune_render to Runes.R")
    fmt.println("13. F1: Clear the grid")
    fmt.println()
    fmt.println("Mouse Commands:")
    fmt.println("14. Left mouse button click: Toggle cell state")
    fmt.println("15. Left mouse button drag: Draw cells")
}
