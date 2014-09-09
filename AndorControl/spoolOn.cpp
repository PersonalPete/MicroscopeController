/* spoolOn.cpp
 *
 * ARGUMENTS: STRING SPOOLPATH
 *
 * RETURNS: RESPONSE CODE
 *
 * DESCRIPTION: Sets up spooling to a target directory. An example path is
 *              "/Folder/To/Spool to/spoolname"
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
    if (nrhs != 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No input arguments: Required String path");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    /* must be string argument */
    if (mxIsChar(prhs[0]) !=1)
        mexErrMsgTxt("Input must be string.");
    
    /* must be a single column */
    if (mxGetM(prhs[0]) !=1)
        mexErrMsgTxt("Must be row vector.");
    
    int buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1; // +1 because C strings are null terminated
    char* inputBuf = (char*) mxCalloc(buflen, sizeof(char)); // use the matlab memory allocation
    
    int status = mxGetString(prhs[0], inputBuf, buflen); // copy the prhs[0] string to the C string input_buf
    
    if (status !=0)
        std::printf("\nWarning: File name not well defined for spooling");
    
    /* STATUS CODE */
    unsigned int ac; 
    
    /* SPOOL TO TARGET */
    ac = SetSpool(1,5,inputBuf,10);
    
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

    /* FREE MEMORY */
    mxFree(inputBuf);
    
    return;
}
