/**********************************************************************************
* PROGRAM: LIBRARY VALIDATOR                                                      *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: THIS CODE VERIFIES THAT A LIBRARY HAS BEEN ASSIGNED.                   *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS CODE ACCEPTS ONE POSITIONAL ARGUMENT: A LIBNAME REFERENCE.       *
*                                                                                 *
*          IF THE LIBRARY IS ASSIGNED, THE CODE RETURNS A 1.                      *
*          IF THE LIBRARY IS NOT ASSIGNED, THE CODE RETURNS A 0.                  *
*                                                                                 *
**********************************************************************************/

%macro libvalidate(indata);

	%local length return RegexID firstchar;
	%let length=%length(&indata);
	%let RegexID=%sysfunc(prxparse(/[A-Za-z_]/));

	%IF &length>=1 %THEN
		%LET firstchar=%SUBSTR(&indata,1,1);

	%IF &length>8 %THEN
		%DO;
			%LET return=0;
		%END;
	%ELSE %IF %SYSFUNC(prxmatch(&RegexID,&firstchar))=0 %THEN
		%DO;
			%LET return=0;
		%END;
	%ELSE %IF %SYSFUNC(LIBREF(&indata))=0 %THEN
		%LET return=1;
	%ELSE %LET return=0;
	%SYSCALL PRXFREE(RegexID);
	&return
%mend libvalidate;