/**********************************************************************************
* PROGRAM:  PREFIX REMOVER                                                        *
* VERSION:  1.0                                                                   *
* AUTHOR:   DAMIEN JOHN MELKSHAM                                                  *
* DATE:     12/07/2012                                                            *
***********************************************************************************
* PURPOSE:  THIS PROGRAM REMOVES A PREFIX FROM A LIST OF WORDS                    *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS MACRO REQUIRES TWO POSITIONAL ARGUMENTS.                         *
*           1)A LIST REPRESENTING WORDS,WITH PREFIXES, SEPARATED BY SPACES        *
*           2)THE PREFIX THAT WILL BE REMOVED FROM EACH OF THE WORDS              *
*                                                                                 *
**********************************************************************************/


%macro RPL(List,Prefix);

%local I Var Final Length calc Prelength;
%let Final=%str();
%let I=1;
%do %while( %scan(&List,&I,%str( )) ne %str( ));
	%let Var = %scan(&List,&I,%str( ));
	%let Length =%LENGTH(&Var);
	%let Prelength=%LENGTH(&Prefix);
	%let Var=%SUBSTR(&Var,%EVAL(&PreLength+1),%EVAL(&Length-&Prelength));
	%let Final = &Final &Var;
	%let I = %eval(&I+1);
	%end;
&final

%MEND RPL;


