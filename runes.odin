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

    grid_state[156] [115] = true 
    grid_state[155] [116] = true; grid_state[157] [116] = true
    grid_state[154] [117] = true; grid_state[158] [117] = true
    grid_state[153] [118] = true; grid_state[159] [118] = true
    grid_state[154] [119] = true; grid_state[158] [119] = true
    grid_state[155] [120] = true; grid_state[157] [120] = true
    grid_state[156] [121] = true; 
    grid_state[155] [122] = true; grid_state[157] [122] = true
    grid_state[154] [123] = true; grid_state[158] [123] = true
    grid_state[153] [124] = true; grid_state[159] [124] = true     

}