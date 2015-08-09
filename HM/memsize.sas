/**********************************************************************************
* PROGRAM: MEMORY SIZE                                                            *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    06/08/2012                                                             *
***********************************************************************************
* PURPOSE: RETURNS THE MAXIMUM MEMORY SIZE SETTING IN SAS.                        *
*                                                                                 *
**********************************************************************************/

%macro memsize;
%local memorysize;
%let memorysize=%SYSFUNC(getoption(MemSize));
&memorysize
%mend memsize;