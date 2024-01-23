package main

import "core:fmt"
import "core:math/rand"

GRID_SIZE :: 64

// CellGrid defines a 64x64 grid of boolean values
CellGrid :: [GRID_SIZE][GRID_SIZE]bool

main :: proc() {

    // Create a 64x64 grid of boolean values
    grid := CellGrid{}
    for i := 0; i < GRID_SIZE; i = i + 1 {
        for j := 0; j < GRID_SIZE; j = j + 1 {
            grid[i][j] = false
        }
    }
    
    for i := 0; i < GRID_SIZE; i = i + 1 {
        for j := 0; j < GRID_SIZE; j = j + 1 {
            
            v := rand.int_max(2)
            grid[i][j] = v == 1            
        }
    }

    // Print the grid
    for i := 0; i < GRID_SIZE; i = i + 1 {
        for j := 0; j < GRID_SIZE; j = j + 1 {
            if grid[i][j] {
                fmt.print("#")
            } else {
                fmt.print(".")
            }
        }
        fmt.println("")
    }

    gp : ^[GRID_SIZE][GRID_SIZE]bool
    gp = &grid
  
    //lets time this loop
    //https://pkg.odin-lang.org/core/time/#duration
    
    for i := 0; i < 64; i += 1 {
        for j := 0; j < 64; j += 1 {

            ff :=  &gp[i][j]

            ff^ = false         
        }
        fmt.println("")
    }


    // Print the grid
    for i := 0; i < GRID_SIZE; i = i + 1 {
        for j := 0; j < GRID_SIZE; j = j + 1 {
            if grid[i][j] {
                fmt.print("#")
            } else {
                fmt.print(".")
            }
        }
        fmt.println("")
    }

    fmt.println("Random u32: ",rand.uint32());

    // Using local random number generator
    my_rand := rand.create(1)
    fmt.println(rand.uint32(&my_rand))
    fmt.println(rand.uint32(&my_rand))

    //get random 0 - 9 
    //https://pkg.odin-lang.org/core/math/rand/#int_max   
    fmt.println(rand.int_max(10))
    fmt.println(rand.int_max(10))
    fmt.println(rand.int_max(10))
    fmt.println(rand.int_max(10))
    fmt.println(rand.int_max(10))

    //get random 0 - 1
    fmt.println(rand.int_max(2))
    fmt.println(rand.int_max(2))
    fmt.println(rand.int_max(2))
    fmt.println(rand.int_max(2))
     
    value := 42             // An integer variable
    ptr := &value           // A pointer to the integer variable      

    fmt.println("Value before:", value)
    fmt.println("Pointer address:", ptr)

    ptr^ = 21               // Dereferencing the pointer and changing the value it points to
    fmt.println("Value after:", value)  
    fmt.println("1-----------------")

    i := 123 
    p: ^int                 // Declare a pointer to an integer
    p = &i                  // p now holds the address of i
    fmt.println("Memory address of i:", p) 
    fmt.println("Value of i through p:", p^) // Dereference p to read i's value
    p^ = 1337               // Modify i through the pointer p
    fmt.println("New value of i:", i) 

    fmt.println("2-----------------")

    cell_status := true
    p_cell := &cell_status  // Pointer to cell_status
    fmt.println("Memory address of cell_status:", p_cell)
    p_cell^ = false         // Modify cell_status through the pointer
    fmt.println("New value of cell_status:", p_cell^)

    fmt.println("3-----------------")

    // Demonstrating pointer usage with strings
    stringX := "Gemstones"
    p_string := &stringX    // Pointer to stringX
    p_string^ = "are"       // Modify stringX through the pointer
    p_string^ = "gems"      // Modify stringX again

    fmt.println("Should print 'gems':", stringX)
}
