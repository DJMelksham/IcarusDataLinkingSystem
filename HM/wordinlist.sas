/* Macro returns a 1 if a word is found in the list, returns a zero if it is not */

%macro wordinlist(Word,List);
%local result wordcount i;
%let wordcount=%countwords(&List,%STR( ));
%let result=0;
%DO i= 1 %TO &wordcount %BY 1;
%IF %SCAN(&list,&I,%STR( ))=&word %THEN %LET result=1;
%END;
&result
%mend wordinlist;