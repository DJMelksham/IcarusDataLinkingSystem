/**********************************************************************************
* PROGRAM: KEEP WORD PATTERN                                                      *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: KEEPS WORDS THAT MATCH A PATTERN                                       *
*                                                                                 *
***********************************************************************************
* COMMENTS:A SIMPLE MACRO, WICH ACCEPTS A LIST OF WORDS SEPARATED BY SPACES,      *
*			AND KEEPS THOSE THAT MATCH A PERL REGULAR EXPRESSION                  *
*                                                                                 *
**********************************************************************************/

%macro keepwordpattern(indata,regex);

%local RegexID found;
	%let RegexID=%sysfunc(prxparse(&regex));
	%let found=%sysfunc(prxmatch(&RegexID, &indata));

%local I result count word ;
%let count=%countwords(&indata,%STR( ));
%let I=1;
	%do %while(&I<=&count);
%let word=%scan(&indata,&I,%STR( ));
%let found=%sysfunc(prxmatch(&RegexID,&word));
%IF &found^=0 %THEN %Let result=&result &word;
%let I = %eval(&I+1);
	%end;
%syscall PRXFREE(RegexID);
&result

%mend keepwordpattern;