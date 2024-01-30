package gnipahellir

import "core:fmt"
import "core:math/rand"
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
GRID_STATE :: [NUM_CELLS_X][NUM_CELLS_Y]CellState
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

grid_state : [NUM_CELLS_X][NUM_CELLS_Y]CellState
next_grid_state : [NUM_CELLS_X][NUM_CELLS_Y]CellState

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

    my_rand := rand.create(656565)
	fmt.println(rand.uint64(&my_rand))    
    
    fmt.println("Starting Norse grids!", LogLevel.INFO)

    // Initialize each cell in the grid
    for i := 0; i < NUM_CELLS_X; i += 1{
        for j := 0; j < NUM_CELLS_Y; j += 1{
            grid_state[i][j] = CellState{i32(i), i32(j), false} // Cast i and j to i32
        }
    }

    //print all cells   
    for i := 0; i < NUM_CELLS_X; i += 1{
         for j := 0; j < NUM_CELLS_Y; j += 1{      

              //set random cells to alive
                if rand.uint64(&my_rand) % 2 == 0 {
                    grid_state[i][j].is_alive = true
                }
         }
    }

    // print grid
    if false{

        for i := 0; i < NUM_CELLS_X; i += 1{
            for j := 0; j < NUM_CELLS_Y; j += 1{
                if grid_state[i][j].is_alive {
                    fmt.print("O")
                } else {
                    fmt.print(" ")
                }
            }
            fmt.println("")
        }

    }
   
    //set random color
    r := u8(rand.uint64(&my_rand)) % 255
    g := u8(rand.uint64(&my_rand)) % 255
    b := u8(rand.uint64(&my_rand)) % 255

    //set random color
    c := SDL.Color{r, g, b, 255}

    //change the console color
    fmt.print("\x1b[38;2;", r, ";", g, ";", b, "m")

}
