/**********************************************************************************
* PROGRAM: REMOVE LIBRARIES MACRO                                                 *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: DEASSIGNS A LIST OF LIBRARIES                                          *
*                                                                                 *
***********************************************************************************
* COMMENTS:A SIMPLE MACRO, WICH ACCEPTS A LIST OF WORDS SEPARATED BY SPACES,      *
*			AND ATTEMPTS TO DEASSIGN THE LIBRARY REPRESENTED BY EACH WORD         *
*                                                                                 *
**********************************************************************************/

%macro removelibraries(input);

%local I count lib;
%let count=%countwords(&input,%STR( ));
%let I=1;
	%do %while(&I<=&count);
%let lib=%scan(&input,&I,%STR( ));
%IF %libvalidate(&lib)=1 %THEN %DO;
libname &lib CLEAR;
%END;
%ELSE %PUT NOTE: LIBRARY %UPCASE(&LIB) IS NOT ASSIGNED AND WAS THEREFORE NOT CLEARED;
%let I = %eval(&I+1);
	%end;

%mend removelibraries;