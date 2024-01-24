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

    grid_state[16] [5] = true 
    grid_state[15] [6] = true; grid_state[17] [6] = true
    grid_state[14] [7] = true; grid_state[18] [7] = true
    grid_state[13] [8] = true; grid_state[19] [8] = true
    grid_state[14] [9] = true; grid_state[18] [9] = true
    grid_state[15] [10] = true; grid_state[17] [10] = true
    grid_state[16] [11] = true; 
    grid_state[15] [12] = true; grid_state[17] [12] = true
    grid_state[14] [13] = true; grid_state[18] [13] = true
    grid_state[13] [14] = true; grid_state[19] [14] = true      

}