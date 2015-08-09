%Macro dsetsmoosh(Outdata=_DJM_NONE,
			N=_DJM_AUTO,
			DataSetRoot=work.Slice,
			deloriginal=N);
	/**********************************
	 * ERROR CHECKING AND SETUP SECTION*
 **********************************/
	%local I;
	%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));
	%LET DataSetRoot=%UPCASE(&DataSetRoot);

	%IF &N=_DJM_AUTO %THEN
		%LET Branch=N;
	%ELSE %LET Branch=Y;

	/***********************************
	 * ACTUAL WORK/CALCULATIONS SECTION*
 ***********************************/

	/* Option to take if we are pasting N Data sets together */
	%IF &Branch=N %THEN
		%DO;
			/* Auto option: Placing together all those data sets in a library that share the data set root */
			%IF &N=_DJM_AUTO %THEN
				%DO;
					%local names lib dset;
					%let lib=%UPCASE(%libnameparse(&Datasetroot));
					%let dset=%UPCASE(%dsetparse(&Datasetroot));

					PROC SQL noprint;
						SELECT memname
							INTO :names SEPARATED BY " "
								FROM DICTIONARY.TABLES
									WHERE (memtype='DATA' OR memtype='VIEW') AND libname="&lib" AND length(strip(memname))>=%length(&dset) AND substr(memname,1,%length(&dset))="&dset";
					QUIT;

					%IF %dsetvalidate(&OutData)=1 %THEN
						%DO;
							%deletedsets(&Outdata);
						%END;

					PROC DATASETS nolist;
						%LET I=1;

						%DO %WHILE (%scan(&names,&I,%STR( ))^=%STR());
							append base=&Outdata data=&lib..%sysfunc(strip(%scan(&names,&I,%STR( )))) force;
					run;

					%LET I=%EVAL(&I+1);
						%END;
						QUIT;

						%IF &deloriginal=Y %THEN
							%DO;
								%LET I=1;

								%deletedsets(
								%DO %WHILE (%scan(&names,&I,%STR( ))^=%STR( ));
								&lib..%sysfunc(strip(%scan(&names,&I,%STR( ))))
								%LET I=%EVAL(&I+1);
							%END;
						);
				%END;
		%END;
%END;

	/* N option: connects those data sets that share the dataset root, and which have appendages of 1 through N */
	%ELSE
		%DO;
			%IF %dsetvalidate(&OutData)=1 %THEN
				%DO;
					%deletedsets(&Outdata);
				%END;

			PROC DATASETS nolist;
				%DO I = 1 %TO &N %BY 1;
					append base=&Outdata data=&Datasetroot.&i force;
			run;

				%END;
				QUIT;

				%IF &deloriginal=Y %THEN
					%DO;
						%deletedsets(
						%DO I = 1 %TO &N %BY 1;
						&Datasetroot.&i%STR( )
					%END;
				);
		%END;
%END;

	%exit:
%mend dsetsmoosh;