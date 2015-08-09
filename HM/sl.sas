/**********************************************************************************
* PROGRAM: List suffixer                                                          *
* VERSION: ???                                                                    *
* AUTHOR:  ???-Edited by Damien John Melksham.                                    *
* DATE: ???                                                                       *
***********************************************************************************
* PURPOSE: The List suffixer takes a list and adds a suffix to the end of         *
*          each word.                                                             *
*                                                                                 *
***********************************************************************************
* COMMENTS: List suffixer requires two positional parameter inputs.               *
*           1) A list of words separated by a space.                              *
*           2) The suffix to be added to each of the words                        *
*                                                                                 *
**********************************************************************************/
%macro SL(List,Suffix);
%local I Var Final;
%let Final=%str();
%let I=1;
%do %while(%scan(&List,&I,%str( )) ne %str( ));
	%let Var = %scan(&List,&I,%str( ));
	%let Final=&Final &Var.&Suffix;
	%let I = %eval(&I+1);
	%end;
&final
%mend;