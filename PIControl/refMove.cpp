 /* refMove.cpp
 *
 * ARGUMENTS: [CONTROLLER ID]
 *
 * RETURNS: N/A
 *
 * DESCRIPTION: Performs a reference move - maybe do this if there is a
  *             problem with the stages/axes
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
                "Stage ID should be an integer");
    }
    
    int controllerID = (int) mxGetScalar(prhs[0]);
    char* szAxes = "1";
    BOOL fIfError = PI_FRF(controllerID,szAxes); // NULL since we only have one axis per stage
    
    return;
    
}    

