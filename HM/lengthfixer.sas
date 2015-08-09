/**********************************************************************************
* PROGRAM: LENGTH FIXER                                                           *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    31/07/2012                                                             *
***********************************************************************************
* PURPOSE: AUTOMATICALLY TRIMS AND CHANGES LENGTHS OF VARS ON A DATA SET          *
*                                                                                 *
***********************************************************************************
* COMMENTS: THIS SIMPLE MACRO AUTOMATICALLY FIGURES OUT AND ADJUSTS CHARACTERS    *
*	    TO BE THEIR MINIMAL LENGTH, ASSUMING LEADING AND TRAILING BLANK DATA  *
*           DOESN'T MATTER.  NUMBERS ARE SET TO LENGTH 8.                         *
*           IF THE ALIGN OPTION IS SET TO SOMETHING WHICH ISN'T N, THEN THE LENG  *
*           OF ALL CHARACTER VARIABLES ARE SET TO THE SMALLEST MULTIPLE OF 8      *
*           THAT IS POSSIBLE WHILE STILL RETAINING ALL INFORMATION.               *
**********************************************************************************/

%macro lengthfixer(DataSet=,Align=N);
	%local count varlist I var typelist type finallengths length;
	%let varlist=%varlistfromdset(&DataSet);
	%let count=%countwords(&varlist,%STR( ));
	%let typelist=%vartype(&DataSet,&varlist);

	Data &DataSet;
		Set &DataSet;
		%let I=1;

		%do %while(&I<=&count);
			%let var=%scan(&varlist,&I,%STR( ));
			%let type=%scan(&typelist,&I,%STR( ));

			%IF &type=C %THEN
				%DO;
					&var=strip(&var);
				%end;

			%let I=%EVAL(&I+1);
		%end;
	run;

	Data _lengthfixer_temp(keep=%PL(&varlist,l_)) /view=_lengthfixer_temp;
		set &dataset;
		%let I=1;

		%do %while(&I<=&count);
			%let var=%scan(&varlist,&I,%STR( ));
			%let type=%scan(&typelist,&I,%STR( ));

			%IF &type=C %THEN
				%DO;
					l_&var=length(&var);
				%end;

			%IF &type=N %THEN
				%DO;
					l_&var=8;
				%end;

			%let I=%EVAL(&I+1);
		%end;
	run;

	proc means data=_lengthfixer_temp MAX noprint;
		var %PL(&varlist,l_);
		output out=work._lengthfixer_lengths(drop=_type_ _freq_) MAX(%PL(&varlist,l_))=%PL(&varlist,l_);
	run;

	%let finallengths=%obtomacro(work._lengthfixer_lengths,%PL(&varlist,l_),1);

options varlenchk=NOWARN;

	Data &Dataset;
		length 
			%let I=1;

		%do %while(&I<=&count);
			%let var=%scan(&varlist,&I,%STR( ));
			%let type=%scan(&typelist,&I,%STR( ));
			%let length=%scan(&finallengths,&I,%STR( ));

			%IF &Align^=N %THEN
				%DO;
					%IF &type=C %THEN
						%DO;
							%let length=%EVAL(%SYSEVALF(%SYSFUNC(CEIL(&length/8)))*8);
							&var $ &length
						%end;

					%IF &type=N %THEN
						&var 8;
				%END;
			%ELSE
				%DO;
					%IF &type=C %THEN
						%DO;
							&var $ &length
						%end;

					%IF &type=N %THEN
						&var 8;
				%END;

			%let I=%EVAL(&I+1);
		%end;
		;
		set &dataset;
	run;

options varlenchk=WARN;

	%deletedsets(work._lengthfixer_temp work._lengthfixer_lengths);

%mend lengthfixer;
