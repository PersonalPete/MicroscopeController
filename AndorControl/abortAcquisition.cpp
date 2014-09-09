/* abortAcquisition.cpp
 * 
 * ARGUMENTS: NONE
 * 
 * RETURNS: STATUS CODE
 * 
 * DESCRIPTION: Call this function to abort an acquisition (e.g. spooling)
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

    /* Abort the current acquisition */
    unsigned int andorCode = AbortAcquisition(); // passes a null pointer to char as argument
    
    UINT32_T andorCode32 = (UINT32_T) andorCode;

    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * outDataPtr = mxGetPr(plhs[0]);
       
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(outDataPtr, &andorCode32, sizeof(andorCode32));
    
    
    
    return;
}
