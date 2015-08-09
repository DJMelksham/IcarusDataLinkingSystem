
%macro dsetslicer(Dataset=_DJM_NONE,
			N=_DJM_NONE,
			Sequential=N,
			Partitions=_DJM_NONE,
			DataSetRoot=work.Slice,
			DorV=D,
			Report=N,
			ReportDSet=work.Datasets,
			deloriginal=N);
	/**********************************
	 * ERROR CHECKING AND SETUP SECTION*
 **********************************/
	%local I branch num num2 rounds first last dsetcount len;
	%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
	%LET Report=%UPCASE(%SUBSTR(&Report,1,1));
	%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));

	%IF &DataSet=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must enter a valid data set to slice.;
			%PUT ERROR: Aborting DSetSlicer...;
			%GOTO exit;
		%END;

	%IF %DsetValidate(&Dataset)=0 %THEN
		%DO;
			%PUT ERROR: &Dataset does not exist.;
			%PUT Aborting DSetSlicer...;
		%END;

	%IF &N^=_DJM_NONE %THEN
		%DO;
			%LET Partitions=_DJM_NONE;
			%LET PartitionDset=_DJM_NONE;
			%LET PartitionVar=_DJM_NONE;
			%LET branch=N;
		%END;
	%ELSE %IF &Partitions^=_DJM_NONE %THEN
		%DO;
			%LET N=_DJM_NONE;
			%LET PartitionDset=_DJM_NONE;
			%LET PartitionVar=_DJM_NONE;
			%LET branch=Partitions;
		%END;

	%IF &Sequential=Y %THEN
		%DO;
			%IF &DorV=V %THEN
				%DO;
					%PUT ERROR: Data type cannot be a view when splitting records sequentially;
					%PUT ERROR: into many data sets;
					%PUT ERROR: Set DorV parameter to D.;
					%PUT ERROR: Aborting...;
					%GOTO exit;
				%END;
		%END;

	/***********************************
	 * ACTUAL WORK/CALCULATIONS SECTION *
 ***********************************/

	/* Option to take if we are dividing the data set up into N Data sets */
	%IF &Branch=N %THEN
		%DO;
			%IF &Sequential=N %THEN
				%DO;
					%LET num=%numofobs(&DataSet);

					%IF &N>&num %THEN
						%DO;
							%PUT ERROR: N IS GREATER THAN THE NUMBER OF OBSERVATIONS IN THE DATASET;
							%PUT ERROR: ABORTING;
							%GOTO exit;
						%END;

					%LET num2=%SYSFUNC(FLOOR(%SYSEVALF((&num/&N))));

					PROC SQL;
						%LET first=1;
						%LET last=&num2;
						%LET dsetcount=&N;

						%IF &DorV=D %THEN
							%DO;
								%DO i=1 %TO &N %BY 1;
									CREATE TABLE &DataSetRoot.&i AS
										SELECT *
											FROM &DataSet.(firstobs=&first obs=&last);
									%LET first=%EVAL(&last+1);

									%IF &i=%EVAL(&n-1) %THEN
										%LET last=&num;
									%ELSE %LET last=%EVAL(&num2*(&I+1));
								%END;
							%END;
						%ELSE
							%DO;
								%DO i=1 %TO &N %BY 1;
									CREATE VIEW &DataSetRoot.&i AS
										SELECT *
											FROM &DataSet.(firstobs=&first obs=&last);
									%LET first=%EVAL(&last+1);

									%IF &i=%EVAL(&n-1) %THEN
										%LET last=&num;
									%ELSE %LET last=%EVAL(&num2*(&I+1));
								%END;
							%END;
					QUIT;

				%END;

			/**********************************
				This is the path that outputs records sequentially into different data sets,
				and thereby allows a relatively random/equal distribution of records,
				rather than outputing them based upon cutoffs
			*******************************************/
			%ELSE %IF &Sequential=Y %THEN
				%DO;

					Data 
						%DO i=1 %TO &N %BY 1;
							&DataSetRoot.&i(drop=_djm_counter)%STR( )
						%END;
					;
					_djm_counter=1;

					do until (_djm_eof);
						set &Dataset end=_djm_eof;
						IF _djm_counter=1 then
							output &DataSetRoot.1;

						%DO i=2 %TO &N %BY 1;
						ELSE IF _djm_counter=&i THEN
							output &DataSetRoot.&i%STR( );
						%END;

						_djm_counter=_djm_counter+1;

						if _djm_counter=%EVAL(&N+1) then
							_djm_counter=1;
					end;
					stop;
					run;

				%END;
		%END;

	/* Option we take if we are dividing the data set up into sections based upon a string of numbers representing observation number cut-points */
	%ELSE %IF &Branch=Partitions %THEN
		%DO;
			%LET Partitions = &Partitions %numofobs(&dataset);
			PROC SQL;
				%IF &DorV=D %THEN
					%DO;
						%LET I=1;
						%LET num=%countwords(&Partitions,%STR( ));
						%LET num2=%numofobs(&DataSet);
						%LET first=1;
						%LET last=%SCAN(&Partitions,1,%STR( ));
						%LET dsetcount=&num;

						%DO %WHILE(%SCAN(&Partitions,&I,%STR( ))^=%STR());
							CREATE TABLE &DataSetRoot.&i AS
								SELECT *
									FROM &DataSet.(firstobs=&first obs=&last);
							%let first=%EVAL(&last+1);

							%IF last^=%SCAN(&Partitions,&num,%STR( )) %THEN
								%LET last=%SCAN(&Partitions,%EVAL(&I+1),%STR( ));
							%ELSE %LET last=&num2;
							%LET I=%EVAL(&I+1);
						%END;
					%END;
				%ELSE
					%DO;
						%LET I=1;
						%LET num=%countwords(&Partitions,%STR( ));
						%LET num2=%numofobs(&DataSet);
						%LET first=1;
						%LET last=%SCAN(&Partitions,1,%STR( ));
						%LET dsetcount=&num;

						%DO %WHILE(%SCAN(&Partitions,&I,%STR( ))^=%STR());
							CREATE VIEW &DataSetRoot.&i AS
								SELECT *
									FROM &DataSet.(firstobs=&first obs=&last);
							%let first=%EVAL(&last+1);

							%IF last^=%SCAN(&Partitions,&num,%STR( )) %THEN
								%LET last=%SCAN(&Partitions,%EVAL(&I+1),%STR( ));
							%ELSE %LET last=&num2;
							%LET I=%EVAL(&I+1);
						%END;
					%END;
			QUIT;

		%END;

	/* Additional option whereby a data set is output that contains a list of all the data set names. */
	%IF &Report=Y %THEN
		%DO;
			%let len=%length(&DataSetRoot.&dsetcount);

			Data &reportDset(drop=i);
				length DataSets $ &len;

				do i=1 to &Dsetcount by 1;
					DataSets="&DataSetRoot"||STRIP(PUT(i,BEST12.));
					output;
				end;

				stop;
			run;

		%END;

	%IF &deloriginal=Y %THEN
		%DO;
			%IF &DorV=V %THEN
				%DO;
					%PUT WARNING: You really shouldnt delete the data set if youre;
					%PUT WARNING: splitting it up using views.;
					%PUT WARNING: But since Im a nice guy Ill let you do it anyway.;
					%PUT WARNING: Because I assume you know what youre doing...;
				%END;

			%deletedsets(&Dataset);
		%END;


	%exit:
%mend dsetslicer;