/**********************************************************************************
* PROGRAM: PROGRAM VALIDATOR                                                     *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: THIS CODE VERIFIES THAT A COMPILED DATA SET PROGRAM EXISTS.            *
*                                                                                 *
***********************************************************************************
* COMMENTS:THIS CODE ACCEPTS ONE POSITIONAL ARGUMENT: A REFERENCE TO A DATA SET   *
*          PRECOMPILED PROGRAM.                                                   *
*          IF THE PROGRAM IS FOUND, THE CODE RETURNS 1.                           *
*          IF THE PROGRAM IS NOT FOUND, THE CODE RETURNS 0.                       *
*                                                                                 *
**********************************************************************************/

%macro progvalidate(indata);

%local pthing;
%IF %SYSFUNC(exist(&indata,PROGRAM)) %THEN %LET pthing=1;
%ELSE %LET pthing=0;
&pthing
%mend progvalidate;
