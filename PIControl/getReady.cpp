/* getReady.cpp
 *
 * ARGUMENTS: [CONTROLLER ID]
 *
 * RETURNS: STATUS (1 = READY, 0 = BUSY)
 *
 * DESCRIPTION: Call this function to check wheterh the stage can be
 *              commanded following an reference move
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
                "No Input arguments accepted.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Stage ID should be an integer");
    }
    
    int controllerID = (int) mxGetScalar(prhs[0]);
    
    int piControllerReady, errorCode;
    BOOL fIfError = PI_IsControllerReady(controllerID,&piControllerReady);
    if (fIfError == FALSE) {
        errorCode = PI_GetError(controllerID);
        if (errorCode != 307) // 307 is timeout - i.e. not ready
            std::printf("\nError %i in ready query\n", errorCode );
        piControllerReady = 0;
    }
    
    /* return the answer */
    
    INT32_T piControllerReady32 = (INT32_T) piControllerReady;
    
    mwSignedIndex dims [2] = {1,1};
    
    plhs[0] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    double * mDataPtr = mxGetPr(plhs[0]);
    memcpy(mDataPtr, &piControllerReady32, sizeof(piControllerReady32));
    
    return;
    
}