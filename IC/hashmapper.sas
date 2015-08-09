%macro hashmapper(IDA=_DJM_NONE,IDB=_DJM_NONE,
			DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
			outdataA=work.HashMappedA,outdataB=work.HashMappedB,
			chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,
			VarRearrange=Y,exp=12,Hashprefix=_DJM_NONE);
	/****************************************
	SET UP SECTION 
	****************************************/
	%local i j var numchars libA libB dataA dataB numvarsA numvarsB autoid numobs varlistA varlistB sortvarlistA sortvarlistB vartypeA vartypeB templen lenarray arraylength;
	%let libA=%UPCASE(%libnameparse(&DataSetA));
	%let libB=%UPCASE(%libnameparse(&DataSetB));
	%let dataA=%UPCASE(%dsetparse(&DatasetA));
	%let dataB=%UPCASE(%dsetparse(&DataSetB));
	%let numchars=%length(&chars);
	%let VarRearrange=%UPCASE(%SUBSTR(&VarRearrange,1,1));
	%let varlistA=%varlistfromdset(&DataSetA);
	%let varlistB=%varlistfromdset(&DataSetB);

	%IF &IDA^=_DJM_NONE AND &IDB^=_DJM_NONE %THEN
		%DO;
			%IF %varsindset(&DatasetA,&IDA) %THEN
				%LET varlistA=%removewordfromlist(&IDA,&varlistA);

			%IF %varsindset(&DataSetB,&IDB) %THEN
				%LET varlistB=%removewordfromlist(&IDB,&varlistB);

			%IF %varsindset(&DatasetA,&IDA) OR %varsindset(&DataSetB,&IDB) %THEN
				%LET autoid=N;
			%ELSE %LET autoid=Y;
		%END;
		%ELSE %DO;
		%PUT ERROR: You must have an ID variable on both data sets;
		%PUT ERROR: Then you need to supply it via IDA and IDB;
		%PUT ERROR: Aborting hashmapper...;
		%GOTO exit;
		%END;

	/******************************************
	ACTUAL OPERATIONS SECTION
	******************************************/

	/* Optionally adding ID and rearranging the variables into the same order on both the data sets */
	%IF &Varrearrange=Y %THEN
		%DO;

			proc sql noprint;
				select name                         
					into :sortvarlistA separated by ' '              
						from dictionary.columns                      
							where libname="&libA" and memname="&DataA"
								order by name;
				select name                         
					into :sortvarlistB separated by ' '              
						from dictionary.columns                      
							where libname="&libB" and memname="&DataB"
								order by name;
			quit;

			%let VarlistA=&sortvarlistA;
			%let VarlistB=&sortvarlistB;
			%LET varlistA=%removewordfromlist(%UPCASE(&IDA),&varlistA);
			%LET varlistB=%removewordfromlist(%UPCASE(&IDB),&varlistB);
		%END;

	%LET numvarsA=%countwords(&VarlistA,%STR( ));
	%LET numvarsB=%countwords(&VarlistB,%STR( ));

	/* Temporary Dset for the ID variables */
	data work._djm_hashmaptemp_1_0;
		set &datasetA(keep=&IDA);
	run;

	data work._djm_hashmaptemp_2_0;
		set &datasetB(keep=&IDB);
	run;

	/* Loop to create the distinct variables from each of the other vars, and their codings */
	%let I=1;

	%DO %WHILE (&I<=&numvarsA);
		%LET var=%SCAN(&VarlistA,&I,%STR( ));

		Data work._djm_tvview_&i /view=work._djm_tvview_&i;
			set &datasetA(keep=&Var) &DatasetB(keep=&Var);
		run;

		%HashDistinct(DataSet=work._djm_tvview_&i,
			Vars=&Var,
			DorV=D,
			Outdata=work._djm_hmtdata_&i);
		%deletedsets(work._djm_tvview_&i);
		%LET I=%EVAL(&I+1);
	%END;

	/* Create a string which is the requisite variable lengths for each of the data items. */
	%let I=1;

	%DO %WHILE (&I<=&numvarsA);
		%let numobs=%numofobs(work._djm_hmtdata_&i);
		%let templen=1;

		%DO %WHILE (%EVAL(&numchars**&templen)<&numobs);
			%IF %EVAL(&numchars**&templen)<&numobs %THEN
				%LET templen=%EVAL(&templen+1);
		%END;

		%let lenarray=&lenarray &templen;
		%LET I=%EVAL(&I+1);
	%END;

	/* Now write data steps which use the chars to create substitute codes for each variable */
	%let I=1;

	%DO %WHILE (&I<=&numvarsA);
		%LET var=%SCAN(&VarlistA,&I,%STR( ));
		%let arraylength=%SCAN(&lenarray,&I,%STR( ));

		Data work._djm_hmtdata_&i;
			length _djm_code $ %scan(&lenarray,&I,%STR( ));
			array _djm_chars {&numchars} $ 1 _temporary_  (
				%let j=1;

				%do %while (&j<=&numchars);
				"%substr(&chars,&j,1)"%str( )
				%let j=%eval(&J+1);
				%END;
			) ;
			array _djm_charspos {&arraylength}_temporary_ (%repeater(1,&arraylength,%STR( )));

			do until (_djm_end);
				set work._djm_hmtdata_&i end=_djm_end;
				_djm_code=
					%let j=1;

				%do %while (&j<=&arraylength);
					_djm_chars[_djm_charspos[&j]]

					%IF &j^=&arraylength %THEN ||;
					%let j=%eval(&J+1);
				%END;
				;
				if missing(&var) then
					call missing(_djm_code);
				else
					do;
						%let j=1;

						%do %while (&j<=&arraylength);
							%IF &J=1 %THEN
								%DO;
									_djm_charspos[&j]=_djm_charspos[&j]+1;
								%END;
							%ELSE %IF &J<=&arraylength %THEN
								%DO;
									IF _djm_charspos[%EVAL(&j-1)]>&numchars then
										do;
											_djm_charspos[%EVAL(&j-1)]=1;
											_djm_charspos[&j]=_djm_charspos[&j]+1;
										end;
								%END;

							%let j=%eval(&J+1);
						%END;
					end;

				output;
			end;

			stop;
		run;

		%LET I=%EVAL(&I+1);
	%END;

	/* Make data sets with the recodings */
	%let I=1;

	%DO %WHILE (&I<=&numvarsA);
		%LET var=%SCAN(&VarlistA,&I,%STR( ));

		Data work._djm_tvview_1_&i /view=work._djm_tvview_1_&i;
			set &datasetA(keep=&Var);
		run;

		Data work._djm_tvview_2_&i /view=work._djm_tvview_2_&i;
			set &datasetB(keep=&Var);
		run;

		%HashJoin(DataSetA=work._djm_tvview_1_&i,DataSetB=work._djm_hmtdata_&i,JoinVars=&Var,DatavarsB=_djm_code,Jointype=IJ,DorV=V,Outdata=work._DJM_TEMP1,exp=&exp,ForceB=Y,ExcludeMissings=N);
		%HashJoin(DataSetA=work._djm_tvview_2_&i,DataSetB=work._djm_hmtdata_&i,JoinVars=&Var,DatavarsB=_djm_code,Jointype=IJ,DorV=V,Outdata=work._DJM_TEMP2,exp=&exp,ForceB=Y,ExcludeMissings=N);

		Data work._DJM_HASHMAPTEMP_1_&I;
			set _DJM_TEMP1(keep=_djm_code rename=(_djm_code=&Var));
		run;

		Data work._DJM_HASHMAPTEMP_2_&I;
			set _DJM_TEMP2(keep=_djm_code rename=(_djm_code=&Var));
		run;

		/*				%deletedsets(work._djm_tvview_1_&i work._djm_tvview_2_&i work._DJM_TEMP1 work._DJM_TEMP2 work._DJM_HMTDATA_&i);*/
		%LET I=%EVAL(&I+1);
	%END;

	/* Pull the recodings together into one data set A */
	Data &outdataA;
		set _djm_Hashmaptemp_1_0;
		%let I=1;

		%DO %WHILE (&I<=&numvarsA);
			set _djm_Hashmaptemp_1_&i;
			%LET I=%EVAL(&I+1);
		%END;
		;
	run;

	/* Pull the recodings together into one data set B */
	Data &outdataB;
		set _djm_Hashmaptemp_2_0;
		%let I=1;

		%DO %WHILE (&I<=&numvarsA);
			set _djm_Hashmaptemp_2_&i;
			%LET I=%EVAL(&I+1);
		%END;
		;
	run;

	/* Delete the left overs */
	%deletedsets(work._djm_Hashmaptemp_1_0 work._djm_Hashmaptemp_2_0 work._djm_temp1 work._djm_temp2 

	%let I=1;
	%DO %WHILE (&I<=&numvarsA);
	%LET var=%SCAN(&VarlistA,&I,%STR( ));
	work._djm_Hashmaptemp_1_&i%STR( )work._djm_Hashmaptemp_2_&i%STR( )work._djm_tvview_1_&i%STR( )work._djm_tvview_2_&i%STR( )work._djm_hmtdata_&i%STR( )
	%LET I=%EVAL(&I+1);
	%END;
	);
	%IF &Hashprefix^=_DJM_NONE %THEN
		%DO;
			%local tempvarlistA tempvarlistB wordy;
			%let tempvarlistA=%varlistfromdset(&OutdataA);
			%let tempvarlistB=%varlistfromdset(&OutdataB);

			PROC DATASETS lib=%libnameparse(&OutdataA) nolist;
				modify %dsetparse(&OutdataA);
				rename

					%DO I=1 %TO %countwords(&tempvarlistA,%STR( )) %BY 1;
						%LET wordy=%SCAN(&tempvarlistA,&I,%STR( ));
						&Wordy=&Hashprefix.&Wordy%STR( )
					%END;
				;
			QUIT;

			RUN;

			PROC DATASETS lib=%libnameparse(&OutdataB) nolist;
				modify %dsetparse(&OutdataB);
				rename

					%DO I=1 %TO %countwords(&tempvarlistB,%STR( )) %BY 1;
						%LET wordy=%SCAN(&tempvarlistB,&I,%STR( ));
						&Wordy=&Hashprefix.&Wordy%STR( )
					%END;
				;
			QUIT;

			RUN;

		%END;

	%exit:
%mend hashmapper;