/* getTimings.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [STATUS CODE, EXPOSURE TIME, KINETIC CYCLE TIME,...
 *                                          ACCUMULATION TIME]
 *
 * DESCRIPTION: Queries the current time settings of the camera - note that
 *              the time set is non-necessarily the one returned.
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
    if (nlhs > 4) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    float expT,accT,kinT;
    
    unsigned int andorCode = GetAcquisitionTimings(&expT,&accT,&kinT);
    
    /* cast the values for MATLAB */
    
    UINT32_T andorCode32 = (UINT32_T) andorCode;
    
    double expTD = (double) expT;
    double accTD = (double) accT;
    double kinTD = (double) kinT;
    
    /* RETURNING A STATUS CODE */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));
    
    plhs[1] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * expPtr = mxGetPr(plhs[1]);
    memcpy(expPtr, &expTD, sizeof(expTD));
    
    plhs[2] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * kinPtr = mxGetPr(plhs[2]);
    memcpy(kinPtr, &kinTD, sizeof(kinTD));
    
    plhs[3] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * accPtr = mxGetPr(plhs[3]);
    memcpy(accPtr, &accTD, sizeof(kinTD));
    
    return;
}
