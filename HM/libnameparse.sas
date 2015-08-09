/**********************************************************************************
* PROGRAM: LIBNAME PARSER                                                         *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: THIS LITTLE MACRO FUNCTION TAKES A DATA SET REFERENCE AS ENTERED IN    *
*          SAS. IT REMOVES THE DATA SET AND RETURNS ONLY THE LIBRARY REFERENCE    *
*                                                                                 *
***********************************************************************************
* COMMENTS: THE CODE OPERATES VIA A RELATIVELY SIMPLE PERL REGULAR EXPRESSION.    *
*                                                                                 *
*           IF THE DATA SET REFERENCE DOES NOT CONTAIN A LIBRARY REFERENCE, THE   *
*           CODE RETURNS THE LIBRARY "WORK"                                       *
*                                                                                 *
*           IT ACCEPTS ONE POSITIONAL ARGUMENT: THE DATA SET REFERENCE.           *
*                                                                                 *
**********************************************************************************/

%macro libnameparse(indata);
	%local rn_lib;
%LET rn_lib=%scan(&indata,1,.);
%IF &rn_lib=%scan(&indata,-1,.) %THEN %LET rn_lib=WORK;
&rn_lib
%mend libnameparse;
