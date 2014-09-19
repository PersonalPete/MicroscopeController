/* connectSingleUSB.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: STATUS CODE
 *
 * DESCRIPTION: Call this function to begin communication with a PI stage
 *
 */


/* header files to use */
#include "mex.h" // required for mex files
#include <iostream> // for cout
#define __int64 INT64_T // since the PI files use a type we don't recognise

#include "PI_GCS2_DLL.h" // PI functions


void
        mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 0) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "No Input arguments accepted.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    /* allocate memory for the answer */
    int sizeBuffers = 100;
    char * szBuffer = new char [sizeBuffers + 1]; // 100 elements + terminator
    
    char* szFilter = "E-871"; // only return USB devices that start with...
    
    int numControllers = PI_EnumerateUSB(szBuffer,sizeBuffers,szFilter); // numControllers == -5 if buffer too small
    
    /* print the output */
    std::printf("\n%i USB objects\n",numControllers);
    for (int ii = 0; ii < sizeBuffers; ii ++) {
        std::printf("%c",szBuffer[ii]);
        if (szBuffer[ii] == '\0') {
            std::printf("\nEND\n");
            break;
        }
    }
    std::printf("\n");
    
    // szBuffer now contains the description of the directly connected (via USB) controller
    
    int pNumberOfConnectedDaisyChainDevices;
    char * szDeviceIDNs = new char [sizeBuffers + 1];
    
    int daisyChainID = PI_OpenUSBDaisyChain(szBuffer,
            &pNumberOfConnectedDaisyChainDevices,
            szDeviceIDNs,
            sizeBuffers);
    
    std::printf("\nPort %i (%i Daisy Chain Devices)\n",
            daisyChainID,
            pNumberOfConnectedDaisyChainDevices);
    
    /* Connect to the daisy chain device */
    // daisyChainID is the port of our USB connection
    
    int tirfStageID   = PI_ConnectDaisyChainDevice(daisyChainID,1); // address set on controllers
    int zStageID      = PI_ConnectDaisyChainDevice(daisyChainID,2);
    int bottomStageID = PI_ConnectDaisyChainDevice(daisyChainID,3);
    int middleStageID = PI_ConnectDaisyChainDevice(daisyChainID,4);
    
    
    try {
        /* do some reference moves */
        int stageID = middleStageID;
        
        BOOL servoState;
        BOOL fIfError = PI_qSVO(stageID,NULL,&servoState);
        std::printf("\nqSVO = %i",servoState);
        
        servoState = 1;
        fIfError = PI_SVO(stageID,NULL,&servoState);
        std::printf("\nSVO Success: %i, set SVO = %i",fIfError,servoState);
        
        fIfError = PI_FRF(stageID,NULL); // perform reference move
        std::printf("\nFRF Success: %i\n",fIfError);
        
        /* while it is referencing, lets query the position */
        double pdValueArray; // for returning the position

        /* wait for controller ready */
        int piControllerReady = 0;
        while (piControllerReady == 0) {
            fIfError = PI_qPOS(stageID,NULL,&pdValueArray); // query position
            std::printf("\nPOS = %.5f",pdValueArray);
            fIfError = PI_IsControllerReady(stageID,&piControllerReady);
            if (fIfError == FALSE) {
                std::printf("\nError in ready query\n");
                break;
            }
        }
        
    } catch (...) {
        /* Close connections and close the daisy chain */
        PI_CloseConnection(tirfStageID);
        PI_CloseConnection(zStageID);
        PI_CloseConnection(bottomStageID);
        PI_CloseConnection(middleStageID);
        std::printf("\nDisconnected from controllers");
        
        PI_CloseDaisyChain(daisyChainID);
        std::printf("\nDisconnected from daisy chain\n");
    }
//
//     /* connect to the specified resource */
//     int controllerID = PI_ConnectUSB(szBuffer);
//
//     std::printf("Connected to controller #%i\n",controllerID);
//
//     /* send some commands */
//     char* szAxes = "1"; // this may be where we choose the axis in the daisy chain we are talking to
//     double pdValueArray;
//     BOOL fIfError; // return value of PI functions
//
//     /* check and set servo (closed-loop) mode */
//     BOOL servoState;
//     fIfError = PI_qSVO(controllerID,szAxes,&servoState);
//     std::printf("\nqSVO = %i",servoState);
//
//     servoState = 1;
//     fIfError = PI_SVO(controllerID,szAxes,&servoState);
//     std::printf("\nSVO Success: %i, set SVO = %i",fIfError,servoState);
//
//     /* reference move */
//     fIfError = PI_FRF(controllerID,szAxes); // perform reference move
//     std::printf("\nFRF Success: %i\n",fIfError);
//
//     /* wait for controller ready */
//     int piControllerReady = 0;
//     while (piControllerReady == 0) {
//         fIfError = PI_IsControllerReady(controllerID,&piControllerReady);
//         if (fIfError == FALSE) {
//             std::printf("\nError in ready query\n");
//             break;
//         }
//         std::printf(".");
//     }
//
//     /* query position */
//     fIfError = PI_qPOS(controllerID,szAxes,&pdValueArray); // query position
//     std::printf("\nqPOS Success: %i, POS = %.5f",fIfError,pdValueArray);
//     /* move to new postion */
//     pdValueArray = 5.0500; // move to this position
//     fIfError = PI_MOV(controllerID,szAxes,&pdValueArray);
//     std::printf("\nPOS Success: %i, set POS = %.5f\n",fIfError,pdValueArray);
//     /* wait for movement to stop */
//     BOOL controllerMoving = TRUE;
//     while (controllerMoving == TRUE){
//         fIfError = PI_IsMoving(controllerID,szAxes,&controllerMoving);
//         std::printf("-");
//     }
//     /* query position */
//     fIfError = PI_qPOS(controllerID,szAxes,&pdValueArray); // query position
//     std::printf("\nqPOS Success: %i, POS = %.5f\n",fIfError,pdValueArray);
//
//     /* wait for controller ready */
//     piControllerReady = 0;
//     while (piControllerReady == 0) {
//         fIfError = PI_IsControllerReady(controllerID,&piControllerReady);
//         if (fIfError == FALSE) {
//             std::printf("\nError in ready query\n");
//             break;
//         }
//         std::printf(".");
//     }
//     /* go home */
//     fIfError = PI_GOH(controllerID,szAxes); // move to position 0
//     std::printf("\nGOH Success: %i",fIfError);
//
//     /* disconnect */
//     PI_CloseConnection(controllerID);
//     std::printf("\nDisconnected from controller #%i\n",controllerID);
//
    
    
    
    /* clear memory */
    delete szBuffer, szDeviceIDNs;
    
    
    
    
    return;
    
}