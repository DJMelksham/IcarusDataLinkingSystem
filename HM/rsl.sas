
/**********************************************************************************
* PROGRAM: REMOVE SUFFIX FROM A LIST                                              *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: THIS PROGRAM REMOVES A SUFFIX FROM A LIST OF WORDS CONTAINING A COMMON *
*          SUFFIX.                                                                *
*                                                                                 *
***********************************************************************************
* COMMENTS:THE PROGRAM REQUIRES TWO POSITIONAL PARAMETERS:                        *
*         1)THE LIST OF WORDS, WITH A COMMON SUFFIX,SEPARATED BY SPACES           *
*         2)THE SUFFIX FOR REMOVAL.                                               *
*                                                                                 *
*         NOTE: THE PROGRAM IS NOT VERY INTELLIGENT.  IT REMOVES THE SUFFIX       *
*         BY CHECKING THE LENGTH OF THE SUFFIX INVOLVED, AND REMOVING THE         *
*         SAME NUMBER OF CHARACTERS FROM THE END OF EACH WORD.                    *
*                                                                                 *
**********************************************************************************/

%macro RSL(List,Suffix);

%local I Var Final Length calc Prelength;
%let Final=%str();
%let I=1;
%do %while( %scan(&List,&I,%str( )) ne %str( ));
	%let Var = %scan(&List,&I,%str( ));
	%let Length =%LENGTH(&Var);
	%let Prelength=%LENGTH(&Suffix);
	%let Var=%SUBSTR(&Var,1,%EVAL(&Length-&Prelength));
	%let Final = &Final &Var;
	%let I = %eval(&I+1);
	%end;
&final

%MEND RSL;
