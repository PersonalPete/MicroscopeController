/* setCropAndBin.cpp
 *
 * ARGUMENTS: [INT X_BIN,
 *             INT Y_BIN,
 *             INT X_MIN,
 *             INT X_MAX,
 *             INT Y_MIN,
 *             INT Y_MAX]
 *
 * RETURNS: [STATUS CODE]
 *
 * DESCRIPTION: Sets the binning and region of interest. x corresponds to
 *              horizontal in the SDK and y corresponds to vertical in the 
 *              SDK
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
    if (nrhs != 6) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidNumInputs",
                "Wrong number of arguments");
    }
    if (nlhs > 1 ) {
        mexErrMsgIdAndTxt( "Mscope:setAcqMode:maxlhs",
                "Too many output arguments.");
    }
    
    for (int inPrmNo = 0; inPrmNo < 6; inPrmNo ++) {
        
        if (!isScalarArray(prhs[inPrmNo])) {
            mexErrMsgIdAndTxt( "Mscope:setAcqMode:invalidArg",
                    "All arguments are integers");
        }
    }
    
    
    int xhBin = (int) mxGetScalar(prhs[0]);
    int yvBin = (int) mxGetScalar(prhs[1]);
    
    
    int xhMin = (int) mxGetScalar(prhs[2]);
    int xhMax = (int) mxGetScalar(prhs[3]);
    
    
    int yvMin = (int) mxGetScalar(prhs[4]);
    int yvMax = (int) mxGetScalar(prhs[5]);
    
    unsigned int ac = SetImage(xhBin,yvBin,xhMin,xhMax,yvMin,yvMax); 
    
    /* RETURNING A STATUS CODE */
    UINT32_T andorCode32 = (UINT32_T) ac;
    
    // define an array of mwSignedIndex called dims (which is our output array dimensions)
    mwSignedIndex dims[2] = {1,1};
    
    // set the first element of the array plhs to be a mxArray pointer returned by mxCreateNumericArray
    // the parameters we pass fully describe the memory footprint of this array
    plhs[0] = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    
    // get a pointer to the data in the mxArray pointed at by plhs[0]
    double * codePtr = mxGetPr(plhs[0]);
    
    // copy the memory from the address of returnInt32 to the location pointed to by outDataPtr
    memcpy(codePtr, &andorCode32, sizeof(andorCode32));
    
    return;
}

