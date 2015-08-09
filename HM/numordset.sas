/**********************************************************************************
* PROGRAM: Number OR Data Set                                                     *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: USED TO TELL WHETHER INPUT IS A NUMBER OR A DATA SET REFERENCE         *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS CODE ACCEPTS ONE POSITIONAL ARGUMENT: A TEXT STRING              *
*                                                                                 *
*           IT IS REDICULOUSLY SIMPLE.                                            *
*           IF THE FIRST LETTER OF THE STRING IS A NUMBER, IT RETURNS "N".        *           
*           IF THE FIRST LETTER OF THE STRING IS NOT A NUMBER, IT RETURNS "D"     *
*                                                                                 *
**********************************************************************************/
%macro Numordset(indata);

	%local RegexID found result;
	%let RegexID=%sysfunc(prxparse(/[0-9]/));
	%let found=%sysfunc(prxmatch(&RegexID,%SUBSTR(&indata,1,1)));

	%IF &found=1 %THEN
		%LET result=N;
	%ELSE %LET result=D;
	%syscall PRXFREE(RegexID);
	&result
%mend NumorDset;