/* initialSettings.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [RESPONSE CODE]
 *
 * DESCRIPTION: Defines the default settings for the camera. In short:
 *              - We use AD channel 0
 *              - EM Amplifier is used with 0 gain
 *              - Image mode, with kinetics and frame transfer on
 *              - External triggering with 50 ms exposures and the kinetic
 *                cycle time indicating the fastest possible repeat rate
 *              - No spooling
 *              - Temperature set to -60 C and cooler on
 *              - Full frame mode
 */

/* header files to use */
#include "mex.h" // required for mex files
#include <iostream> // for cout
#include "atmcd32d.h" // Andor functions

// define the default settings for our camera

#define DFT_CHANNEL 0
#define DFT_AMP 0 
#define DFT_PREA_GAIN 0
#define DFT_EMGAIN_MODE 1
#define DFT_EMCCD_GAIN 0
#define DFT_HSS 0 
#define DFT_VSS 3 
#define DFT_BASE_CLAMP 1
#define DFT_READ_MODE 4 // is image of course
#define DFT_ACQ_MODE 3 // 5 is run-till-abort, which is our video mode
//for internal triggering this must be 3, for external 3 or 4 for fast kinetics

/* Fast kinetics won't work with a cropped sensor */

#define DFT_FRAME_TRANS_MODE 1 

#define DFT_TRIGGER_MODE 1 // 1 is external 
#define DFT_TRIGGER_FAST 1  

#define DFT_EXP 0.05f   
#define DFT_KIN 0.05f
#define DFT_ACC 0.05f
#define DFT_KIN_NUM 100

#define DFT_SPOOL 1 

#define DFT_TEMP -60

#define NUM_SETTINGS 22

// The entry point for mex
void
        mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No input arguments");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    /* ARRAY FOR STATUS CODES */
    
    unsigned int ac [ NUM_SETTINGS ]; 
    
    /* INITIALISE THE CAMERA */
    
    ac[0] = SetTemperature(DFT_TEMP); // set the temperature
    ac[1] = CoolerON();
    
    ac[2] = SetADChannel(DFT_CHANNEL);
    ac[3] = SetOutputAmplifier(DFT_AMP);
    ac[4] = SetPreAmpGain(DFT_PREA_GAIN);
    ac[5] = SetEMGainMode(DFT_EMGAIN_MODE);
    ac[6] = SetEMCCDGain(DFT_EMCCD_GAIN); // no EM gain
    ac[7] = SetHSSpeed(DFT_AMP,DFT_HSS); // type 0 (EM) shift speed 0 (10 MHz)
    ac[8] = SetVSSpeed(DFT_VSS); // 3 corresponds to 1.7 us (Camera recommends 4)
    ac[9] = SetBaselineClamp(DFT_BASE_CLAMP);
    

    ac[10] = SetAcquisitionMode(DFT_ACQ_MODE); 
    ac[11] = SetReadMode(DFT_READ_MODE);
    ac[12] = SetFrameTransferMode(DFT_FRAME_TRANS_MODE);
    
    ac[13] = SetTriggerMode(DFT_TRIGGER_MODE); 
    ac[14] = SetFastExtTrigger(DFT_TRIGGER_FAST);
           
    ac[15] = SetKineticCycleTime(DFT_KIN);
    ac[16] = SetAccumulationCycleTime(DFT_ACC);
    ac[17] = SetExposureTime(DFT_EXP); 
    
    ac[18] = SetNumberKinetics(DFT_KIN_NUM);
    ac[19] = SetNumberAccumulations(1); // don't accumulate
    
    ac[20] = SetSpool(DFT_SPOOL,5,"SpoolTarget/defaultSpoolName",10);
    
    int xhpixels, yvpixels;
    ac[21] = GetDetector(&xhpixels,&yvpixels);
    ac[22] = SetImage(1,1,1,xhpixels,1,yvpixels); // Acquire the whole image with no binning
    
    /*CHECK THEY WENT OK */
    
    UINT32_T andorCode32 = DRV_SUCCESS;
    
    for (int ii = 0; ii < NUM_SETTINGS ; ii++) {
        if (ac[ii] != DRV_SUCCESS) {
            std::printf("\nError initialising Camera\n%i returned code: %i\n",ii,ac[ii]);
            andorCode32 = 1;
        }
    }
    
    /* RETURNING THE STATUS CODE */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of our status code to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));

    
    
    return;
}
