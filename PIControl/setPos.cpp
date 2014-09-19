/* setPos.cpp
 *
 * ARGUMENTS: [CONTROLLER ID, DOUBLE POSITION (mm)]
 *
 * RETURNS: NONE
 *
 * DESCRIPTION: Set the target position of the stage
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
                "2 arguments required.");
    }
    if (nlhs > 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "Stage ID should be an integer");
    }

    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setTemp:invalidArg",
                "position should be a double");
    }
    
    
    /* get the input arguments of position and controller ID */
    int controllerID = (int) mxGetScalar(prhs[0]);
    double pos  = (double) mxGetScalar(prhs[1]); // move to this position
    
    /* move! */

    char* szAxes = "1";
    BOOL fIfError = PI_MOV(controllerID,szAxes,&pos); // NULL since we only have one axis per controller
    
    // std::printf("\nOK? %i\n",fIfError);
    
    return;
    
}