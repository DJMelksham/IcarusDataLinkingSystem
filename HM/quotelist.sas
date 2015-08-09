/**********************************************************************************
* PROGRAM:  Quote List                                                            *
* VERSION:  1.0                                                                   *
* AUTHOR:   Damien Melksham                                                       *
* DATE:     12/08/2012                                                            *
***********************************************************************************
* PURPOSE:  This macro puts double quotes around the words in a list originally   *
*           separated by spaces.                                                  *
*                                                                                 *
***********************************************************************************
* COMMENTS: Careful with its use, as you may have to use the likes of quote and   *
*           str functions with this macro to enable usage with the rest of SAS    *
**********************************************************************************/

%macro quotelist(list);

%local I result word;

%let I=1;
%do %while(%SCAN(&list,&i,%STR( ))^=%STR( ));
%let word=%SCAN(&list,&i,%STR( ));
%if &I=1 %THEN %LET result="&word";
%else %let result=&result "&word";
%LET I=%EVAL(&I+1);
%END;

&result

%mend quotelist;
