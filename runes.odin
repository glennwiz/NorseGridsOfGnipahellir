package gnipahellir

import "core:fmt"
import "core:os"
import "core:mem"

get_rune_f :: proc() {

    //     o      o    o
    //     o    o    o
    //     o o     o 
    //     o     o
    //     o   o
    //     o o
    //     o   
    //     o     
    //     o        
    //     o
    //     o

    grid_state[10][5] = true; grid_state[13] [5] = true;  grid_state[16] [5] = true;
    grid_state[10] [6] = true;  grid_state[12] [6] = true; grid_state[15] [6] = true;
    grid_state[10] [7] = true;  grid_state[11] [7] = true; grid_state[14] [7] = true; 
    grid_state[10] [8] = true;  grid_state[13] [8] = true;
    grid_state[10] [9] = true;  grid_state[12] [9] = true;
    grid_state[10] [10] = true; grid_state[11] [10] = true; 
    grid_state[10] [11] = true; 
    grid_state[10] [12] = true; 
    grid_state[10] [13] = true; 
    grid_state[10] [14] = true;
    grid_state[10] [15] = true;
}

get_rune_r :: proc() {

    //     o
    //     o o
    //     o   o
    //     o     o
    //     o   o
    //     o o
    //     o   o
    //     o     o
    //     o      o   

    grid_state[10] [5] = true;
    grid_state[10] [6] = true;  grid_state[11] [6] = true; 
    grid_state[10] [7] = true;  grid_state[12] [7] = true; 
    grid_state[10] [8] = true;  grid_state[13] [8] = true;
    grid_state[10] [9] = true;  grid_state[12] [9] = true;
    grid_state[10] [10] = true; grid_state[11] [10] = true; 
    grid_state[10] [11] = true; grid_state[12] [11] = true;
    grid_state[10] [12] = true; grid_state[13] [12] = true;
    grid_state[10] [13] = true; grid_state[14] [13] = true;
}

get_rune_o :: proc() {

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

    grid_state[16] [2] = true 
    grid_state[15] [3] = true; grid_state[17] [3] = true
    grid_state[14] [4] = true; grid_state[18] [4] = true
    grid_state[13] [5] = true; grid_state[19] [5] = true
    grid_state[14] [6] = true; grid_state[18] [6] = true
    grid_state[15] [7] = true; grid_state[17] [7] = true
    grid_state[16] [8] = true; 
    grid_state[15] [9] = true; grid_state[17] [9] = true
    grid_state[14] [10] = true; grid_state[18] [10] = true
    grid_state[13] [11] = true; grid_state[19] [11] = true      

}