/* afCloseCamera
 *  RETURNS NONE
 *
 *  ARGS    INT hCam, INT mId, INT mPtr
 *
 * Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
#include "matrix.h"
#include <iostream>

#include "uc480.h"
#include "afconstants.h"

bool isScalarArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == 1);
}

bool isFramesArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == N_FRAMES);
}


void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    // CHECK ARGS
    if (nrhs != 3) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Three Input arguments required (camH, mId, mPtr).");
    }
    if (nlhs > 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Camera handle is an integer");
    }
    
    if (!isFramesArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Memory ID is an array");
    }
    
    if (!isFramesArray(prhs[2])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Memory Ptr is an array");
    }
    
    int hCam = (int) mxGetScalar(prhs[0]);
    UINT64_T* mId = (UINT64_T*) mxGetData(prhs[1]);
    UINT64_T* mPtr = (UINT64_T*) mxGetData(prhs[2]);
    
    // FREE MEMORY AND CLOSE CONNECTION
    int rv;
    for (int ii = 0; ii < N_FRAMES; ii++) {
        rv = is_FreeImageMem(hCam, (char*) mPtr[ii], (int) mId[ii]);
    }
    rv = is_ExitCamera(hCam);
    
    return;
    
}