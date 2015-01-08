/* afCentroidImages.cpp
 *
 *  RETURNS double imageCentroid
 *
 *  ARGS    INT hCam, INT mPtr,
 *          INT roiHMin, INT roiHMax, 
 *          INT roiVMin, INT roiVMax,
 *          INT nFrames < 1000
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
    if (nrhs != 7) {
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
    
    if (!isFramesArray(prhs[1])) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "Memory Ptr is an array of length equal to the number of frames");
    }
    
    if ((!isScalarArray(prhs[2])) | (!isScalarArray(prhs[3])) |
            (!isScalarArray(prhs[4])) | (!isScalarArray(prhs[5]))){
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "Roi defined by 4 scalars");
    }
    
    if (!isScalarArray(prhs[6])) {
        mexErrMsgIdAndTxt( "Mscope:afGetLastImage:invalidArg",
                "NFrames is an integer");
    }
    
    // EXTRACT PARAMETERS
    int hCam = (int) mxGetScalar(prhs[0]);   
    // Pointer to the pointers to the 8-bit camera data
    UINT8_T** mPtrsPtr = (UINT8_T**) mxGetData(prhs[1]);
    // ROI to centroid within
    int hRoiMin = (int) mxGetScalar(prhs[2]);
    int hRoiMax = (int) mxGetScalar(prhs[3]);
    int vRoiMin = (int) mxGetScalar(prhs[4]);
    int vRoiMax = (int) mxGetScalar(prhs[5]);
    // Number of recent frames to consider
    int nFrames = (int) mxGetScalar(prhs[6]);
    
    //std::printf("\nInput Parameters: ROI %i %i %i %i; Frames %i\n",hRoiMin, hRoiMax, vRoiMin, vRoiMax, nFrames);
    
    // WORK OUT WHICH MEMORY IN SEQUENCE IS MOST RECENT
    int mostRecentBuffer;
    
    VOID *pcImgMem;
    is_GetImageMem(hCam, &pcImgMem);
    UINT8_T* pcImgMemInt = (UINT8_T*) pcImgMem;
    
    for (int ii = 0; ii < N_FRAMES; ii++) {
        // loop over allocated frame pointers, if it matches then use the corresponding ID
        if (mPtrsPtr[ii] == pcImgMemInt) {
            mostRecentBuffer = ii;
            break;
        }
    }
    
    //std::printf("\nMost Recent Buffer: %i\n",mostRecentBuffer);
    
    // LOOP OVER FRAMES
    int actualFrame;
    
    double weightedMeanPosSum = 0;
    double normalisationSum = 0;
    
    for (int frame = mostRecentBuffer - nFrames; frame < mostRecentBuffer; frame++) {
        // Calculate which frame buffer to use, putting negatives in range 
        // cyclically
        if (frame < 0) {
            actualFrame = frame + N_FRAMES;
        } else {
            actualFrame = frame;
        }
        //std::printf("\nLooking at buffer %i\n",actualFrame);
        // LOOP OVER ROWS
        for (int row = vRoiMin; row < vRoiMax; row++) {
            //std::printf("\nLooping over vertical row %i\n",row);
            // LOOP OVER COLUMNS
            for (int column = hRoiMin; column < hRoiMax; column++) {
                //std::printf("\nColumn %i; Value %u\n",column,mPtrsPtr[actualFrame][column + row*H_PIX]); 
                weightedMeanPosSum += (double) column * (double) mPtrsPtr[actualFrame][column + row*H_PIX];
                normalisationSum += (double) mPtrsPtr[actualFrame][column + row*H_PIX];
            }
        }
    }
    
    // COMPUTE THE CENTROID
    double centroidPos = weightedMeanPosSum/normalisationSum;
    //std::printf("\nCentroid: %.2f\n",centroidPos);
    
    // RETURN THE ANSWER TO MATLAB
    mwSignedIndex scalarDims[2] = {1,1}; // elements in image
    
    plhs[0] = mxCreateNumericArray(2, scalarDims, mxDOUBLE_CLASS, mxREAL);
    double * centroidPtr = mxGetPr(plhs[0]);
    memcpy(centroidPtr, &centroidPos, sizeof(centroidPos));
    
    
    return;
    
}