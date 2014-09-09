/* initialiseCamera.cpp
 * 
 * ARGUMENTS: NONE
 * 
 * RETURNS: STATUS CODE
 * 
 * DESCRIPTION: Call this function to initialise an attached camera
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
                "No Input arguments accepted.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }    

    
    // Lets have a go at one of the Andor functions    
    char*  charNullPtr = 0;
    
    // the argument for Initialize is a pointer to a char array with the directory to find the 
    // DETECTOR.INI file containing camera information - but we don't need this for an iXon3
    
    // Initialize is an Andor function
    unsigned int andorCode = Initialize(charNullPtr); // passes a null pointer to char as argument
    
    UINT32_T andorCode32 = (UINT32_T) andorCode;
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * outDataPtr = mxGetPr(plhs[0]);
       
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(outDataPtr, &andorCode32, sizeof(andorCode32));
    
    
    return;
}
