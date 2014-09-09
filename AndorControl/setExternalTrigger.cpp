/* setExternalTrigger.cpp
 *
 * ARGUMENTS: BOOLEAN FASTTRIGGER (TRUE)
 *
 * RETURNS: [RESPONSE CODE]
 *
 * DESCRIPTION: Sets up external triggering. Fast triggering is enabled by
 *              default - this doesn't wait for a keep clean to allow
 *              a trigger
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
    if (nrhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Too many input arguments");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (nrhs == 1 && ( !mxIsLogical(prhs[0]) || !mxGetN(prhs[0]) || !mxGetM(prhs[0]) ) ) {
        mexErrMsgIdAndTxt("Mscope:initialiseCamera:invalidArg","Logical argument required");
    }
    bool fastTrig = true; // default is to allow fast triggering
    
    if (nrhs == 1) {
        fastTrig = *mxGetLogicals(prhs[0]);
    }
    /* ARRAY FOR STATUS CODES */
    
    unsigned int ac[2];
    
    /* SETUP THE CAMERA */
    
    ac[0] = SetTriggerMode(1); 
    if (fastTrig) {
        ac[1] = SetFastExtTrigger(1);
    } else {
        ac[1] = SetFastExtTrigger(0);
    }
    
    /*CHECK THEY WENT OK */
    
    UINT32_T andorCode32 = DRV_SUCCESS;
    
    for (int ii = 0; ii < 2 ; ii++) {
        if (ac[ii] != DRV_SUCCESS) {
            std::printf("\nError initialising Camera\n%i returned code: %i\n",ii,ac[ii]);
            andorCode32 = 1;
        }
    }
    
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
