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
PERF_COUNT :u64= 0

cell_life :bool
is_set :bool
cell_count :i32 = 0

zoom_level :i32 = 20
zoom_step :i32 = 2

bug_mode_flipper :bool = false
bug_mode_flipper_count := 0
bug_mode :bool = false
sim_running :bool
sim_speed :i32 = 60
sim_speed_step :i32 = 5
grid_show :bool = false

center_x := WINDOW_WIDTH / 2
center_y := WINDOW_HEIGHT / 2

grid_state : [NUM_CELLS_X][NUM_CELLS_Y]Cell
next_grid_state : [NUM_CELLS_X][NUM_CELLS_Y]Cell
Game :: struct {
    perf_frequency: f64,
    renderer: ^SDL.Renderer,
}

Cell :: struct {
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
    fmt.println("Starting Norse grids!")

    grid_state = [NUM_CELLS_X][NUM_CELLS_Y]Cell{}

    game_loop : for {
    
        fmt.println("Starting game loop")
        //randomize_grid_state()
        for i := 0; i < NUM_CELLS_X; i += 1 {
            for j := 0; j < NUM_CELLS_Y; j += 1 {
                grid_state[i][j].is_alive = true
            }
        }
    }
       
}

get_time :: proc() -> f64 {
    PERF_COUNT = SDL.GetPerformanceCounter()   
    return f64(PERF_COUNT) * 1000 / game.perf_frequency
}
