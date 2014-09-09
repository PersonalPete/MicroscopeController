/* setupAndAcqSingle.cpp
 * 
 * ARGUMENTS: NONE
 * 
 * RETURNS: Camera image (of camera status request)
 * 
 * DESCRIPTION: Takes a single acquistion and returns it as an array of 
 *              16-bit integers
 * 
 */

/* header files to use */        
#include "mex.h" // required for mex files
#include <iostream> // for cout
#include "atmcd32d.h" // Andor functions


// The entry point for mex
void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "One input argument required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    

    int returnInt;
    
    // What shift speeds does the camera recommend?
    int vsIndex;
    float vsSpeed;
    
    returnInt = GetFastestRecommendedVSSpeed(&vsIndex,&vsSpeed);
    std::printf("\nVS: %i: %.2f us\n",vsIndex,vsSpeed);
    
    /* Shutter parameters */
    int typ = 0; // output TTL low to open external shutter (not important)
    int mode = 2; // Fully auto (0), permanently open (1), permanently closed (2)
    
    int closingTime = 0, openingTime = 0; // I'm not sure what to put here
    
    SetShutter(typ, mode, closingTime, openingTime); // make sure the shutter is closed 
    
    /* Camera settings */    
   
    SetADChannel(0);
    SetOutputAmplifier(0);
    SetPreAmpGain(0);
    SetEMCCDGain(0); // no EM gain
    SetHSSpeed(0,0); // type 0 (EM) shift speed 0 (10 MHz)
    returnInt = SetVSSpeed(3); // recommended by the camera
    
    
    
    SetBaselineClamp(1);
    
    /* Acquisition settings */
    
    int readMode = 4; // image mode
    int acqMode = 3; // single scan (1), kinetics (3)?
    
    SetReadMode(readMode);
    SetAcquisitionMode(acqMode);
    

    
    
    /* Trigger mode and frame transfer mode*/
    int triggerMode = 0; // (0) internal, (1) external
    
    returnInt = SetTriggerMode(triggerMode); 
    if (returnInt == DRV_SUCCESS) {
        std::printf("\nTriggering set\n");
    }
    
    if (triggerMode == 1) {
        std::printf("\nExternal\n");
        SetFastExtTrigger(1); // Fast external triggering disabled (0)
                              // System waits for keep clean to finish
                              // before triggering allowed
    }
    
    returnInt = SetFrameTransferMode(1); // Off (0) or On (1)
    if (returnInt == DRV_SUCCESS) {
        std::printf("\nFrame transfer mode active\n");
    }
    
    /* Timings */
    
    float exposure = 0.068; // exposure time in seconds
    float kineticCycleTime = 0.0; // repetitition time in seconds
    float accumulationTime = 0.0;
    int kineticSeriesNumber = 100;
    
    SetKineticCycleTime(kineticCycleTime);
    SetExposureTime(exposure);
    SetAccumulationCycleTime(accumulationTime);
    
    SetNumberKinetics(kineticSeriesNumber);
    
    SetNumberAccumulations(0);
    
    /* Set the image area and binning */
    SetImage(1,1,1,512,1,512); // Acquire the whole image with no binning
    
    /* Acquisition Timings */
    
    float exposureTrue, accumulateTrue, kineticTrue;
    returnInt = GetAcquisitionTimings(&exposureTrue,&accumulateTrue,&kineticTrue);
    std::printf("\nExposure: %.3f s\nAccumulation cycle: %.3f s\nKinetic cycle: %.3f\n",exposureTrue,accumulateTrue,kineticTrue);
    
    
    // SetSpool(1,5,"/SpoolTarget/External_trigger",10);
    
    /* Check the camera is idle, if not then cancel the acquisition */
    int status = 0;
    GetStatus(&status);
    if (status != DRV_IDLE) {
        return;
    }
    
    std::printf("\nStatus: Idle\nAcquiring...\n");
    
    /* Start Acquisition */
    // StartAcquisition();
    
    /* Current camera status */
    
    
    return;
}
