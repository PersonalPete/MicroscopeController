/* beginAcquire.cpp
 * 
 * ARGUMENTS: NONE
 * 
 * RETURNS: STATUS CODE
 * 
 * DESCRIPTION: After initialising the camera and setting the initial
 *              settings you can call this function to begin acquisition
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
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
  
    
    // Start acquiring is an Andor function
    unsigned int andorCode = StartAcquisition(); 
    
    UINT32_T andorCode32 = (UINT32_T) andorCode;
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    double * outDataPtr = mxGetPr(plhs[0]);
    memcpy(outDataPtr, &andorCode32, sizeof(andorCode32));
    
    
    
    return;
}
