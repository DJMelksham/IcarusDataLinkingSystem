%macro icarus_distsmoosh(ControlDataSet=_DJM_NONE, 
			OutData=_DJM_NONE, 	
			DataSetNames=_ic_slice,
			deloriginal=N, 
			Includelocal=N);
	%local num i rworkref tempdata;
	%let tempdata=_djm_ic_temp;
	%let num=%numofobs(&ControlDataSet);
	%let Includelocal=%UPCASE(%SUBSTR(&Includelocal,1,1));

	%IF &Includelocal=Y %THEN
		%DO;
			%LET num=%EVAL(&num+1);
		%END;

	%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));

	%IF &ControlDataSet=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must enter a valid data set to slice.;
			%PUT ERROR: Aborting icarus_distsmoosh...;
			%GOTO exit;
		%END;

	%IF %DsetValidate(&ControlDataSet)=0 %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not exist.;
			%PUT ERROR: Aborting icarus_distsmoosh;
			%GOTO exit;
		%END;

	/**********************************/
	/* ACTUAL WORK BIT */
	/**********************************/
	%IF &includelocal=Y %THEN
		%DO;

			PROC SQL;
				%DO i = 1 %TO %EVAL(&num-1) %BY 1;
					%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
					CREATE TABLE work.&DataSetNames.&i AS
						SELECT *
							FROM &rworkref..&DataSetNames.&i;
				%END;
			QUIT;

		%END;
	%ELSE
		%DO;

			PROC SQL;
				%DO i = 1 %TO %EVAL(&num) %BY 1;
					%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
					CREATE TABLE work.&DataSetNames.&i AS
						SELECT *
							FROM &rworkref..&DataSetNames.&i;
				%END;
			QUIT;

		%END;

	%dsetsmoosh(Outdata=&OutData,
		N=_DJM_AUTO,
		DataSetRoot=work.&DataSetNames,
		deloriginal=Y);

	%IF &deloriginal=Y %THEN
		%DO;
			%IF &includelocal=Y %THEN
				%DO;
					%deletedsets(
					%DO i = 1 %TO %EVAL(&num-1) %BY 1;
					%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
					&rworkref..&DataSetNames.&i%STR( )
				%END;
			);
		%END;
	%ELSE
		%DO;
			%deletedsets(
			%DO i = 1 %TO %EVAL(&num) %BY 1;
			%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
			&rworkref..&DataSetNames.&i%STR( )
		%END;
	);
%END;
%END;

%exit:
%mend icarus_distsmoosh;