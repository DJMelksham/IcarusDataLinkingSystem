%macro icarus_distslice(ControlDataSet=_DJM_NONE, 
						DataSet=_DJM_NONE, 	
						DataSetNames=_ic_slice, 
						deloriginal=N, 
						Includelocal=N);

	/* Includelocal is designed to be a flag to determine whether a data set will be retained
	in the local session as well */

	%local num i rworkref tempdata;
	%let tempdata=_djm_ic_temp;
	%let num=%numofobs(&ControlDataSet);
	%let Includelocal=%UPCASE(%SUBSTR(&Includelocal,1,1));

	%IF &Includelocal=Y %THEN
		%DO;
			%LET num=%EVAL(&num+1);
		%END;

	%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));

	%IF &DataSet=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must enter a valid data set to slice.;
			%PUT ERROR: Aborting icarus_distslicer...;
			%GOTO exit;
		%END;

	%IF %DsetValidate(&Dataset)=0 %THEN
		%DO;
			%PUT ERROR: &Dataset does not exist.;
			%PUT ERROR: Aborting icarus_distslicer;
			%GOTO exit;
		%END;

	%IF &ControlDataSet=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must enter a valid data set to slice.;
			%PUT ERROR: Aborting icarus_distslicer...;
			%GOTO exit;
		%END;

	%IF %DsetValidate(&ControlDataSet)=0 %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not exist.;
			%PUT ERROR: Aborting icarus_distslicer;
			%GOTO exit;
		%END;

	%dsetslicer(Dataset=&DataSet,
		N=&num,
		Sequential=N,
		Partitions=_DJM_NONE,
		DataSetRoot=work._ic_t,
		DorV=V,
		Report=N,
		ReportDSet=work.Datasets,
		deloriginal=N);

	%IF &includelocal=Y %THEN
		%DO;

			PROC SQL;
				%DO i = 1 %TO %EVAL(&num-1) %BY 1;
					%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
					CREATE TABLE &rworkref..&DataSetNames.&i AS
						SELECT *
							FROM work._ic_t&i;
				%END;

				CREATE TABLE work.&DataSetNames.&num AS
					SELECT *
						FROM work._ic_t&i;
			QUIT;

			%deletedsets(
			%DO i = 1 %TO &num %BY 1;
			work._ic_t&i%STR( )
		%END;
	);
%END;
	%ELSE
		%DO;

			PROC SQL;
				%DO i = 1 %TO &num %BY 1;
					%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
					CREATE TABLE &rworkref..&DataSetNames.&i AS
						SELECT *
							FROM work._ic_t&i;
				%END;
			QUIT;

			%deletedsets(
			%DO i = 1 %TO &num %BY 1;
			work._ic_t&i%STR( )
		%END;
	);
		%END;

%IF &deloriginal=Y %THEN %DO;
%deletedsets(&Dataset);
%END;

	%exit:
%mend icarus_distslice;