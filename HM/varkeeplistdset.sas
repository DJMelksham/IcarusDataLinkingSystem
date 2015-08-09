/**********************************************************************************
* PROGRAM: KEEP VARIABLES IN A LIST, BASED ON A DATA SET                          *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    23/09/2012                                                             *
***********************************************************************************
* PURPOSE: TO KEEP WORDS IN A LIST VIA COMPARISON TO A SECOND LIST OF ZEROS AND   *
*          ONES. VARIABLES AND SECOND LIST ARE DERIVED FROM A DATA SET            *
***********************************************************************************
* COMMENTS:THERE ARE 2 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1)A DATA SET                                                            *
*         2)AN OBSERVATION NUMBER                                                 *
*																				  *
*		  THE PROGRAM WILL POPULATE THE FIRST LIST WITH THE VARIABLES FOUND IN    *
*         THE DATA SET REFERENCED.                                                *
*         THE PROGRAM WILL POPULATE THE SECOND LIST WITH THE OBSERVATIONS FOUND   *
*         IN OBSERVATION N, WHERE N IS THE SECOND PARAMETER FED TO THIS PROGRAM.  *
*                                                                                 * 
*         THE PROGRAM WILL RETURN THE WORDS WHEREBY THE POSITION OF THE WORD IN   *
*         THE FIRST LIST CORRESPONDS TO THE POSITION OF THE "1's" IN THE SECOND   *
* 		  LIST.  TECHNICALLY, YOU DO NOT NEED BINARY VALUES FOR THE SECOND LIST,  *
*         THOUGH OTHER WORDS WILL BE TREATED LIKE THEY ARE ZEROS.                 *
**********************************************************************************/

%macro VarKeepListDset(DataSet,Obnumber);
%local i num var Varlist ob result;
%let Varlist=%varlistfromDset(&Dataset);
%let num=%countwords(&Varlist,%STR( ));
%let Key=%obtomacro(&DataSet,&Varlist,&Obnumber);

%LET I=1;
%do %while (&I<=&num);
%if %scan(&Key,&I,%STR( ))=1 %THEN %DO;
%LET Var=%scan(&Varlist,&I,%STR( ));
%LET result=&result &Var;
%END;
%let I=%EVAL(&I+1);
%end;
&result
%mend VarKeepListDset;