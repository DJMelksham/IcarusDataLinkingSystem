/**********************************************************************************
* PROGRAM: REPEATER                                                               *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    16/07/2012                                                             *
***********************************************************************************
* PURPOSE: TO TURN ONE WORD INTO A REPEATING STRING SEPARATED BY A DELIMITER      *
*                                                                                 *
***********************************************************************************
* COMMENTS:THERE ARE 3 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1)A "WORD"			                                                  *
*         2)NUMBER OF TIMES THE WORD NEEDS TO BE REPEATED                         *
*         3)A DELIMITER THAT SEPARATES THE REPEATED WORD IN THE NEW LIST/OUTPUT   *
*																				  *
*         THE PROGRAM WILL REPEAT THE WORD N TIMES IN OUTPUT DELIMITED BY THE     *
*         DELIMITER CHOSEN.  USEFUL IN COMBINATION WITH MY OTHER HELPER MACROS    *
* 		  												                          *
**********************************************************************************/
%macro repeater(string,N,delimiter);

%local I Final;

%LET Final=&string;

%let I = 2;
%do %while(&I <= &N);
	%let Final = &final.&Delimiter.&string;
	%let I = %eval(&I+1);
	%end;
&Final

%mend repeater;