/* setTemp.cpp
 *
 * ARGUMENTS: INT TARGET TEMP
 *
 * RETURNS: [STATUS CODE]
 *
 * DESCRIPTION: Sets the thermoelectric temperature set point
 *
 */

/* header files to use */
#include "mex.h" // required for mex files
#include <iostream> // for cout
#include "atmcd32d.h" // Andor functions


// convenience function
bool isScalarArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == 1);
}

// The entry point for mex
void
        mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs !=1) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidNumInputs",
                "Wrong number of arguments");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Temperature is a scalar");
    }
    
    int targTemp = (int) mxGetScalar(prhs[0]);
       
    unsigned int ac = SetTemperature(targTemp); // set the temperature
    
    /* RETURNING A STATUS CODE */
    UINT32_T andorCode32 = (UINT32_T) ac;     
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));
    
    return;
}

