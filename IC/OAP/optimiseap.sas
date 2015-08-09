/* optimiseap is a macro to optimise the agreement patterns into the smallest
possible number, to be used in the melksham method of data linking. */

%macro optimiseap(dset=,
			excludevars=_DJM_NONE,
			outdata=work.Optimised_AP);
	%local varlist i num var currentmin;
	%let varlist=%varlistfromdset(&dset);

	/* Populate the variables that constitute the agreement pattern vars*/
	%IF &excludevars ^= _DJM_NONE %THEN
		%DO;
			%let i = 1;

			%DO %WHILE (%scan(&excludevars,&i,%STR( ))^=%STR( ));
				%let var = %scan(&excludevars,&i,%STR( ));
				%let varlist = %removewordfromlist(&var,&varlist);
				%let i = %EVAL(&i + 1);
			%END;
		%END;

	/* Make a copy data set that we will use destructively */

	/* We do this so we can easily put the following program inside a loop,
	which terminates when the size of the data set is zero */
	Data work._djm_oap_temp;
		set &dset;
	run;

	/* Get the number of obs in temporary data set to set up the loop */
	%let num = %numofobs(&dset);

	%IF %dsetvalidate(&outdata) %THEN %DO;
		%deletedsets(&outdata);
	%END;

	%do %while (&num ^= 0);

		/* make a view with the sum of 1's for each record
		in the agreement patterns */

		%djm_oap_sumview(dset=_djm_oap_temp,
			varlist=&varlist,
			sumvar=_djm_sumvar,
			outview=work._djm_sumview);

		/* Get the minimum number of agreement patterns found in the view */
		/* Put it into currentmin */

		PROC SQL noprint;
			SELECT MIN(_djm_sumvar)
				INTO :currentmin
					FROM work._djm_sumview;

		%IF &currentmin = 0 %THEN %DO;
		%deletedsets(_djm_oap_temp _djm_sumview);
		%PUT ERROR: You cannot optimise a set of agreement patterns;
		%PUT ERROR: where one of the patterns involves no matches;
		%GOTO exit;
		%END;
			/* Create a second view with those agreement patterns which have the
			minimum number of 1's for this round */

		data work._djm_oap_tempaphold(keep = &varlist);
			set work._djm_sumview(where=(_djm_sumvar = &currentmin));
		run;

		/* Use the agreement patterns in previous data step to generate a big
		where clause, and then use said where clause to keep those records that
		aren't covered by the original agreement patterns. */

		Data work._djm_oap_temp;
			set work._djm_oap_temp(where=(%djm_oap_bigwclause(_djm_oap_tempaphold)));
		run;

		/* Add the patterns currently in _djm_oap_tempaphold into the final selection */

		PROC APPEND BASE=&outdata data=_djm_oap_tempaphold force nowarn;
		run;

		/* Delete the temp files used in the loop */

		%deletedsets(_djm_oap_tempaphold _djm_sumview);

		/* Get the number of records left in the original data set */
		/* The loop will abort if the number is zero. */

		%let num = %numofobs(_djm_oap_temp);
	%END;

%deletedsets(_djm_oap_temp);

%PUT NOTE: ****************************;
%PUT NOTE: AGREEMENT PATTERNS OPTIMISED;
%PUT NOTE: ****************************;

%exit:

%mend optimiseap;
/**/
/*%optimiseap(dset=work.test,*/
/*			excludevars=weight,*/
/*			outdata=work.Optimised_AP);*/