/* connectDaisyChainController.cpp
 *
 * ARGUMENTS: [DAISY CHAIN ID, CONTROLLER NUMBER]
 *
 * RETURNS: CONTROLLER ID
 *
 * DESCRIPTION: Call this function to begin communication with a  particular
 *              PI stage in a daisy chain
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
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "2 input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Daisy Chain ID should be an integer");
    }
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Controller ID should be an integer");
    }
    
    int daisyChainID = (int) mxGetScalar(prhs[0]);
    int controllerNumber = (int) mxGetScalar(prhs[1]);
    
    INT32_T controllerID = (INT32_T) PI_ConnectDaisyChainDevice(daisyChainID,controllerNumber); // address set on controllers

    mwSignedIndex dims [2] = {1,1};
    
    plhs[0] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    double * mDataPtr = mxGetPr(plhs[0]);
    memcpy(mDataPtr, &controllerID, sizeof(controllerID));

    
    return;
    
}