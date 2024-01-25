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
              //X     Y
    grid_state[153] [115] = true;
    grid_state[153] [116] = true;
    grid_state[153] [117] = true;
    grid_state[153] [118] = true;
    grid_state[153] [119] = true;
    grid_state[153] [120] = true;
    grid_state[153] [121] = true;   
    grid_state[153] [122] = true; 
    grid_state[153] [123] = true; 
    grid_state[153] [124] = true;
    grid_state[153] [125] = true;

    grid_state[156] [115] = true;
    grid_state[155] [116] = true;
    grid_state[154] [117] = true;
    grid_state[153] [118] = true; 

    grid_state[159] [115] = true;
    grid_state[158] [116] = true;
    grid_state[157] [117] = true;    
    grid_state[154] [120] = true;  
    grid_state[155] [119] = true;
    grid_state[156] [118] = true;

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

    grid_state[156][115] = true;
    grid_state[10][116] = true;  grid_state[11] [6] = true; 
    grid_state[10][117] = true;  grid_state[12] [7] = true; 
    grid_state[10][118] = true;  grid_state[13] [8] = true;
    grid_state[10][119] = true;  grid_state[12] [9] = true;
    grid_state[10][120] = true; grid_state[11] [10] = true; 
    grid_state[10][121] = true; grid_state[12] [11] = true;
    grid_state[10][122]  = true; grid_state[13] [12] = true;
    grid_state[10][123] = true; grid_state[14] [13] = true;
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