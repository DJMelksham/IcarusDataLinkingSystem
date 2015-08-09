/**********************************************************************************
* PROGRAM: KEEP VARIABLES IN A LIST                                               *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    23/09/2012                                                             *
***********************************************************************************
* PURPOSE: TO KEEP WORDS IN A LIST VIA COMPARISON TO A SECOND LIST OF ZEROS AND   *
*          ONES                                                                   *
***********************************************************************************
* COMMENTS:THERE ARE 2 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1)A LIST OF VARIABLES, SEPARATED BY SPACES                              *
*         2)THE SECOND LIST, COMPOSING OF ZEROS AND ONES                          *
*																				  *
*         THE PROGRAM WILL RETURN THE WORDS WHEREBY THE POSITION OF THE WORD IN   *
*         THE FIRST LIST CORRESPONDS TO THE POSITION OF THE ONES IN THE SECOND    *
* 		  LIST.  TECHNICALLY, YOU CAN USE NON-ZEROS AS THE OTHER NUMBER.          *
**********************************************************************************/

%macro varkeeplist(Varlist,Key);
%local i num var result;
%let num=%countwords(&Varlist,%STR( ));

%let i = 1;

%do %while (&I<=&num);
%if %scan(&Key,&I,%STR( ))=1 %THEN %DO;
%LET Var=%scan(&Varlist,&I,%STR( ));
%LET result=&result &Var;
%END;
%let I=%EVAL(&I+1);
%end;
&result
%mend varkeeplist;