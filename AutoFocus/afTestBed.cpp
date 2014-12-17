/* BOOL AFTESTBED
 *
 * Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
#include <iostream>
#include "uc480.h"

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    // CHECK ARGS
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No Input arguments accepted.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    int rv, numCams;
    
    // QUERY SOME INFORMATION ABOUT THE SYSTEM
    
    rv = is_GetNumberOfCameras(&numCams);
    
    UC480_CAMERA_LIST* pucl;
    pucl = (UC480_CAMERA_LIST*) new BYTE [sizeof(DWORD) + numCams*sizeof(UC480_CAMERA_INFO)];
    (*pucl).dwCount = numCams;
    
    rv = is_GetCameraList(pucl);
    
    delete [] pucl;
    
    // CONNECT TO A CAMERA
    
    HCAM hCam = 0;
    
    rv = is_InitCamera(&hCam, NULL);
    
    std::printf("\nhCam = %i\n",hCam);
    
    // FRAME RATE
    double frameRate = 10;
    double actualFrameRate;
    
    rv = is_SetFrameRate(hCam, frameRate, &actualFrameRate);
      
    // EXPOSURE TIME
    double expTime = 10; // exposure time in ms
    rv = is_Exposure(hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &expTime, 8);
    
    // TRIGGER MODE
    rv = is_SetExternalTrigger(hCam, IS_SET_TRIGGER_SOFTWARE);
    
    // COLOR MODE
    rv = is_SetColorMode(hCam, IS_CM_MONO8); // 8-bit monochrome
    
    // ALLOCATE MEMORY
    int hPix = 1280, vPix = 1024, bitDepth = 8;
    char* pcImgMem;
    int id;
    rv = is_AllocImageMem(hCam, hPix, vPix, bitDepth, &pcImgMem, &id);
    
    // SET MEMORY
    
    rv = is_SetImageMem(hCam, pcImgMem, id);    
    
    
    // CAPTURE
    rv = is_CaptureVideo(hCam, IS_DONT_WAIT);
    
    // Sleep
    Sleep(1000);
    
    // COPY IMAGE INTO MATLAB
    mwSignedIndex imageDims[2] = {hPix,vPix}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, imageDims, mxUINT8_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[0]);
    
    // rv = is_CopyImageMem(hCam, pcImgMem, id, (char*) imgPtr);
    
    memcpy(imgPtr, pcImgMem, hPix*vPix*sizeof(pcImgMem[0]));
   
    
    // FREE MEMORY AND CLOSE CONNECTION
    rv = is_FreeImageMem(hCam, pcImgMem, id);
    rv = is_ExitCamera(hCam);
    
    return;
    
}