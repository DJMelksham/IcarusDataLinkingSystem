

/**********************************************************************************
 * PROGRAM: SORTED NEIGHBOURHOOD                                                   *
 * VERSION: 1.0                                                                    *
 *  AUTHOR: DAMIEN JOHN MELKSHAM                                                   *
 *    DATE: 05/08/2012                                                             *
 ***********************************************************************************
 * PURPOSE: THE SORTED NEIGHBOURHOOD PROGRAM IS DESIGNED TO ALLOW QUICK AND FLEXI- *
 *          BLE IMPLIMENTATIONS OF SORTED NEIGHBOURHOOD METHODS ON A DATA SET      *
 *          IT CREATES A DATA SET/VIEW THAT REPRESENTS THE RECORDS WHICH WOULD     *
 *          HAVE BEEN PRODUCED FROM A SORTED NEIGHBOURHOOD PROCEDURE.              *
 ***********************************************************************************
 * COMMENTS: SORTED NEIGHBOURHOOD OPERATES ON A SINGLE DATA SET.                   *
 *           DATASET=THE DATA SET WHICH WILL BE SORTED/NEIGHBOURHOODED...          *
 *           SortVar=THE VARIABLES BY WHICH THE DATA SET WILL BE SORTED              *
 *           ORDER=LETTERS CORRESPONDING TO THE ORDER OF THE VARIABLES IN SortVar    *
 *           DURING THE SORT.  SHOULD BE A STRING OF LETTERS A AND D, WITH A       *
 *           REPRESENTING ASCENDING AND D REPRESENTING DESCENDING.                 *
 *           IF THE ARGUMENT IS NOT SUPPLIED, THEN EVERYTHING IS DONE IN ASCENDING *
 *           ORDER.                                                                *
 *           OUTDATA=THE DATA SET/VIEW THAT IS PRODUCED BY SORTED NEIGHBOURHOOD.   *
 *           VORD=WHETHER A VIEW OR DATA SET IS PRODUCED.  CAREFUL WITH BIG DATA.  *
 *           WINDOW=THE SIZE OF THE WINDOW OPERATING DURING SORTED NEIGHBOURHOOD.  *
 *           FOREVAR AND AFTVAR=IF SUPPLIED INSTEAD OF WINDOW, SPECIFIES TWO       *
 *           VARIABLES ON THE DATA SET SPECIFYING THE LOOK AHEAD AND LOOK BEHIND   *
 *           DIMENSIONS FOR A RECORD ON THE SORTED DATA SET.                       *
 *           PREFIXA AND PREFIXB=SINCE THE MACRO PRODUCES AN OUTPUT DATA SET, THESE*
 *           PREFIXES DETERMINE WHAT WILL BE APPENDED TO THE VARIABLES OUTPUT RE-PR*
 *           ESENTING THE RECORD BEING COMPARED IN EACH ROUND AND THE RECORDS THEY *
 *           ARE BEING COMPARED TO RESPECTIVELY.                                   *
 *           DENIALVAR=IF THIS VAR IS SET, THE PROGRAM LOOKS FOR THIS VARIABLE, AND*
 *           WILL DISALLOW THOSE COMPARISONS WHERE THE DENIAL VAR IS THE SAME. CAN *
 *           BE USED WHEN MERGING TWO DATA SETS TOGETHER INTO A SINGLE DATA SET TO *
 *           ENSURE COMPARISONS ONLY ACROSS THE TWO DATA SETS WHILE NOT PERFORMING *
 *           COMPARISONS BETWEEN RECORDS IN THE SAME DATA SET.                     *
 *           ROLLOVER=IF THIS IS SET TO YES, THE DATA SET IMPLICITLY CURVES BACK   *
 *           UPON ITSELF.  DESIGNED TO GET AROUND THE FACT THAT THE NUMBER OF COMPA*
 *           RISONS ARE NON-EQUAL FOR THOSE RECORDS AT THE BEGINNING AND END OF THE*
 *           SORT.                                                                 *
 *           tagsort=IF SET TO Y, WILL USE THE TAGSORT    *
 *           METHOD TO SORT THE INPUT DATA SET                                     *
 **********************************************************************************/


%macro SNHood(
			DataSet=, /* */
			SortVar=,/* */
			Order=_DJM_NONE,/* */
			Outdata=work.SNHood,/* */
			VorD=V,/* */
			window=_DJM_NONE,/* */
			forevar=_DJM_NONE,/* */
			aftvar=_DJM_NONE,/* */
			prefixA=a_,/* */
			prefixB=b_,/* */
			denialvar=_DJM_NONE,
			rollover=N,
			tagsort=N
			);
	/* UPCASE variables and set local macro vars */
	%let SortVar=%UPCASE(&SortVar);
	%let Order=%UPCASE(&Order);
	%let VorD=%UPCASE(%SUBSTR(&VorD,1,1));
	%let tagsort = %UPCASE(%SUBSTR(&tagsort,1,1));
	%let rollover = %UPCASE(%SUBSTR(&rollover,1,1));
	%local I SortVar2 order2 sortorder num;

	%IF %dsetvalidate(&DataSet) = 0 %THEN %DO;
	%PUT ERROR: Data set &Dataset does not exist;
	%PUT ERROR: Aborting snhood...;
	%GOTO exit;
	%END;

	/* Interleaving of ascending/descending sort order if someone has specified a non-default sort order via the feed in of the list in Order */
	%IF &Order^=_DJM_NONE %THEN
		%DO;
			%let I=1;

			%do %while(%scan(&SortVar,&I,%str( )) ^= %str( ));
				%let order2=%scan(&Order,&I,%str( ));
				%let SortVar2=%scan(&SortVar,&I,%str( ));

				%if &order2^=D %THEN
					%let order2=;
				%else %let order2=DESCENDING;
				%let sortorder=&sortorder &order2 &SortVar2;
				%let I = %eval(&I+1);
			%end;

			%let SortVar=&sortorder;
		%END;

	/* Getting the number of observations in DataSet */
	%let num=%numofobs(&DataSet);
	%let Varlist=%varlistfromdset(&DataSet);

	/* Error check to see whether the user has specificed both window and forevar/aftvar*/
	%IF &window^=_DJM_NONE AND &forevar^=_DJM_NONE AND &aftvar^=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: User has entered values for window, forevar and aftvar;
			%PUT ERROR: These options are mutually exclusive;
			%PUT ERROR: ABORTING.;
			%GOTO exit;
		%end;

	/* Simple error check to see whether window size might be greater than the size of the data set */
	%IF &window>&num AND &rollover=N AND &window^=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: Window size in sorted neighbourhood greater than resulting size of data set.;
			%PUT ERROR: Consider use of rollover option.;
			%PUT ERROR: ABORTING.;
			%GOTO exit;
		%end;

	%IF &forevar^=_DJM_NONE AND &aftvar^=_DJM_NONE %THEN %DO;
		%LET Rollover = Y;
	%END;

	/* Sorting the data sets, so they can be in the same order for our sorted neighbourhood */
	proc sort data=&Dataset
		%IF &tagsort=Y %THEN tagsort;;
			by &SortVar;
	run;

	/* Tree to take if the forevar and aftvar variables remain in their default state */
	%IF &foreVar=_DJM_NONE AND &aftvar=_DJM_NONE %THEN
		%DO;
			/* Now that the two data sets have been sorted, we need to create a data set/view to help impliment the sorted neighbourhood comparison */
			data &outdata(drop=_DJM_J) %IF &VORD^=D %THEN /VIEW=&Outdata;;
				/* Branch of code if rollover option is not set */
				%IF %UPCASE(%SUBSTR(&rollover,1,1))=N OR &rollover=_DJM_NONE %THEN
					%DO;
						do _DJM_i = 1 to &num;
							set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;
							_DJM_j=1;

							do while (_DJM_j<=&window-1 AND _DJM_i+_DJM_j<=&num);
								newpoint=_DJM_i+_DJM_j;
								set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;

								%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
								output;
								_DJM_j=_DJM_j+1;
							end;
						end;

						stop;
					%END;

				/* Branch of code if rollover option is set */
				%ELSE
					%DO;
						do _DJM_i = 1 to &num;
							set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;
							_DJM_j=1;

							do while (_DJM_j<=&window-1);
								newpoint=_DJM_i+_DJM_j;

								do until (newpoint<=&num);
									if newpoint>&num then
										newpoint=newpoint-&num;
								end;

								set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;

								%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
								output;
								_DJM_j=_DJM_j+1;
							end;
						end;

						stop;
					%END;
			run;

		%END;

	/* Tree to take if we need to use forevar and aftvar */
	%ELSE
		%DO;
			/* Checking whether the forevar and aftvar are in the data set */
			%IF %varsindset(&dataset,&forevar &aftvar)=0 %THEN
				%DO;
					%PUT ERROR: Variables &forevar and &aftvar were not found on the reference data set:%UPCASE(&dataset);
					%PUT ERROR: ABORTING;
					%GOTO exit;
				%END;

			/* Now that the two data sets have been sorted, we need to create a data set/view to help impliment the sorted neighbourhood comparison */
			data &outdata(drop=_djm_j) %IF &VORD^=D %THEN /VIEW=&Outdata;;

				/* Branch of code if rollover option is set, which will be all the time, because it is set to this if fore and
					aftvar are supplied. */
				
						do _DJM_i = 1 to &num;
							set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;

							/* part for forevar */
							_DJM_j=0-&prefixa.&forevar;

							do while (_DJM_j<0);
								newpoint=_DJM_i+_DJM_j;

								do until (newpoint<=&num AND newpoint>=1);
									if newpoint<=0 then
										newpoint=newpoint+&num;
								end;
								
										set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
										%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
										output;
				

								_DJM_j=_DJM_j+1;
							end;

							/* part for aftvar */
							_DJM_j=0+&prefixa.&aftvar;

							do while (_DJM_j>0);
								newpoint=_DJM_i+_DJM_j;

								do until (newpoint<=&num AND newpoint>=1);
									if newpoint>&num then
										newpoint=newpoint-&num;
								end;

										set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
										%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
										output;

								_DJM_j=_DJM_j-1;
							end;
						end;

						stop;
						
			run;

		%END;

	%exit:
%mend SNHood;