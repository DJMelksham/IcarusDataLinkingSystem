/**********************************************************************************
 * PROGRAM: Delete Data Sets (and views)                                           *
 * VERSION: 1.0                                                                    *
 *  AUTHOR: Damien John Melksham                                                   *
 *    DATE: 13/07/2012                                                             *
 ***********************************************************************************
 * PURPOSE: To make tidying up of macros just that little bit easier               *
 *          by automating the deleting of multiple data sets and views.            *
 *                                                                                 *
 ***********************************************************************************
 * COMMENTS:Often in programs data sets and views may be created with a tendency   *
 *          to mix or match due to efficiency, processing, and design wishes.      *
 *          But deleting them can often involve a bit of programming or tedium     *
 *                                                                                 *
 *          This program will automatically delete a list of data sets/views.      *
 *          It doesn't particularly care which is which, and will seek that        *
 *          information out for itself, and include the data set or view           *
 *          in the requisite command.                                              *
 *                                                                                 *
 *          This macro involves dropping out of macro code and invoking SQL.       *
 *          Has a dependency on the findreplace macro.                             *
 *                                                                                 *
 **********************************************************************************/
%macro deletedsets(dsetlist);
	%local I Var1 vthing dthing J K L jlist klist llist;
	%let I=1;
	%let J=0;
	%let K=0;
	%let L=0;

	%do %while(%scan(&dsetlist,&I,%str( )) ne %str( ));
		%let Var1=%scan(&dsetlist,&I,%str( ));
    %IF %SYSFUNC(exist(&Var1,DATA)) %THEN
		%LET dthing=1;
	%ELSE %LET dthing=0;
	%IF %SYSFUNC(exist(&Var1,VIEW)) %THEN
		%LET vthing=1;
	%ELSE %LET vthing=0;
	%IF &dthing=1 %THEN %DO;
    %LET J=%EVAL(&J+1);
    %let jlist=&jlist &Var1;
	%END;
	%ELSE %IF &vthing=1 %THEN %DO;
	%LET K=%EVAL(&K+1);
    %let klist=&klist &Var1;
	%END;
	%ELSE %DO;
	%LET L=%EVAL(&L+1);
    %LET llist=&llist &Var1;
	%END;

		%let I = %eval(&I+1);
	%end;

	%IF &J>=1 %THEN %DO;
	%LET Jlist=%findreplace(&Jlist,%STR( ),%STR(,));
	PROC SQL;
    DROP TABLE &Jlist;
	QUIT;
	%END;
	%IF &K>=1 %THEN %DO;
	%let Klist=%findreplace(&Klist,%STR( ),%STR(,));
	PROC SQL;
	DROP VIEW &Klist;
	QUIT;
	%END;
	%IF &L>=1 %THEN %DO;
	%PUT NOTE: THE FOLLOWING ITEMS WERE NOT FOUND, AND HENCE NOT DELETED;
    %PUT NOTE: %UPCASE(&LList);
	%END;

%mend deletedsets;