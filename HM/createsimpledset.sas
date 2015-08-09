/**********************************************************************************
* PROGRAM: CREATE SIMPLE DATA SET                                                 *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    16/07/2012                                                             *
***********************************************************************************
* PURPOSE: CREATES A SIMPLE DATA SET OF DIMENSIONS 1xN, FROM 2 DELIMITED LISTS    *
***********************************************************************************
* COMMENTS:THERE ARE 4 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1) DATA SET NAME                                                        *
*         2) STRING 1 IS A DELIMITED LIST OF WORDS                                *
*         3) DELIMITER 1 IS THE DELIMITER FOR STRING 1                            *
*         4) STRING 2 IS A DELIMITED LIST OF WORDS                                *
*         5) DELIMITER 2 IS THE DELIMITER FOR STRING 2                            *
*                                                                                 *
*         1xN IS A VERY COMMON VECTOR SIZE WHICH HAPPENS TO BE PRETTY COMMON IN   * 
*         THE LIKES OF DATA LINKING. ALSO, IT'S A VERY CONVENIENT WAY OF STORING  *
*         TWO STRINGS OF RELATED VARIABLES TOGETHER IN A PORTABLE HARD-COPY.      *  
*                                                                                 *
*         LET ONE STRING BE THE VARIABLE NAMES, AND THE OTHER STRING BE THE       *
*         VALUES.  MY OTHER HELPER FUNCTIONS CAN THEN BE USED TO READ IN EITHER   *
*         THE VARIABLES, THE VALUES, OR BOTH FROM THE DATA SET INTO THE MACRO     *
*         FACILITY FOR EASY MANIPULATION AND FURTHER PROGRAMMING.                 *
*         HAS A DEPENDENCY ON THE COUNTWORDS MACRO.                               *
*                                                                                 *
*         DOES REQUIRE DROPPING OUT OF MACRO LANGUAGE TO ACTUAL CREATE IT HOWEVER.*
*                                                                                 *
**********************************************************************************/

%macro createsimpledset(dsetname,variables,delimiter1,values,delimiter2);

%local N I Specific_Var Specific_Value;
%let N=%countwords(&variables,&delimiter1);
%let I=1;

data &dsetname;
%do %while (&I<=&N);
%let Specific_Var=%scan(&variables,&I,&delimiter1);
%let Specific_Value=%scan(&values,&I,&delimiter2);
&Specific_Var=&Specific_Value;
%let I=%EVAL(&I+1);
%end;
run;

%mend createsimpledset;