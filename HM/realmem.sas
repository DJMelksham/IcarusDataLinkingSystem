/**********************************************************************************
* PROGRAM: REAL MEMORY                                                            *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    06/08/2012                                                             *
***********************************************************************************
* PURPOSE: RETURNS THE MEMORY AVAILABLE TO SAS AS A NUMBER                        *
*                                                                                 *
**********************************************************************************/

%macro realmem;
%local realmemory;
%let realmemory=%SYSFUNC(getoption(xmrlmem));
&realmemory
%mend realmem;
