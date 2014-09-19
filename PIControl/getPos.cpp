/* getPos.cpp
 *
 * ARGUMENTS: [CONTROLLER ID]
 *
 * RETURNS: POSITION (mm)
 *
 * DESCRIPTION: Get the actual position of the stage
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
                "1 argument required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Stage ID should be an integer");
    }

    
    
    /* get the input arguments of position and controller ID */
    int controllerID = (int) mxGetScalar(prhs[0]);
    double pos ; //  position
    
    /* move! */
    char * szAxes = "1";
    BOOL fIfError = PI_qPOS(controllerID,szAxes,&pos); // NULL since we only have one axis per controller
    
    mwSignedIndex dims [2] = {1,1};
    
    plhs[0] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * mDataPtr = mxGetPr(plhs[0]);
    memcpy(mDataPtr, &pos, sizeof(pos));
    
    return;
    
}