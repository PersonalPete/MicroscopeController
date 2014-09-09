/* setupAndAcqSingle.cpp
 * 
 * ARGUMENTS: NONE
 * 
 * RETURNS: CAMERA IMAGE
 * 
 * DESCRIPTION: Gets the most recent image so we can display it
 * 
 */

/* header files to use */        
#include "mex.h" // required for mex files
#include <iostream> // for cout
#include "atmcd32d.h" // Andor functions


// The entry point for mex
void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "One input argument required.");
    }
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    

    int returnInt;
    
    
    
    
    
    
    
    
    return
}