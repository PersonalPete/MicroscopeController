/* afCloseCamera
 *  RETURNS NONE
 *
 *  ARGS    INT hCam
 *
 * Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
#include <iostream>
#include "uc480.h"

bool isScalarArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == 1);
}


void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    // CHECK ARGS
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Two Input arguments required (camH, mId).");
    }
    if (nlhs > 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Camera handle is an integer");
    }
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Memory ID is an integer");
    }
    
    int hCam = (int) mxGetScalar(prhs[0]);
    int id = (int) mxGetScalar(prhs[1]);
    
    // FREE MEMORY AND CLOSE CONNECTION
    VOID *pcImgMem;
    int rv = is_GetImageMem(hCam, &pcImgMem);
    
    rv = is_FreeImageMem(hCam, (char*) pcImgMem, id);
    rv = is_ExitCamera(hCam);
    
    return;
    
}