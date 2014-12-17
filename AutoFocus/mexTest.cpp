#include "mex.h"
#include <iostream>
#include "uc480.h"

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    int numCams;
    
    int outVar = is_GetNumberOfCameras(&numCams);
    
    std::printf("\n%i cameras\n",numCams);
    
   
    
   return;
   
}