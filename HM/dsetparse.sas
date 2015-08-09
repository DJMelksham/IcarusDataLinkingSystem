/**********************************************************************************
 * PROGRAM: DATA SET PARSER                                                        *
 * VERSION: 1.0                                                                    *
 *  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
 *    DATE: 12/07/2012                                                             *
 ***********************************************************************************
 * PURPOSE: THIS LITTLE MACRO FUNCTION TAKES A DATA SET REFERENCE AS ENTERED IN    *
 *          SAS. IT REMOVES THE LIBRARY NAME AND RETURNS ONLY THE DATA SET NAME.   *
 *                                                                                 *
 ***********************************************************************************
 * COMMENTS: THE CODE OPERATES VIA A RELATIVELY SIMPLE PERL REGULAR EXPRESSION.    *
 *                                                                                 *
 *           IF THE DATA SET NAME DOES NOT CONTAIN A LIBRARY REFERENCE, THE        *
 *           CODE SHOULD SIMPLY RETURN THE DATA SET NAME.                          *
 *                                                                                 *
 *           IT ACCEPTS ONE POSITIONAL ARGUMENT: THE DATA SET REFERENCE.           *
 *                                                                                 *
 **********************************************************************************/
%macro dsetparse(indata);
	%local rn_data;
	%LET rn_data=%scan(&indata,-1,.);
	&rn_data
%mend dsetparse;
