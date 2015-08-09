%macro NumstoChars(Indata,vars,sd);
/**********************************************************************************
* PROGRAM: Numbers to Characters                                                  *
* VERSION: 1.0                                                                    *
*  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
*    DATE: 12/07/2012                                                             *
***********************************************************************************
* PURPOSE: DESIGNED TO TACKLE THAT SOMEWHAT IRRITATING CIRCUMSTANCE OF CLASHING   *
*          VARIABLE TYPES WHEN WRITING MACROS IN THE PRACTICE OF RECORD LINKING.  *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS CODE ACCEPTS TWO POSITIONAL ARGUMENTS:                           *
*           1) A DATA SET REFERENCE                                               *
*           2) A LIST OF VARIABLES SEPARATED BY SPACES                            *			
*                                                                                 *
*          I HAVE ACTUALLY RECOMMENDED THAT PEOPLE DO NOT RELY ON SUCH PROCESSES  *
*          TO MAKE THEIR VARIABLES CONCHORD.  HOWEVER, IT IS NICE WHEN THEY DO.   *
*          THIS FUNCTION IS FOR USE SPECIFICALLY IN MACRO PROGRAMMING.            *
*          WHEN TAKING A VARIABLE LIST FROM A DATA SET, THE PROGRAM CHECKS THE    *
*          DATA TYPE OF THOSE VARIABLES. FOR THOSE WHERE THE DATA TYPE IS NUMERIC *
*          THE FUNCTION REPLACES THE ORIGINAL NAME OF THAT VARIABLE IN A SIMPLE   *
*          PUT FUNCTION WITH A FORMAT OF BEST12.                                  *
*                                                                                 *  
*          THE FUNCTION RETURNS THE ORIGINAL VARIABLES STRING WITH ANY CHANGES    *
*          MADE.                                                                  *
**********************************************************************************/
	%local rc dsid result tempy I varnum;

	/* Open the data set */
	%let dsid=%sysfunc(open(&indata));
	%let I=1;

	%do %while(%scan(&vars,&I,%str( )) ne %str( ));
		%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
		%let tempy=%SYSFUNC(vartype(&dsid,&varnum));

		%IF &tempy=N %THEN
			%LET result=&result put(%scan(&vars,&I,%str( )),best&sd..);
		%ELSE %LET result=&result %scan(&vars,&I,%str( ));
		%let I = %eval(&I+1);
	%end;

	/* Close the data set */
	%let rc=%SYSFUNC(close(&dsid));
	&result
%mend NumstoChars;