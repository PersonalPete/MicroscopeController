/* getTemp.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [TEMP STATUS CODE, TEMP]
 *
 * DESCRIPTION: Queries the current temperature of the chip
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
                "No input arguments");
    }
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    
    int temp;
    int tempCode = GetTemperature(&temp); // current temperature
    
    
    
    /* cast the values for MATLAB */
    UINT32_T tempCode32 = (UINT32_T) tempCode;
        
    INT32_T temp32 = (INT32_T) temp;
 
    
    /* RETURNING A STATUS CODE */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(codePtr, &tempCode32, sizeof(tempCode32));
    
    plhs[1] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    double * tempPtr = mxGetPr(plhs[1]);
    memcpy(tempPtr, &temp32, sizeof(temp32));
    

    
    return;
}
