/* afInitialiseCamera
 *
 *  RETURNS DOUBLE exposureSet, DOUBLE framerateSet
 *  ARGS    INT hCam, DOUBLE exposure, DOUBLE framerate
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
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Camera handle is an integer");
    }
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Exposure is a double (in Hz)");
    }
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Frame rate rate is a double (in ms)");
    }
    
    int hCam = (int) mxGetScalar(prhs[0]);
    double frameRate = (double) mxGetScalar(prhs[2]);
    double expTime = (double) mxGetScalar(prhs[1]);
    
    // FRAME RATE
    double actualFrameRate;    
    int rv = is_SetFrameRate(hCam, frameRate, &actualFrameRate);
      
    // EXPOSURE TIME
    rv = is_Exposure(hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &expTime, 8);
    
    double actualExposure;
    rv = is_Exposure(hCam, IS_EXPOSURE_CMD_GET_EXPOSURE, &actualExposure, 8);
    
    // RETURN THE ACTUAL VALUES
    mwSignedIndex scalarDims[2] = {1,1}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, scalarDims, mxDOUBLE_CLASS, mxREAL);
    double * exposurePtr = mxGetPr(plhs[0]);
    memcpy(exposurePtr, &actualExposure, sizeof(actualExposure));
    
    plhs[1] = mxCreateNumericArray(2, scalarDims, mxDOUBLE_CLASS, mxREAL);
    double * frameratePtr = mxGetPr(plhs[1]);
    memcpy(frameratePtr, &actualFrameRate, sizeof(actualFrameRate));
    
    return;
    
}