/**********************************************************************************
* PROGRAM: Word Counter                                                           *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: Counts the number of words in a list.                                  *
*                                                                                 *
***********************************************************************************
* COMMENTS: Takes a list of words as the first argument, and a delimiter as the   *
*           second.                                                               *
*                                                                                 *
*           Returns the number of words.                                          *
*                                                                                 *
**********************************************************************************/

%macro countwords(varlist,delimiter);
	%local I result;
	%let I=1;

	%do %while( %scan(&varlist,&I,%str(&delimiter)) ne %str( ));
		%let I = %eval(&I+1);
	%end;

	%LET result=%EVAL(&I-1);
	&result
%mend countwords;