# Norse Grids Game Code Breakdown
![image](https://github.com/glennwiz/NorseGridsOfGnipahellir/assets/195927/40166846-5c8e-4c34-bcb3-88220f75c39c)

This code is for a simple grid-based game using SDL2 in Odin language. Let's go through it step-by-step.

## Package Import

```odin
package gnipahellir
```

- **gnipahellir:** The name of the package.

## Imports

```odin
import "core:fmt"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
```

- **core:fmt:** Standard formatting library.
- **SDL:** SDL2 library for handling graphics.
- **SDL_Image:** SDL2 extension for image handling.

## Constants

```odin
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC
WINDOW_WIDTH, WINDOW_HEIGHT :: 640, 480
TARGET_DT :: 1000 / 60
CELL_SIZE :: 5
NUM_CELLS_X :: WINDOW_WIDTH / CELL_SIZE
NUM_CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE
```

- **WINDOW_FLAGS:** Window display settings.
- **RENDER_FLAGS:** Renderer options.
- **WINDOW_WIDTH, WINDOW_HEIGHT:** Dimensions of the window.
- **TARGET_DT:** Targeted time for each frame (60 frames per second).
- **CELL_SIZE:** Size of each cell in the grid.
- **NUM_CELLS_X, NUM_CELLS_Y:** Number of cells in the X and Y axis.

## Data Structures

```odin
GridState :: [NUM_CELLS_X][NUM_CELLS_Y]bool
```

- **GridState:** A two-dimensional boolean array representing the grid's state.

```odin
Game :: struct {
    perf_frequency: f64,
    renderer: ^SDL.Renderer,
}
```

- **Game:** Struct containing performance frequency and renderer.

```odin
CellState :: struct {
    x: i32,
    y: i32,
    is_alive: bool
}
```

- **CellState:** Struct representing the state of a cell.

## Initialization

```odin
game := Game{}
```

- Initializes an instance of the Game struct.

## Main Procedure

```odin
main :: proc() {
```

- The main procedure where the program execution begins.

### Initializing Grid State

```odin
grid_state : GridState 
for x := 0; x < len(grid_state) ; x += 1 {
   for y := 0; y < len(grid_state[x]); y += 1 {        
        grid_state[x][y] = false
    }
}
```

- Initializes the grid state to false (off) for each cell.

### SDL Initialization

```odin
assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
assert(SDL_Image.Init(SDL_Image.INIT_PNG) != nil, SDL.GetErrorString())
defer SDL.Quit()
```

- Initializes SDL for video and image handling, with error checking.

### Creating Window and Renderer

```odin
window := SDL.CreateWindow(
    "Norse grids!",
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
```

- Creates an SDL window and renderer with error checking.

### Game Loop Setup

```odin
game_loop : for {
    // Game loop content here
}
```

- The main game loop where all game logic and rendering happens.

#### Getting Time for Frame Rate Management

```odin
start : f64
end : f64
counter : u32 = 0
event : SDL.Event
```

- Variables to manage time and events in the game loop.

#### Event Handling

```odin
if SDL.PollEvent(&event) {
    // Event handling logic here
}
```

- Handles SDL events like quitting the game or key presses.

#### Drawing and Updating Grid

- Various logic to handle drawing the grid, updating cell states, etc.

### Frame Rate Management

```odin
end = get_time()
for end - start < TARGET_DT {
    end = get_time()
}
```

- Manages the frame rate to stay around 60 FPS.

## Auxiliary Functions

```odin
get_time :: proc() -> f64 {
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}
```

- A helper function to get the current time for frame rate management.
