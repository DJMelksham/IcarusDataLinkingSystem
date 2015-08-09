/**********************************************************************************
* PROGRAM: List Prefixer                                                          *
* VERSION: ???                                                                    *
* AUTHOR:  ???-Edited by Damien John Melksham.                                    *
* DATE: ???                                                                       *
***********************************************************************************
* PURPOSE: The List Prefixer takes a list and adds a prefix to the beginning of   *
*          each word.                                                             *
*                                                                                 *
***********************************************************************************
* COMMENTS: List Prefixer requires two positional parameter inputs.               *
*           1) A list of words separated by a space.                              *
*           2) The prefix to be added to each of the words                        *
*                                                                                 *
**********************************************************************************/

%macro PL(List,Prefix);
%local I Var Final;
%let Final = %str();
%let I = 1;
%do %while(%scan(&List,&I,%str( )) ne %str( ));
	%let Var = %scan(&List,&I,%str( ));
	%let Final = &Final &Prefix.&Var;
	%let I = %eval(&I+1);
	%end;
&Final
%mend;
