/**********************************************************************************
* PROGRAM: VARIABLE LENGTH FINDER                                                 *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    06/08/2012                                                             *
***********************************************************************************
* PURPOSE: FIND THE LENGTHS FOR A LIST OF VARIABLES IN A DATASET.                 *
*                                                                                 *
***********************************************************************************
* COMMENTS:TAKES A DATA SET NAME AND A LIST OF VARIABLES SEPARATED BY SPACES.     *
*          RETURNS A STRING OF NUMBERS SEPARATED BY SPACES.                       *
*          EACH NUMBER REPRESENTS THE LENGTH OF THE VARIABLE IN THE SAME POSIT-   *
*          ION IN THE STRING OF VARIABLES FED INTO THE MACRO.                     *
*                                                                                 *
**********************************************************************************/

%macro VarLengths(indata,vars);
	%local rc dsid result I varnum;
	%let dsid=%sysfunc(open(&indata));
	%let I=1;

	%do %while(%scan(&vars,&I,%str( )) ne %str( ));
		%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
		%let result=&result %SYSFUNC(varlen(&dsid,&varnum));
		%let I = %eval(&I+1);
	%end;

	%let rc=%SYSFUNC(close(&dsid));
	&result
%mend VarLengths;