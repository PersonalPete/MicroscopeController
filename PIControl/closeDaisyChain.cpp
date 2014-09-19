/* connectDaisyChainController.cpp
 *
 * ARGUMENTS: [DAISY CHAIN ID]
 *
 * RETURNS: N/A
 *
 * DESCRIPTION: Call this function to close communication with a daisy
 *              chain and all controllers in it
 *
 */


/* header files to use */
#include "mex.h" // required for mex files
#include <iostream> // for cout
#define __int64 INT64_T // since the PI files use a type we don't recognise

#include "PI_GCS2_DLL.h" // PI functions

// convenience function
bool isScalarArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == 1);
}

void
        mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "1 input argument required.");
    }
    if (nlhs > 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Daisy Chain ID should be an integer");
    }
    
    int daisyChainID = (int) mxGetScalar(prhs[0]);
    
    PI_CloseDaisyChain(daisyChainID);
    
    return;
    
}