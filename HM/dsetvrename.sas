/**********************************************************************************
* PROGRAM: Rename Variables                                                       *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham                                                   *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: This macro makes renaming variables somewhat easier.                   *
*                                                                                 *
***********************************************************************************
* COMMENTS: Unlike some of my other macros, this one does involve non-macro code. *
*           But it still makes it easier to rename variables with lists           *
*           derived from macro variables.                                         *
*                                                                                 *
*           The three positional arguments are:                                   *
*           1)the data set                                                        *
*           2)list of variables separated by a space to be renamed                *
*           3)list of variables to which they will be renamed                     *
*                                                                                 *
*           It has a dependency on the tvtdl macro.                               *
**********************************************************************************/

%macro dsetvrename(Dataset,oldvarlist,newvarlist);

%local k old new;
  %let k=1;
  %let old = %scan(&oldvarlist,&k);
  %let new = %scan(&newvarlist,&k);
    
PROC DATASETS library=%libnameparse(&Dataset) nolist;
    modify %dsetparse(&Dataset);
    rename%STR( )
    %do %while((&old NE %STR()) OR (&new NE %STR()));
      &old=&new%STR( )
      %let k=%eval(&k+1);
      %let old=%scan(&oldvarlist, &k);
      %let new = %scan(&newvarlist, &k);
  %end;
  ;
quit;
run;

%mend dsetvrename;