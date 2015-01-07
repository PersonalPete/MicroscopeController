/* afCentroidImages.cpp
 *
 *  RETURNS double imageCentroid
 *
 *  ARGS    INT hCam, INT mPtr,
 *          INT roiHMin, INT roiHMax, 
 *          INT roiVMin, INT roiVMax,
 *          INT nFrames < 300, INT H or V (H = 1)
 *
 * Computes the centroid within the ROI of the last nFrames images acquired
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
    if ((nrhs != 7) & (nrhs!=8)) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidNumInputs",
                "Seven or eight input arguments required (camH, mId, mPtr).");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:maxlhs",
                "Too many output arguments.");
    }    
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "Camera handle is an integer");
    }
    
    if (!isFramesArray(prhs[1]) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "Memory Ptr is an array of length equal to the number of frames");
    }
    
    if ((!isScalarArray(prhs[2]) | (!isScalarArray(prhs[3])) |
            (!isScalarArray(prhs[4])) | (!isScalarArray(prhs[5]))){
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "Roi defined by 4 scalars");
    }
    
    if (!isScalarArray(prhs[6]){
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "NFrames is an integer");
    }
    
    if ((nrhs == 8) & (!isScalarArray(prhs[7]))) {
        mexErrMsgIdAndTxt( "MScope:afGetLastImage:invalidArg",
                "Horizontal = 1 (default)");
    }
    
    // EXTRACT PARAMETERS
    int hCam = (int) mxGetScalar(prhs[0]);   
    
    // LOOP OVER FRAMES
    
    // LOOP OVER ROWS
    
    // LOOP OVER COLUMNS
    
    // COMPUTE THE CENTROID

    // RETURN THE ANSWER TO MATLAB
    mwSignedIndex imageDims[2] = {H_PIX,V_PIX}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, imageDims, mxUINT8_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[0]);
    
    rv = is_CopyImageMem(hCam, (char*) pcImgMem, id, (char*) imgPtr);
    
    return;
    
}