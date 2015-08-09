/**********************************************************************************
* PROGRAM: Simple find and replacer                                               *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: A simple macro to act as a find/replace simplifier in macro code.      *
*                                                                                 *
***********************************************************************************
* COMMENTS:The macro requires three arguments                                     *
*                                                                                 *
*         1) The string on which to perform the find/replace                      *
*         2) The find pattern, expressed as part of a perl regular expression     *
*         3) The replacement pattern, expressed as part of a perl regular exp.    *
*                                                                                 *
*         The function returns the string with the find replace performed.        *
*                                                                                 *
**********************************************************************************/

%macro findreplace(string,find,replace);
%local result;
%let result=%sysfunc(prxchange(s/&find./&replace./,-1,&string.));
&result
%mend findreplace;
