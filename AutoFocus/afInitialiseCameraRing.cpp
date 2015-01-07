/* afInitialiseCameraRing
 *
 *  RETURNS INT hCam, INT mId, INT mPtr 
 *          handle to camera, memory ID and pointers to memory of ring buffer
 *
 *  ARGS    NONE
 *
 *  Open connection to THORLABS DCC1545M-GL and allocates memory for a ring
 *  buffer of images
 */

#include "mex.h"
#include "matrix.h"
#include "afconstants.h"

#include <iostream>
#include "uc480.h"

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
    if (nlhs > 3) {
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
    /* However, we still need to allocate all the memory for the full image
     * even when we subsample it. When reading the image data we take this into account
     */ 
    rv = is_SetSubSampling(hCam, IS_SUBSAMPLING_4X_HORIZONTAL | IS_SUBSAMPLING_4X_VERTICAL);
    
    
    // ALLOCATE MEMORY
    int bitDepth = 8;
    char* pcImgMem [N_FRAMES]; // pointers to memory for each frame
    int id [N_FRAMES]; // ID of memory for each frame
    
    UINT64_T pcImgMemInt [N_FRAMES]; // integer representations of frame pointers
    UINT64_T id64 [N_FRAMES]; // 64-bit representation of frame pointers
    
    for (int ii = 0; ii < N_FRAMES; ii++) {
        // allocate the memory and store the addresses and ID in the arrays
        rv = is_AllocImageMem(hCam, H_PIX, V_PIX, bitDepth, &pcImgMem[ii], &id[ii]);
        rv = is_AddToSequence(hCam, pcImgMem[ii], id[ii]);
        // cast and store as types we can return to MATLAB
        pcImgMemInt[ii] = (UINT64_T) pcImgMem[ii];
        id64[ii] = (UINT64_T) id[ii];        
    }
    // SET MEMORY - don't need to do this for ring buffering
    // rv = is_SetImageMem(hCam, pcImgMem[0], id[0]);
    
    // WORK OUT THE LINE PITCH
    int linePitch;
    rv = is_GetImageMemPitch(hCam, &linePitch);
    std::printf("\nLine Pitch = %i\n",linePitch);
    
    // START CAPTURING
    rv = is_CaptureVideo(hCam, IS_DONT_WAIT);
    
    // RETURN CAMERA HANDLE
    UINT8_T hCam8 = (UINT8_T) hCam;
    
    mwSignedIndex scalarDims[2] = {1,1}; // elements in matrix
    
    plhs[0] = mxCreateNumericArray(1, scalarDims, mxUINT8_CLASS, mxREAL);
    double * hCamPtr = mxGetPr(plhs[0]);
    
    memcpy(hCamPtr, &hCam8, sizeof(hCam8));
    
    // RETURN MEMORY ID    
    mwSignedIndex vectorDims[2] = {N_FRAMES,1}; // frames in memory
    
    plhs[1] = mxCreateNumericArray(1, vectorDims, mxUINT64_CLASS, mxREAL);
    double * mIdPtr = mxGetPr(plhs[1]);
    
    memcpy(mIdPtr, id64, sizeof(UINT64_T)*N_FRAMES);
    
    // RETURN MEMORY PTRs
    plhs[2] = mxCreateNumericArray(1, vectorDims, mxUINT64_CLASS, mxREAL);
    double * mPtrPtr = mxGetPr(plhs[2]);
    memcpy(mPtrPtr, pcImgMemInt, sizeof(UINT64_T)*N_FRAMES);
    
    return;
    
}