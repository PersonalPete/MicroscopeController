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
    char * szBuffer = new char [100]; // 100 elements + terminator
    
    char* szFilter = "E-871"; // only return USB devices that start with...
    
    int numControllers = PI_EnumerateUSB(szBuffer,100,szFilter); // numControllers == -5 if buffer too small
    
    /* print the output */
    std::printf("\n%i USB objects\n",numControllers);
    for (int ii = 0; ii < 100; ii ++) {
        std::printf("%c",szBuffer[ii]);
    }
    std::printf("\n");
    
    /* connect to the specified resource */
    int controllerID = PI_ConnectUSB(szBuffer);
    
    std::printf("Connected to controller #%i\n",controllerID);
    
    /* send some commands */
    char* szAxes = "1"; // this may be where we choose the axis in the daisy chain we are talking to
    double pdValueArray;
    BOOL fIfError; // return value of PI functions
    
    /* check and set servo (closed-loop) mode */
    BOOL servoState;
    fIfError = PI_qSVO(controllerID,szAxes,&servoState);
    std::printf("\nqSVO = %i",servoState);
    
    servoState = 1;
    fIfError = PI_SVO(controllerID,szAxes,&servoState);
    std::printf("\nSVO Success: %i, set SVO = %i",fIfError,servoState);
        
    /* reference move */
    fIfError = PI_FRF(controllerID,szAxes); // perform reference move
    std::printf("\nFRF Success: %i\n",fIfError);
    
    /* wait for controller ready */
    int piControllerReady = 0;
    while (piControllerReady == 0) {
        fIfError = PI_IsControllerReady(controllerID,&piControllerReady);
        if (fIfError == FALSE) {
            std::printf("\nError in ready query\n");
            break;
        }
        std::printf(".");
    }
    
    /* query position */
    fIfError = PI_qPOS(controllerID,szAxes,&pdValueArray); // query position
    std::printf("\nqPOS Success: %i, POS = %.5f",fIfError,pdValueArray);
    /* move to new postion */
    pdValueArray = 5.0500; // move to this position
    fIfError = PI_MOV(controllerID,szAxes,&pdValueArray);
    std::printf("\nPOS Success: %i, set POS = %.5f\n",fIfError,pdValueArray);
    /* wait for movement to stop */
    BOOL controllerMoving = TRUE;
    while (controllerMoving == TRUE){
        fIfError = PI_IsMoving(controllerID,szAxes,&controllerMoving);
        std::printf("-");
    }
    /* query position */
    fIfError = PI_qPOS(controllerID,szAxes,&pdValueArray); // query position
    std::printf("\nqPOS Success: %i, POS = %.5f\n",fIfError,pdValueArray);
    
    /* wait for controller ready */
    piControllerReady = 0;
    while (piControllerReady == 0) {
        fIfError = PI_IsControllerReady(controllerID,&piControllerReady);
        if (fIfError == FALSE) {
            std::printf("\nError in ready query\n");
            break;
        }
        std::printf(".");
    }
    /* go home */
    fIfError = PI_GOH(controllerID,szAxes); // move to position 0
    std::printf("\nGOH Success: %i",fIfError);
    
    /* disconnect */
    PI_CloseConnection(controllerID);
    std::printf("\nDisconnected from controller #%i\n",controllerID);
    
    
    
    
    /* clear memory */
    delete szBuffer;
    
    
    
    
    return;
    
}