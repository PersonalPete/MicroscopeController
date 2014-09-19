/* connectDaisyChainUSB.cpp
 *
 * ARGUMENTS: NONE
 *
 * RETURNS: [DAISY CHAIN ID, NUMBER OF DAISY CHAIN DEVICES]
 *
 * DESCRIPTION: Call this function to begin communication with a PI
 *              controller daisy chain.
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
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    /* allocate memory for the answer */
    int sizeBuffers = 100;
    char * szBuffer = new char [sizeBuffers + 1]; // 100 elements + terminator
    
    char * szFilter = "E-871"; // only return USB devices that start with...
    
    int numControllers = PI_EnumerateUSB(szBuffer,sizeBuffers,szFilter); // numControllers == -5 if buffer too small
    
    /* print the output */
    std::printf("\n%i USB objects\n",numControllers);
    for (int ii = 0; ii < sizeBuffers; ii ++) {
        std::printf("%c",szBuffer[ii]);
        if (szBuffer[ii] == '\0') {
            //std::printf("\nEND\n");
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
    
    /* clear memory */
    delete szBuffer, szDeviceIDNs;
    
    /* fill the matlab return variables */
    INT32_T daisyChainID32 = (UINT32_T) daisyChainID;
    INT32_T numberConnectedDevices32 = (UINT32_T) pNumberOfConnectedDaisyChainDevices;
    
    mwSignedIndex dims [2] = {1,1};
    
    plhs[0] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    double * mDataPtr = mxGetPr(plhs[0]);
    memcpy(mDataPtr, &daisyChainID32, sizeof(daisyChainID32));
    
    plhs[1] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    mDataPtr = mxGetPr(plhs[1]);
    memcpy(mDataPtr, &numberConnectedDevices32, sizeof(numberConnectedDevices32));
    
    return;
    
}