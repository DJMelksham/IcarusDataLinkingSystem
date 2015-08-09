/**********************************************************************************
* PROGRAM: TWO VARIABLES TWO DELIMITERS                                           *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: TO EASILY REPRODUCE A PATTERN I FREQUENTLY FIND IN CODE.               *
*          WITHOUT THE MESS OR FUSS OF REGULAR MACRO PROGRAMMING.                 *
*                                                                                 *
***********************************************************************************
* COMMENTS:THERE ARE 4 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1)A LIST OF VARIABLES                                                   *
*         2)A SECOND LIST OF VARIABLES                                            *
*         3)A DELIMITER                                                           *
*         4)A SECOND DELIMITER                                                    *
*                                                                                 *
*         Anyway, pretending we have a pattern such that:                         *
* 		  List of variables = A(with members v1,v2,v3)                            *
*		  List of variables = B(with members b1,b2,b3)                            *
*		  delimiter 1 = '='	                                                      *
*         delimiter 2 = ','                                                       *
*                                                                                 *
*         Then the macro will output the following pattern:                       *
*         v1=b1,v2=b2,v3=b3,...,etc...                                            *
*                                                                                 *
*         FOR THE LAST MEMBER OF THIS PATTERN, WE DON'T WANT TO OUTPUT THE        *
*         SECOND DELIMITER.                                                       *
*                                                                                 *
*         THE VARLISTS ARE REQUIRED TO BE WORDS SEPARATED BY SPACES.              *
*                                                                                 *
*         IF THE TWO VARLISTS ARE OF DIFFERENT LENGTHS, YOU'RE GOING TO HAVE      *
*         PROBLEMS.                                                               *
*                                                                                 *
*         IT HAS A DEPENDENCY ON THE COUNTWORDS MACRO.                            *
*                                                                                 *
**********************************************************************************/

%macro tvtdl(varlist1,varlist2,delim1,delim2);
	%local I Var1 Var2 count1 count2 Final;
	%LET count1=%countwords(&varlist1,%STR( ));
	%LET count2=%countwords(&varlist2,%STR( ));

	%IF &count1^=&count2 %THEN
		%DO;
			%PUT ERROR: DIFFERING NUMBER OF VARIABLES/WORDS IN THE LISTS FED TO THE TVTDL FUNCTION.;
			%PUT ERROR: HIGH LIKELIHOOD OF EVERYTHING EXPLODING HORRIBLY.;
				%PUT ERROR: THE WORD LISTS INVOLVED WERE AS FOLLOWS:;
			%PUT ERROR: &varlist1;
			%PUT ERROR: &varlist2;
		%END;

	%let Final=%str();
	%let I=1;

	%do %while(%scan(&varlist1,&I,%str( )) ne %str( ));
		%let Var1=%scan(&varlist1,&I,%str( ));
		%let Var2=%scan(&varlist2,&I,%str( ));
			%IF &I=&count1 %THEN %LET Final=&Final.&Var1.&delim1.&Var2;
	%ELSE %LET Final=&Final.&Var1.&delim1.&Var2.&delim2;
	%let I = %eval(&I+1);
	%end;

	&Final
%mend tvtdl;
