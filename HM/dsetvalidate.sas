/**********************************************************************************
* PROGRAM: DATA SET VALIDATOR                                                     *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: THIS CODE VERIFIES THAT A DATA SET EXISTS.                             *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS CODE ACCEPTS ONE POSITIONAL ARGUMENT: A REFERENCE TO A DATA SET. *
*                                                                                 *
*          IF THE DATA SET IS FOUND, THE CODE RETURNS A 1.                        *
*          IF THE DATA SET IS NOT FOUND, THE CODE RETURNS A 0.                    *
*          ALSO WORKS FOR VIEWS.                                                  *
**********************************************************************************/

%macro dsetvalidate(indata);

	%local dthing vthing thingexist;

	%IF %SYSFUNC(exist(&indata)) %THEN
		%LET dthing=1;
	%ELSE %LET dthing=0;

	%IF %SYSFUNC(exist(&indata,VIEW)) %THEN
		%LET vthing=1;
	%ELSE %LET vthing=0;
	%LET thingexist=0;

	%IF &dthing=1 %THEN
		%LET thingexist=1;

	%IF &vthing=1 %THEN
		%LET thingexist=1;
	&thingexist

%mend dsetvalidate;