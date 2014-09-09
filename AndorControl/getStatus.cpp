/* getStatus.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [RESPONSE CODE, CAMERA STATUS CODE]
 *
 * DESCRIPTION: Queries the current status of the camera. DRV_IDLE (20073)
 *              must be returned before starting
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
    
    int camStatus;
    
    unsigned int andorCode = GetStatus(&camStatus);
    
    /* cast the values for MATLAB */
    
    UINT32_T andorCode32 = (UINT32_T) andorCode;
    INT32_T status = (INT32_T) camStatus;
    
    /* RETURNING THE STATUS CODES */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of our status code to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));
    
    plhs[1] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    double * statPtr = mxGetPr(plhs[1]);
    memcpy(statPtr, &status, sizeof(status));
    
    
    return;
}
