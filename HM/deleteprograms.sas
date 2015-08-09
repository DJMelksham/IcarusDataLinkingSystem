/**********************************************************************************
* PROGRAM: Delete Programs                                                        *
* VERSION: 1.0                                                                    *
*  AUTHOR: Damien John Melksham                                                   *
*    DATE: 13/07/2012                                                             *
***********************************************************************************
* PURPOSE: To make tidying up of macros just that little bit easier               *
*          by automating the deletion of multiple compiled data set programs.     *
*                                                                                 *
***********************************************************************************
* COMMENTS:Often in programs compiled data step programs may be created.          *
*                                                                                 *
*          This macro involves dropping out of macro code and invoking            *
*          PROC DATASETS                                                          *
*          It has a dependency on the progvalidate macro                          *
**********************************************************************************/

%macro deleteprograms(programs);

%local I Var1 result RegexID found rn_lib rn_data;
%let I=1;
%let RegexID=%sysfunc(prxparse(/((\w+)\.)?(\w+)/));
	%do %while(%scan(&programs,&I,%str( )) ne %str( ));
		%let Var1=%scan(&programs,&I,%str( ));
	
	%let found=%sysfunc(prxmatch(&RegexID, &Var1));
	%IF &found>=1 %THEN
		%DO;
			%let rn_lib=%UPCASE(%sysfunc(prxposn(&RegexID,2,&Var1)));
			%let rn_data=%UPCASE(%sysfunc(prxposn(&RegexID,3,&Var1)));
			%IF %length(&rn_lib)=0 %THEN
				%LET rn_lib=WORK;
		%END;

		%IF %progvalidate(&Var1)=1 %THEN %DO;
       PROC DATASETS lib=&rn_lib. memtype=PROGRAM nolist;
	   DELETE &rn_data;
	   QUIT;
	   RUN;
	%END;
	%ELSE %DO;
	%PUT NOTE: &rn_lib..&rn_data was not deleted as such a program did not exist.;
	%END;
				
	%let I = %eval(&I+1);
	%end;
	%syscall PRXFREE(RegexID);

%mend deleteprograms;