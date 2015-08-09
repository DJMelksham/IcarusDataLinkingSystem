/**********************************************************************************
* PROGRAM: TERMINATING LIST PATTERN                                               *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: TO EASILY REPRODUCE A PATTERN INVOLVING A LIST OF VARIABLES            *
*          WHERE A DELIMITER AND TEXT STRING AND A SECOND DELIMITER IS APPENEDED  *
*          TO THE END OF EACH VARIABLE IN STRING 1.                               *
*          THE FULL PATTERN TERMINATES ON THE LAST MEMBER, SUCH THAT DELIMITER 2  *
*          IS NOT INCLUDED ON THE END OF THE LAST REPETITION OF THE PATTERN.      *
***********************************************************************************
* COMMENTS:THERE ARE 4 ARGUMENTS TO BE FED INTO THIS MACRO                        *
*                                                                                 *
*         1) STRING1 IS A REGULAR STRING OF WORDS/VARIABLES DELIMITED BY SPACES   *
*         2) STRING2 IS A CONSTANT/STRING CONSISTING OF 1 WORD                    *
*         3) DELIMITER1 IS A TEXT STRING                                          *
*         4) DELIMITER2 IS A TEXT STRING                                          *
*                                                                                 *
*         CLOSELY RELATED TO TVTDL MACRO, THIS MACRO DOES A VERY SIMILAR THING,   *
*         BUT IS FOR USE WHEN ONE OF THE STRINGS IS COMPRISED OF A CONSTANT.      *
*         THUS YOU CAN COMMIT A REPEATED CONSTANT PATTERN ON A STRING OF VARIABLES*
*         WHICH IS SIMPLIFIED THROUGH THE USE OF THIS MACRO.                      *
*                                                                                 *
*         HAS A DEPENDENCY ON THE COUNTWORDS, THE TLTDV MACRO, AND THE REPEATER   *
*         MACRO.                                                                  *
*                                                                                 *
**********************************************************************************/

%macro termlistpattern(string1,string2,delimiter1,delimiter2);
%local string1_num string2_repeated result;
%let string1_num=%countwords(&string1,%STR( ));
%let string2_repeated=%repeater(_DJM_MS_,&string1_num,%str( ));
%let result=%tvtdl(&string1,&string2_repeated,&delimiter1,&delimiter2);
%let result=%findreplace(&result,_DJM_MS_,&string2);
&result
%mend termlistpattern;