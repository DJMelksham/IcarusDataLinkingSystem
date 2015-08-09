/**********************************************************************************
* PROGRAM: VARIABLE TYPE FINDER                                                   *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: FIND THE TYPES OF A LIST OF VARIABLES IN A DATASET.                    *
*                                                                                 *
***********************************************************************************
* COMMENTS:TAKES A DATA SET NAME AND A LIST OF VARIABLES SEPARATED BY SPACES.     *
*          RETURNS A STRING OF CHARACTERS SEPARATED BY SPACES.                    *
*          FOR EACH VARIABLE, "C" IS PUT IN THE STRING IF A VARIABLE IS OF        *
*          TYPE CHARACTER.  "N" IS PUT IN THE STRING IF A VARIABLES IS OF         *
*          TYPE NUMERIC.                                                          *
*                                                                                 *
**********************************************************************************/

%macro vartype(indata,vars);
	%local rc dsid result I varnum;
	%let dsid=%sysfunc(open(&indata));
	%let I=1;

	%do %while(%scan(&vars,&I,%str( )) ne %str( ));
		%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
		%let result=&result %SYSFUNC(vartype(&dsid,&varnum));
		%let I = %eval(&I+1);
	%end;

	%let rc=%SYSFUNC(close(&dsid));
	&result
%mend vartype;