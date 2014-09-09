/* setTimings.cpp
 *
 * ARGUMENTS: [EXPOSURE TIME, KINETIC CYCLE TIME]
 *
 * RETURNS: [STATUS CODE, EXPOSURE TIME, KINETIC CYCLE TIME,...
 *                                          ACCUMULATION TIME]
 *
 * DESCRIPTION: Sets the exposure, cycle and accumulation time - note that
 *              the time set is non-necessarily the one returned.
 *              Accumulation time is not used and is set to zero by default
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
    if (nrhs > 2 || nrhs < 2) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:invalidNumInputs",
                "Wrong number of arguments");
    }
    if (nlhs > 4) {
        mexErrMsgIdAndTxt( "Mscope:initialiseCamera:maxlhs",
                "Too many output arguments.");
    }
    
    
    float kin = 0.0f, exp = 0.0f, acc = 0.0f;
    
    /* validate kinetic time and fill our float with it */
    if (!isScalarArray(prhs[1]))
        mexErrMsgIdAndTxt("Mscope:setTimings:invalidArg","2-3 floating point scalars required");
    kin = mxGetScalar(prhs[1]);
    
    /* validate exposure time etc... */
    if (!isScalarArray(prhs[0]))
        mexErrMsgIdAndTxt("Mscope:setTimings:invalidArg","2-3 floating point scalars required");
    exp = (float) mxGetScalar(prhs[0]);
    
    
    unsigned int ac[4]; // andor code array
    
    ac[0] = SetNumberAccumulations(1); // don't accumulate
    
    ac[1] = SetExposureTime(exp); 
    ac[2] = SetKineticCycleTime(kin);
    // ac[3] = SetAccumulationCycleTime(acc);
    
    float expT,accT,kinT; // for the actual set values
    
    ac[3] = GetAcquisitionTimings(&expT,&accT,&kinT);
    
    /* RETURNING A STATUS CODE */
    UINT32_T andorCode32 = DRV_SUCCESS;
    
    for (int ii = 0; ii < 4 ; ii++) {
        if (ac[ii] != DRV_SUCCESS) {
            std::printf("\nError initialising Camera\n%i returned code: %i\n",ii,ac[ii]);
            andorCode32 = 1;
        }
    }
    
    /* CAST TO DOUBLES FOR MATLAB */
    double expTD = (double) expT;
    double accTD = (double) accT;
    double kinTD = (double) kinT;     
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));
    
    plhs[1] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * expPtr = mxGetPr(plhs[1]);
    memcpy(expPtr, &expTD, sizeof(expTD));
    
    plhs[2] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * kinPtr = mxGetPr(plhs[2]);
    memcpy(kinPtr, &kinTD, sizeof(kinTD));
    
    plhs[3] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    double * accPtr = mxGetPr(plhs[3]);
    memcpy(accPtr, &accTD, sizeof(kinTD));
    
    return;
}

