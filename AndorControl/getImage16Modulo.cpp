/* getImage16Modulo.cpp
 *
 * WARNING: THIS DOESN'T SEEM TO WORK DURING SPOOLING, SO WE HAVE TO THINK
 * OF ANOTHER WAY TO IMPLEMENT ANTI-ALIASING DISPLAY DURING ACQUISITION
 * 
 * ARGUMENTS: [INT XPIX, INT YPIX, INT CYCLE_FRAME, INT CYCLE_LENGTH]
 * 
 * RETURNS: [STATUS, CAMERA_IMAGE, FRAME_NUMBER_RETURNED]
 * 
 * DESCRIPTION: Gets the most recent image, so we can display it and make 
 *              sure that we don't skip a channel in ALEX (otherwise we 
 *              couldn't see its focus). We input the number of x and y
 *              pixels input so the correct amount of memory can be
 *              allocated.
 *
 *              The CYCLE_LENGTH is 3 for three colour ALEX, and 2 for two 
 *              colour ALEX. If we want the same illumination as the first
 *              frame we set CYCLE_MODULO to 1, second to 2 etc...
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
    if (nrhs != 4) {
        mexErrMsgIdAndTxt( "Mscope:getImage16Modulo:invalidNumInputs",
                "Three input arguments required.");
    }
    if (nlhs > 3) {
        mexErrMsgIdAndTxt( "Mscope:getImage16Modulo:maxlhs",
                "Too many output arguments.");
    } 
    
    unsigned long xPix, yPix;
    long cycleFrame, cycleLength;
    /* validate arguments etc... */
    
    if (!isScalarArray(prhs[0])) {
        mexErrMsgIdAndTxt("Mscope:getImage16Modulo:invalidArg","Integer number of pixels");
    }
    xPix = (unsigned long) mxGetScalar(prhs[0]);
    
    
    if (!isScalarArray(prhs[1])) {
        mexErrMsgIdAndTxt("Mscope:getImage16Modulo:invalidArg","Integer number of pixels");
    }
    yPix = (unsigned long) mxGetScalar(prhs[1]);
    
    if (!isScalarArray(prhs[2])) {
        mexErrMsgIdAndTxt("Mscope:getImage16Modulo:invalidArg","Integer frame in cycle");
    }
    cycleFrame = (long) mxGetScalar(prhs[2]);
    
    if (!isScalarArray(prhs[3])) {
        mexErrMsgIdAndTxt("Mscope:getImage16Modulo:invalidArg","Integer cycle length");
    }
    cycleLength = (long) mxGetScalar(prhs[3]);
    
    if (cycleFrame > cycleLength) {
        mexErrMsgIdAndTxt("Mscope:getImage16Modulo:invalidArg","Cycle length must be greater than cycle frame");
    }
    
    /* construct the array we will return the image in */
    
    unsigned long numPix = xPix*yPix; // total number of pixels
    
    WORD * imageArray = new WORD[numPix];
    
    
    /* call the Andor SDK functions */ 
    long first, last;
    unsigned int ac = GetNumberAvailableImages(&first,&last);    
    INT32_T last32 = (INT32_T) last;
    
    
    
    // work out which image we need to retreive
    int latestCycleStart = last - last%cycleLength;
    // so many frames after the most recent cycle start
    int frame = latestCycleStart + cycleFrame - 2*cycleLength;
    
//     if (frame > last) {
//         frame = frame - cycleLength;
//     }
    if (frame < 1) { 
        frame = 1; // give the first frame if we are just starting acquisition
    }
    
    std::printf("\nGetNumAvailIm Code: %i, First: %i, Last: %i, Frame: %i\n",ac,first,last,frame);
    
    INT32_T frame32 = (INT32_T) frame;
    
    // IMPORTANT ONE FOR ACTUAL IMAGE RETRIEVAL        
    UINT32_T returnInt = (UINT32_T) GetImages16(frame,frame,imageArray,numPix,&first,&last);
    
    std::printf("\nValid First: %i, Valid Last: %i, Frame: %i\n",first,last,frame);
    
    /* Copy the memory into MATLAB form */
    
    mwSignedIndex returnIntDims[2] = {1,1}; // how many elements does the output code need
    
    plhs[0] = mxCreateNumericArray(1, returnIntDims, mxUINT32_CLASS, mxREAL);
    double * codePtr = mxGetPr(plhs[0]);
    memcpy(codePtr, &returnInt, sizeof(returnInt));
    
    mwSignedIndex imageDims[2] = {xPix,yPix}; // elements in image
    
    plhs[1] = mxCreateNumericArray(2, imageDims, mxUINT16_CLASS, mxREAL);
    double * imgPtr = mxGetPr(plhs[1]);
    memcpy(imgPtr, imageArray, numPix*sizeof(imageArray[0]));
    
        
    plhs[2] = mxCreateNumericArray(2, returnIntDims, mxINT32_CLASS, mxREAL);
    double * latestImNoPtr = mxGetPr(plhs[2]);
    memcpy(latestImNoPtr, &frame32, sizeof(frame32));
    
    /* clear up the array we used */
    
    delete imageArray;
    
    return;
}
