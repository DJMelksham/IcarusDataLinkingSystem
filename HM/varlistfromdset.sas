/**********************************************************************************
 * PROGRAM: VARIABLE LIST FROM DATA SET                                            *
 * VERSION: 1.0                                                                    *
 * AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
 * DATE:    12/07/2012                                                             *
 ***********************************************************************************
 * PURPOSE: OBTAINS THE VARIABLE NAMES CONTAINED IN A DATA SET                     *
 *                                                                                 *
 ***********************************************************************************
 * COMMENTS: SUPPLY THE FUNCTION A DATA SET.                                       *
 *                                                                                 *
 *           THE FUNCTION WILL RETURN THE VARIABLES IN THAT DATA SET.              *
 *                                                                                 *
 **********************************************************************************/
%macro varlistfromdset(indata);
	%local rc dsid cnt result I;
	%let dsid=%sysfunc(open(&indata));
	%let cnt=%sysfunc(attrn(&dsid,nvars));

	%do i = 1 %to &cnt;
		%let result=&result %sysfunc(varname(&dsid,&i));
	%end;

	%let rc=%sysfunc(close(&dsid));
	&result
%mend varlistfromdset;