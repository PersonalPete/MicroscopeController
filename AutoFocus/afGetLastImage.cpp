/* afGetLast Image
 *
 *  RETURNS double imageData
 *
 *  ARGS    INT hCam, INT memID, INT mPtr
 *
 * Open connection to THORLABS DCC1545M-GL
 */

#include "mex.h"
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
    if ((nrhs != 2) & (nrhs!=3)) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Two or three input arguments required (camH, mId, mPtr).");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Camera handle is an integer");
    }
    
    if ((!isScalarArray(prhs[1])) & (!isFramesArray(prhs[1]))) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                "Memory ID is an integer or a array of length equal to the number of frames");
    }
    
    if ((nrhs == 3) & (!isFramesArray(prhs[2]))) {
        mexErrMsgIdAndTxt( "MScope:afGetLastImage:invalidArg",
                "Memory Ptr is an array");
    }
    
    int hCam = (int) mxGetScalar(prhs[0]);
    int id;
    
    // GET THE MEMORY POINTER
    VOID *pcImgMem;
    int rv = is_GetImageMem(hCam, &pcImgMem);
    UINT64_T pcImgMemInt = (UINT64_T) pcImgMem;
            
    if (nrhs != 3) {
        id = (int) mxGetScalar(prhs[1]);
    } else {
        UINT64_T* mId = (UINT64_T*) mxGetData(prhs[1]); // extract the args
        UINT64_T* mPtr = (UINT64_T*) mxGetData(prhs[2]);
        for (int ii = 0; ii < N_FRAMES; ii++) {
            // loop over allocated frame pointers, if it matches then use the corresponding ID
            if (mPtr[ii] == pcImgMemInt) {
                id = (int) mId[ii];
                break;
            }
        }
    }

    // COPY IMAGE INTO MATLAB
    mwSignedIndex imageDims[2] = {H_PIX,V_PIX}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, imageDims, mxUINT8_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[0]);
    
    rv = is_CopyImageMem(hCam, (char*) pcImgMem, id, (char*) imgPtr);
    
    return;
    
}