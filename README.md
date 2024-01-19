# Norse Grids Game Code Breakdown
![image](https://github.com/glennwiz/NorseGridsOfGnipahellir/assets/195927/7940b2de-0b9d-4707-a1d6-dfa36008548b)

# Runes of Conway's Game of Life #

This code is for a simple grid-based game using SDL2 in Odin language. Let's go through it in the world of gnipahellir.

## Package Import

```odin
package gnipahellir
```

**gnipahellir** 

"Norse Grids": The Essence of Odin's Game World

Embark on a journey to "Norse Grids", a realm where ancient myths and digital landscapes merge. Each cell in this Odin-crafted world, part of the GridState, is a land piece in the Norse cosmos, teeming with potential for life or stillness, as dictated by the CellState structure. Here, fate is not a solitary thread but an intricate weave, influenced by neighboring cells.

Awakening the World: Game Start-Up

In the beginning, the world is a dormant grid, each cell asleep. Yet, with the start of the game, life stirs. The SDL libraries ignite, birthing a window that serves as a portal to this borderless Norse universe, fully immersing the player.

Rhythm of the Cosmos: Game Loop and Timing

At the heart of this realm, the game loop pulses like the rhythm of the cosmos, controlling time and events. Each cycle, marked by TARGET_DT for consistent frame rates, is a mix of player interaction and the life-death dance on the grid.

Divine Play: Interaction and Events

Players rise as deities, shaping this world through keystrokes and mouse movements. Each action breathes life into a cell or dooms it to oblivion, the grid echoing their will. A click brings life; another, darkness.

Visual Saga: Grid Rendering

As the story unfolds, the renderer brings the grid to life, cell by cell. Colors transition from deep blacks to greys, reflecting the Norse theme. The grid, a living entity, changes with the zoom level, offering players the choice to view the grand narrative or individual life threads.
