/* afGetLast Image
 *
 *  RETURNS double imageData
 *
 *  ARGS    INT hCam, INT memID
 *
 * Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
#include <iostream>
#include "uc480.h"

#define H_PIX 1280
#define V_PIX 1024

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
    if (nlhs > 1) {
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
    
    // GET THE MEMORY POINTER
    VOID *pcImgMem;
    int rv = is_GetImageMem(hCam, &pcImgMem);

    // COPY IMAGE INTO MATLAB
    mwSignedIndex imageDims[2] = {H_PIX,V_PIX}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, imageDims, mxUINT8_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[0]);
    
    rv = is_CopyImageMem(hCam, (char*) pcImgMem, id, (char*) imgPtr);
    
    return;
    
}