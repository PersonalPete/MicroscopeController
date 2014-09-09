/* setInternalTrigger.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [RESPONSE CODE]
 *
 * DESCRIPTION: Sets up internal triggering. Kinetic cycle time dictates 
 *              repeat rate.
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
    if (nrhs > 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Too many input arguments");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }

    /* ARRAY FOR STATUS CODES */
    
    unsigned int ac;
    
    /* SETUP THE CAMERA */
    
    ac = SetTriggerMode(0); 

    
    /*CHECK THEY WENT OK */
    
    UINT32_T andorCode32 = (UINT32_T) ac;
    
    
    /* RETURNING THE STATUS CODE */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of our status code to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));

    
    
    return;
}
