/**********************************************************************************
* PROGRAM: CONFIRM VARIABLES IN DATA SET                                          *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: TO CONFIRM WHETHER VARIABLES IN A LIST ARE ACTUALLY CONTAINED          *
*          IN A DATASET.                                                          *
*                                                                                 *
***********************************************************************************
* COMMENTS:REQUIRES A DATA SET NAME, AND A LIST OF VARIABLES SEPARATED BY SPACES  *
*          IF THE VARIABLES ARE ALL IN THE DATA SET, THE FUNCTION RETURNS 1.      *
*          OTHERWISE IT RETURNS 0.                                                *
*                                                                                 *
**********************************************************************************/

%macro varsindset(indata,vars);
	%local rc dsid result I;

%let result=1;

%let dsid=%sysfunc(open(&indata));
	%let I=1;

	%do %while( %scan(&vars,&I,%str( )) ne %str( ));
		%IF %SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))))=0 %THEN
			%LET result=0;
		%let I = %eval(&I+1);
	%end;
%let rc=%SYSFUNC(close(&dsid));

&result

%mend varsindset;