/**********************************************************************************
* PROGRAM: Remove Word From List                                                  *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham                                                   *
* DATE:    30/08/2012                                                             *
***********************************************************************************
* PURPOSE: Removes a word from a list of words, if it is found in the list        *
*                                                                                 *
***********************************************************************************
* COMMENTS: Takes a word as the first argument, a list of words as the            *
*           second, and the delimiter used in that list as the third              *
*                                                                                 *
*           Returns the list with the offending word removed                      *
*                                                                                 *
**********************************************************************************/

/**********************************************************************************
* PROGRAM: Remove Word From List                                                  *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham                                                   *
* DATE:    30/08/2012                                                             *
***********************************************************************************
* PURPOSE: Removes a word from a list of words, if it is found in the list        *
*                                                                                 *
***********************************************************************************
* COMMENTS: Takes a word as the first argument, a list of words as the            *
*           second, and the delimiter used in that list as the third              *
*                                                                                 *
*           Returns the list with the offending word removed                      *
*                                                                                 *
**********************************************************************************/

%macro removewordfromlist(word,list);

%local i num result secondword;

%let num=%countwords(&list,%STR( ));
%let i=1;
%let result=;
%do %while(&i<=&num);
%let secondword=%scan(&list,&i,%STR( ));
%if &word^=&secondword %then %let result=&result &secondword;
%let i=%eval(&i+1);
%end;
&result

%mend removewordfromlist;