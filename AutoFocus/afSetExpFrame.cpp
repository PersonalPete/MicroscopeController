/* afInitialiseCamera
 *
 *  ARGS    INT hCam, double frameRate, double exposure
 * 
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
    if (nrhs != 3) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No Input arguments accepted.");
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
                "Frame rate is a double (in Hz)");
    }
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Exposure rate is a double (in ms)");
    }
    
    int hCam = (int) mxGetScalar(prhs[0]);
    double frameRate = (double) mxGetScalar(prhs[1]);
    double expTime = (double) mxGetScalar(prhs[1]);
    
    // FRAME RATE
    double actualFrameRate;
    
    int rv = is_SetFrameRate(hCam, frameRate, &actualFrameRate);
      
    // EXPOSURE TIME
    rv = is_Exposure(hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &expTime, 8);
    
    return;
    
}