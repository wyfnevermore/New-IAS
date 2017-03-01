
#include "dlpdata.h"//;
#include <iostream>
#include <iomanip>
#include <fstream>
using namespace std;

int Add(int a,int b){
    return a+b;

}

bool getDLPData(char *pData,double *wavelength,double *intensity)
{
    scanResults Results;
	if(dlpspec_scan_interpret(pData,SCAN_DATA_BLOB_SIZE,&Results) != DLPSPEC_PASS)
	{
		return false;
	}
	
	int gain = Results.pga;

	for(int i = 0; i < ADC_DATA_LEN; i++)
	{
		wavelength[i] = Results.wavelength[i];
		intensity[i] = Results.intensity[i]/(double)gain;
	}
	return true;
}

