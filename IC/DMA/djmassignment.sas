%macro djmassignment(dset=_DJM_NONE,
			outdata=work.FINAL_ASSIGNMENT,
			qualstatsout=work.QUALITYSTATS,
			ida=_DJM_NONE,
			idb=_DJM_NONE,
			weightvar=_DJM_NONE,
			stopafter=C,
			addgrade=N,
			gradevar=grade,
			qualstats=Y,
			exp=12,
			sasfileoption=N);
	%let stopafter=%UPCASE(%SUBSTR(&stopafter,1,1));
	%let qualstats=%UPCASE(%SUBSTR(&qualstats,1,1));
	%let addgrade=%UPCASE(%SUBSTR(&addgrade,1,1));
	%let sasfileoption=%UPCASE(%SUBSTR(&sasfileoption,1,1));

	/***************************
	ERROR CHECKING
	***************************/
	%IF (&stopafter^=A AND &stopafter ^= B AND &stopafter ^= C) %THEN
		%DO;
			%PUT ERROR: The stopafter parameter must be set to either;
			%PUT ERROR: A, B, or C;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Has indata been supplied? */
	%IF &dset=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: The data set needs to be specified via the indata argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &ida=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the first ID variable via the ida argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &idb=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the second ID variable via the idb argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &weightvar=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the weight variable via the weightvar argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Does indata exist? */
	%IF %dsetvalidate(&dset)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Are variables in data set */
	%IF %varsindset(&dset,&ida)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF %varsindset(&dset,&idb)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF %varsindset(&dset,&weightvar)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/**************************
	ALGORITHM PART
	**************************/
	%local run_category workfile_size1 workfile_size2;
	%local records_linked records_remain roundnumber;
	%local totala totalb totalc grandtotal;
	%let totala = 0;
	%let totalb = 0;
	%let totalc = 0;
	%let grandtotal = 0;

	/*************************************************************/
	/* Step 1: Run algorithm one: Output results to _djm_group_A */
	/*************************************************************/

	/* Define _djm_temp_workfile as those records not eliminated
	by the application of algo 1.  This is achieved via the application
	of _djm_recorddeleter */
	%djm_algo1(	indata=&dset,
		outdata=work._djm_group_a,
		ida=&ida,
		idb=&idb,
		weightvar=&weightvar,
		exp=&exp);

	%djm_rdeleter(	deleter_dset=work._djm_group_a,
		deletee_dset=&dset,
		outdata=work._djm_temp_workfile,
		ida=&ida,
		idb=&idb,
		keepvars=&weightvar,
		exp=&exp);

	%let workfile_size1=0;
	%IF %dsetvalidate(work._djm_temp_workfile) %then %let workfile_size2=%numofobs(work._djm_temp_workfile);
	%else %let workfile_size2=0;
	%IF %dsetvalidate(work._djm_group_a) %then %let records_linked=%numofobs(work._djm_group_a);
	%else %let records_linked=0;
	%let totala=&records_linked;
	%let records_remain=&workfile_size2;
	%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

	/*****************************************************************/
	/* Step 2: Continue running algorithm one until no change in size*/
	/*****************************************************************/
	%DO %WHILE ((&stopafter^=A) AND (&workfile_size1^=&workfile_size2));
		%djm_algo1(	indata=work._djm_temp_workfile,
			outdata=work._djm_group_b_hold,
			ida=&ida,
			idb=&idb,
			weightvar=&weightvar,
			exp=&exp);

		PROC APPEND base=work._djm_group_b data=work._djm_group_b_hold;
		run;

		%djm_rdeleter(deleter_dset=work._djm_group_b_hold,
			deletee_dset=work._djm_temp_workfile,
			outdata=work._djm_temp_workfile,
			ida=&ida,
			idb=&idb,
			keepvars=&weightvar,
			exp=&exp);

		%deletedsets(work._djm_group_b_hold);
		%let workfile_size1 = %numofobs(work._djm_temp_workfile);
		%let records_linked=%EVAL(&totala+%numofobs(work._djm_group_b));
		%let records_remain=&workfile_size1;
		%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

		%IF &workfile_size1 ^= &workfile_size2 %THEN
			%DO;
				%let workfile_size2 = &workfile_size1;
				%let workfile_size1 = 0;
			%END;
	%END;

	%IF &stopafter^=A %THEN
		%IF %dsetvalidate(work._djm_group_b) %then %let totalb=%numofobs(work._djm_group_b);
		%else %let totalb=0;

	/*****************************************************************
	Step 3: Loop algorithms 2, deleter and looping 1 + deleter until no change,
	until records left = 0
	******************************************************************/
	%DO %WHILE ((&stopafter^=B AND &stopafter^=A) AND (&workfile_size2^=0));

		/* Algo 2 and deletion */
		%djm_algo2(indata=work._djm_temp_workfile,
			outdata=work._djm_group_c_hold,
			ida=&ida,
			idb=&idb,
			weightvar=&weightvar,
			avgnoisevar=_djm_avgnoise,
			locfamvar=_djm_locfam,
			exp=&exp,
			sasfileoption=&sasfileoption);

		PROC APPEND base=work._djm_group_c data=work._djm_group_c_hold;
		run;

		%djm_rdeleter(	deleter_dset=work._djm_group_c_hold,
			deletee_dset=work._djm_temp_workfile,
			outdata=work._djm_temp_workfile,
			ida=&ida,
			idb=&idb,
			keepvars=&weightvar,
			exp=&exp);

		%deletedsets(work._djm_group_c_hold);

		%let workfile_size2=%numofobs(work._djm_temp_workfile);
		%if %dsetvalidate(work._djm_group_c) %then
		%let records_linked=%EVAL(&totala+&totalb+%numofobs(work._djm_group_c));
		%else %let records_linked=%EVAL(&totala+&totalb+0);
		%let records_remain=&workfile_size2;
		%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

		/* Algo 1 loop */
		%DO %WHILE ((&workfile_size1^=&workfile_size2) AND (&workfile_size2^=0));
			%djm_algo1(	indata=work._djm_temp_workfile,
				outdata=work._djm_group_c_hold,
				ida=&ida,
				idb=&idb,
				weightvar=&weightvar,
				exp=&exp);

			PROC APPEND base=work._djm_group_c data=work._djm_group_c_hold;
			run;

			%djm_rdeleter(	deleter_dset=work._djm_group_c_hold,
				deletee_dset=work._djm_temp_workfile,
				outdata=work._djm_temp_workfile,
				ida=&ida,
				idb=&idb,
				keepvars=&weightvar,
				exp=&exp);

			%deletedsets(work._djm_group_c_hold);

			%let workfile_size1 = %numofobs(work._djm_temp_workfile);
			%let records_linked=%EVAL(&totala+&totalb+%numofobs(work._djm_group_c));
			%let records_remain=&workfile_size1;
			%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

			%IF &workfile_size1 ^= &workfile_size2 %THEN
				%DO;
					%let workfile_size2 = &workfile_size1;
					%let workfile_size1 = 0;
				%END;
		%END;
	%END;

	/* populating macro totals */
	%IF &stopafter^=B AND &stopafter^=A %THEN %DO;
		%if %dsetvalidate(work._djm_group_c) %then %let totalc=%numofobs(work._djm_group_c);
		%else %let totalc=0;
	%END;
	%IF &stopafter=A %THEN
		%let grandtotal = &totala;
	%ELSE %IF &stopafter=B %THEN
		%let grandtotal = %EVAL(&totala + &totalb);
	%ELSE %IF &stopafter=C %THEN
		%let grandtotal = %EVAL(&totala + &totalb + &totalc);

	/*************************************************************
	Part 4: FINAL MERGING AND TIDY UP
	*************************************************************/
	%deletedsets(work._djm_temp_workfile);

	%IF &addgrade = Y %THEN
		%DO;
			%IF %dsetvalidate(work._djm_group_a) %THEN
				%DO;

					data work._djm_group_a;
						set work._djm_group_a;
						length &gradevar $ 1;
						&gradevar = 'A';
					run;

				%END;

			%IF %dsetvalidate(work._djm_group_b) %THEN
				%DO;

					data work._djm_group_b;
						set work._djm_group_b;
						length &gradevar $ 1;
						&gradevar = 'B';
					run;

				%END;

			%IF %dsetvalidate(work._djm_group_c) %THEN
				%DO;

					data work._djm_group_c;
						set work._djm_group_c;
						length &gradevar $ 1;
						&gradevar = 'C';
					run;

				%END;
		%END;

	%IF %dsetvalidate(&outdata) %THEN %DO;
		%deletedsets(&outdata);
	%END;

	%IF %dsetvalidate(work._djm_group_a) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_a;
			run;

			%deletedsets(work._djm_group_a);
		%END;

	%IF %dsetvalidate(work._djm_group_b) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_b;
			run;

			%deletedsets(work._djm_group_b);
		%END;

	%IF %dsetvalidate(work._djm_group_c) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_c;
			run;

			%deletedsets(work._djm_group_c);
		%END;

	/*************************************************************
	Part 5: QUALITY STATS
	*************************************************************/
	%IF &QUALSTATS=Y %THEN
		%DO;

			Data &qualstatsout;
				length Info $ 22 Number 8;
				Info = "A Grade";
				Number = &totala;
				output;
				Info = "B Grade";
				Number = &totalb;
				output;
				Info = "C Grade";
				Number = &totalc;
				output;
				Info = "A Grade Percent";
				Number = %SYSEVALF((&totala/&grandtotal)*100);
				output;
				Info = "B Grade Percent";
				Number = %SYSEVALF((&totalb/&grandtotal)*100);
				output;
				Info = "C Grade Percent";
				Number = %SYSEVALF((&totalc/&grandtotal)*100);
					output;
				Info = "Total Records Assigned";
				Number = &grandtotal;
				output;
			run;

		%END;

	%exit:
%mend djmassignment;