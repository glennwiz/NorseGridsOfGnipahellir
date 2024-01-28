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
    grid_state[153] [115].is_alive = true;
    grid_state[153] [116].is_alive = true;
    grid_state[153] [117].is_alive = true;
    grid_state[153] [118].is_alive = true;
    grid_state[153] [119].is_alive = true;
    grid_state[153] [120].is_alive = true;
    grid_state[153] [121].is_alive = true;   
    grid_state[153] [122].is_alive = true; 
    grid_state[153] [123].is_alive = true; 
    grid_state[153] [124].is_alive = true;
    grid_state[153] [125].is_alive = true;

    grid_state[156] [115].is_alive = true;
    grid_state[155] [116].is_alive = true;
    grid_state[154] [117].is_alive = true;
    grid_state[153] [118].is_alive = true; 

    grid_state[159] [115].is_alive = true;
    grid_state[158] [116].is_alive = true;
    grid_state[157] [117].is_alive = true;    
    grid_state[154] [120].is_alive = true;  
    grid_state[155] [119].is_alive = true;
    grid_state[156] [118].is_alive = true;

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

    grid_state[10][115].is_alive = true;
    grid_state[10][116].is_alive = true; 
    grid_state[10][117].is_alive = true; 
    grid_state[10][118].is_alive = true; 
    grid_state[10][119].is_alive = true; 
    grid_state[10][120].is_alive = true; 
    grid_state[10][121].is_alive = true; 
    grid_state[10][122].is_alive = true; 
    grid_state[10][123].is_alive = true; 

    grid_state[11] [6].is_alive = true; 
    grid_state[12] [7].is_alive = true; 
    grid_state[13] [8].is_alive = true;
    grid_state[12] [9].is_alive = true;
    grid_state[11] [10].is_alive = true; 
    grid_state[12] [11].is_alive = true;
    grid_state[13] [12].is_alive = true;
    grid_state[14] [13].is_alive = true;
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
    logger("1 get_rune_o\n");
    //how to  update the grid_state trough a pointer to the grid_state

    grid_state[156][115].is_alive = true 
    logger("2 get_rune_o\n")
    grid_state[155] [116].is_alive = true
    grid_state[154] [117].is_alive = true 
    grid_state[153] [118].is_alive = true 
    grid_state[154] [119].is_alive = true 
    grid_state[155] [120].is_alive = true 
    grid_state[155] [122].is_alive = true 
    grid_state[154] [123].is_alive = true 
    grid_state[153] [124].is_alive = true 
    grid_state[157] [116].is_alive = true
    grid_state[158] [117].is_alive = true
    grid_state[159] [118].is_alive = true
    grid_state[158] [119].is_alive = true
    grid_state[157] [120].is_alive = true
    grid_state[156] [121].is_alive = true  
    grid_state[157] [122].is_alive = true
    grid_state[158] [123].is_alive = true
    grid_state[159] [124].is_alive = true    

}
