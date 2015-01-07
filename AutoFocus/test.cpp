#include "mex.h"
#include <iostream>
#include "uc480.h"

#define DFT_EXP_TIME 10 // milliseconds per frame
#define DFT_FRAME_RATE 10 // frames per second
#define DFT_PX_CLOCK 35 // MHz (max 43)

#define H_PIX 1280
#define V_PIX 1024
#define N_FRAMES 300

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
        std::printf("Size of char* : %i",sizeof(char*));
    
        return;
    
}