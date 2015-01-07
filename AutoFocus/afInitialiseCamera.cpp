/* afInitialiseCamera
 *
 *  RETURNS INT hCam, INT mId 
 *          handle to camera, memory ID
 *
 *  ARGS    NONE
 *
 *  Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
#include <iostream>
#include "uc480.h"

#include "afconstants.h"

#define DFT_EXP_TIME 10 // milliseconds per frame
#define DFT_FRAME_RATE 10 // frames per second
#define DFT_PX_CLOCK 35 // MHz (max 43)

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    // CHECK ARGS
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No Input arguments accepted.");
    }
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    HCAM hCam = 0;
    
    // CONNECT TO CAMERA AND GET THE HANDLE
    int rv = is_InitCamera(&hCam, NULL);
    
    // SET THE PIXEL CLOCK
    UINT pixelClock = DFT_PX_CLOCK;
    rv = is_PixelClock(hCam, IS_PIXELCLOCK_CMD_SET, (void*) &pixelClock, sizeof(pixelClock));
    
    // FRAME RATE
    double frameRate = DFT_FRAME_RATE;
    double actualFrameRate;
    
    rv = is_SetFrameRate(hCam, frameRate, &actualFrameRate);
      
    // EXPOSURE TIME
    double expTime = 10; // exposure time in ms
    rv = is_Exposure(hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &expTime, 8);
    
    // TRIGGER MODE
    rv = is_SetExternalTrigger(hCam, IS_SET_TRIGGER_SOFTWARE);
    
    // COLOR MODE
    rv = is_SetColorMode(hCam, IS_CM_MONO8); // 8-bit monochrome
    
     // SET THE SUBSAMPLING
    rv = is_SetSubSampling(hCam, IS_SUBSAMPLING_4X_VERTICAL | IS_SUBSAMPLING_4X_HORIZONTAL);
    
    // ALLOCATE MEMORY
    int bitDepth = 8;
    char* pcImgMem;
    int id;
    rv = is_AllocImageMem(hCam, H_PIX, V_PIX, bitDepth, &pcImgMem, &id);
    
    // CALCULATE THE LINE PITCH
    int linePitch;
    rv = is_GetImageMemPitch(hCam, &linePitch);
    std::printf("\nLine Pitch = %i\n",linePitch);
    
    // SET MEMORY
    rv = is_SetImageMem(hCam, pcImgMem, id);
    
    // START CAPTURING
    rv = is_CaptureVideo(hCam, IS_DONT_WAIT);
    
    // RETURN CAMERA HANDLE
    UINT8_T hCam8 = (UINT8_T) hCam;
    
    mwSignedIndex scalarDims[2] = {1,1}; // elements in image
    
    plhs[0] = mxCreateNumericArray(1, scalarDims, mxUINT8_CLASS, mxREAL);
    double * hCamPtr = mxGetPr(plhs[0]);
    
    memcpy(hCamPtr, &hCam8, sizeof(hCam8));
    
    // RETURN MEMORY ID
    UINT32_T id32 = (UINT32_T) id;
    
    plhs[1] = mxCreateNumericArray(1, scalarDims, mxUINT32_CLASS, mxREAL);
    double * mIdPtr = mxGetPr(plhs[1]);
    
    memcpy(mIdPtr, &id32, sizeof(id32));
    
    return;
    
}