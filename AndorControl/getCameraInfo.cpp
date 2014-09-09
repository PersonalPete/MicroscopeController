/* getCameraInfo.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: STATUS CODE (of camera status request)
 *
 * DESCRIPTION: Prints information about the current state and properties
 *              of the connected camera to standard output.
 *
 *              Sets the cooler on and targets -80 C
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
    
    
    // Lets have a go at one of the Andor functions
    
    
    // the argument for Initialize is a pointer to a char array with the directory to find the
    // DETECTOR.INI file containing camera information - but we don't need this for an iXon3
    
    
    unsigned int returnInt, returnIntLast;
    
    /* Temperature */
    
    int coolerStatus;
    
    
    returnInt = IsCoolerOn(&coolerStatus);
    
    std::printf("\nCooler Status: %i\n",coolerStatus);
    
    int tecStatus;
    returnIntLast = GetTECStatus(&tecStatus);
    
    std::printf("TEC overheat: %i\n",tecStatus);
    
    int temp;
    
    int tempReturn = GetTemperature(&temp); // current temperature
    
    if (tempReturn == DRV_TEMP_STABILIZED) {
            std::printf("\n * Temperature stable *\n");
    }
    
    std::printf("Current temperature is %i C\n",temp);
    
    int minTemp, maxTemp;
    returnInt = GetTemperatureRange(&minTemp,&maxTemp);
    
    std::printf("Min: %i, Max: %i C\n",minTemp,maxTemp);
    
    
    /* Available pixels */
    int xpixels, ypixels;
    
    returnInt = GetDetector(&xpixels,&ypixels);
    
    std::printf("\nX: %i, Y: %i px\n",xpixels,ypixels);
    
    /* Shutter */
    int internalShutter;
    IsInternalMechanicalShutter(&internalShutter);
    std:printf("\nInternal shutter: %i\n",internalShutter);
    
    /* Analog-digital converter channels */
    int numberChan;
    returnInt = GetNumberADChannels(&numberChan);
    std::printf("\n%i AD Channel(s) available\n",numberChan);
    
    /* Pre-amp gains */
    int numberPAGains;
    returnInt = GetNumberPreAmpGains(&numberPAGains);
    std::printf("\n%i Pre-amp gains available\n",numberPAGains);
    
    /* Amplifier descriptions */
    int numberAmp;
    returnInt = GetNumberAmp(&numberAmp);
    std::printf("\n%i Amplifiers\n",numberAmp);
    
    int descLen = 21;
    
    char desc[21];
    for (int ampI = 0; ampI < numberAmp; ampI++) {
        returnInt = GetAmpDesc(ampI,desc,descLen);
        std::printf("%i : %s\n",ampI,desc);
    }
    
    /* Horizontal shift speeds */
    
    for (int amp = 0; amp < numberAmp; amp++) {
        std::printf("\nUsing amplifier %i:\n",amp);
        
        for (int channel = 0; channel < numberChan; channel++) {
            int numberHS;
            returnInt = GetNumberHSSpeeds(channel,amp,&numberHS); // 0 specifies we use the EM amplifier
            std::printf("\n%i HS speeds for AD Channel %i",numberHS,channel);
            float speedHS;
            for (int speedI = 0; speedI < numberHS; speedI++) {
                returnInt = GetHSSpeed(channel,amp,speedI,&speedHS); // EM multiplication (0)
                std::printf("\n%i : %.3f MHz, Pre-Amp Gains available: ",speedI,speedHS);
                for (int paGainI = 0; paGainI < numberPAGains; paGainI++) {
                    int pagAvailable;
                    returnInt = IsPreAmpGainAvailable(channel,amp,speedI,paGainI,&pagAvailable);
                    if (pagAvailable == 1) {
                        float paGain;
                        returnInt = GetPreAmpGain(paGainI,&paGain);
                        std::printf("%.2f ",paGain);
                    }
                }
            }
            std::printf("\n");
        }
    }
    /* Pre-amp gain */
    
    /* Vertical Shift-speeds */
    int numberVS;
    returnInt = GetNumberVSSpeeds(&numberVS);
    std::printf("\n%i VS speeds\n",numberVS);
    
    float speedVS;
    for (int speedI = 0; speedI < numberVS; speedI++) {
        returnInt = GetVSSpeed(speedI,&speedVS);
        std::printf("%i : %.3f us\n",speedI,speedVS);
    }
    
    /* EM Gain */
    
    int gain;
    returnInt = GetEMCCDGain(&gain);
    std::printf("\nGain = %i\n",gain);
    
    SetEMGainMode(1);
    
    int low, high;
    returnInt = GetEMGainRange(&low,&high);
    std::printf("Min: %i, Max: %i",low,high);
    
    /* Acquisition Timings */
    
    float exposure, accumulate, kinetic;
    returnInt = GetAcquisitionTimings(&exposure,&accumulate,&kinetic);
    std::printf("\nExposure: %.3f s\nAccumulation cycle: %.3f s\nKinetic cycle: %.3fs\n",exposure,accumulate,kinetic);
    
    
    /* Current camera status */
    int status;
    returnInt = GetStatus(&status);
    
    switch (status) {
        case DRV_IDLE:
            std::printf("\nStatus: Idle\n");
            break;
        case DRV_TEMPCYCLE:
            std::printf("\nStatus: Executing temp cycle\n");
            break;
        case DRV_ACQUIRING:
            std::printf("\nStatus: Acquiring\n");
            break;
        case DRV_ACCUM_TIME_NOT_MET:
            std::printf("\nStatus: Unable to meet accumulate cycle time\n");
            break;
        case DRV_KINETIC_TIME_NOT_MET:
            std::printf("\nStatus: Unable to meet kinetic cycle time\n");
            break;
        case DRV_ERROR_ACK:
            std::printf("\nStatus: Unable to communicate with card\n");
            break;
        case DRV_ACQ_BUFFER:
            std::printf("\nStatus: Computer unable meet ISA slot read rate\n");
            break;
        case DRV_ACQ_DOWNFIFO_FULL:
            std::printf("\nStatus: Computer unable meet read rate - camera memory full\n");
            break;
        case DRV_SPOOLERROR:
            std::printf("\nStatus: Overflow of spool buffer\n");
            break;
    }
    
    
    
    UINT32_T statusFlag;
    
    if (returnIntLast == DRV_SUCCESS) {
        
        statusFlag = 1; // SUCCESS
    } else if (returnIntLast == DRV_NOT_SUPPORTED) {
        std::printf("Error: %u. Operation not supported\n",returnIntLast);
        statusFlag = 0; // FAILURE
    } else {
        std::printf("Error: %u. Please consult Andor manual.\nCheck camera and card\n",returnIntLast);
        statusFlag = 0;
    }
    
    /* RETURNING A STATUS CODE */
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * outDataPtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(outDataPtr, &statusFlag, sizeof(statusFlag));
    
    
    
    return;
}
