/* getLastFrame32.cpp
 * 
 * ARGUMENTS: INT XPIX, INT YPIX
 * 
 * RETURNS: [STATUS, CAMERA IMAGE, NUMBER_IN_SERIES]
 * 
 * DESCRIPTION: Gets the most recent image so we can display it
 *              We input the number of x and y pixels input
 * 
 */

/* header files to use */        
#include "mex.h" // required for mex files
#include <iostream> // for cout
#include "atmcd32d.h" // Andor functions

// convenience function
bool isScalarArray(const mxArray* pArg) {
    return (mxIsNumeric(pArg) && mxGetN(pArg) == 1 && mxGetM(pArg) == 1);
}

// The entry point for mex
void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "Mscope:getLastFrame16:invalidNumInputs",
                "Two input argument required.");
    }
    if (nlhs > 3) {
        mexErrMsgIdAndTxt( "Mscope:getLastFrame16:maxlhs",
                "Too many output arguments.");
    } 
    
    int xPix, yPix;
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt("Mscope:setTimings:invalidArg","2-3 floating point scalars required");
    }
    xPix = (unsigned long) mxGetScalar(prhs[0]);
    
    /* validate exposure time etc... */
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt("Mscope:setTimings:invalidArg","2-3 floating point scalars required");
    }
    yPix = (unsigned long) mxGetScalar(prhs[1]);
    
    /* construct the array we will return the image in */
    
    unsigned long numPix = xPix*yPix; // total number of pixels
    
    at_32 * imageArray = new at_32 [numPix];
    
    
    /* call the Andor SDK functions */ 
    long first, last;
    GetNumberNewImages(&first,&last);    
    INT32_T last32 = (INT32_T) last;
    
    // long validFirst, validLast; // Comment this out if not getting EXACT frame
    
    // IMPORTANT ONE FOR ACTUAL IMAGE RETRIEVAL        
     UINT32_T returnInt = (UINT32_T) GetMostRecentImage(imageArray,numPix);
    // UINT32_T returnInt = (UINT32_T) GetImages(last,last,imageArray,numPix,&validFirst,&validLast);

    
    /* Copy the memory into MATLAB form */
    
    mwSignedIndex returnIntDims[2] = {1,1}; // how many elements does the output code need
    
    plhs[0] = mxCreateNumericArray(1, returnIntDims, mxUINT32_CLASS, mxREAL);
    double * codePtr = mxGetPr(plhs[0]);
    memcpy(codePtr, &returnInt, sizeof(returnInt));
    
    mwSignedIndex imageDims[2] = {xPix,yPix}; // elements in image
    
    plhs[1] = mxCreateNumericArray(2, imageDims, mxUINT32_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[1]);
    memcpy(imgPtr, imageArray, numPix*sizeof(imageArray[0]));
    
        
    plhs[2] = mxCreateNumericArray(2, returnIntDims, mxINT32_CLASS, mxREAL);
    double * latestImNoPtr = mxGetPr(plhs[2]);
    memcpy(latestImNoPtr, &last32, sizeof(last32));
    
    /* clear up the array we used */
    
    delete imageArray;
    
    return;
}
