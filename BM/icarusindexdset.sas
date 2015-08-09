%macro icarusindexdset(DataSet=_DJM_NONE,
			ControlDataset=_DJM_NONE,
			Index1Root=work.Icarusindex1_,
			Index2Root=work.Icarusindex2_,
			ExcludeMissings=N,
			exp=12);
	%local i vars num;
	%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMIssings,1,1));

	/**************************/
	/* Error checking section */
	/**************************/
	/* Do DataSets exist? */
	%IF %DSETVALIDATE(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: Data Set A does not exist;
			%PUT ERROR: Aborting IcarusIndexDset...;
			%GOTO exit;
		%END;

	%IF %DSETVALIDATE(&ControlDataSet)=0 %THEN
		%DO;
			%PUT ERROR: ControlDataSet does not exist;
			%PUT ERROR: Aborting IcarusIndexDset...;
			%GOTO exit;
		%END;

	/* Populate the vars from the Control Data Set */
	%LET Vars = %varlistfromdset(&ControlDataset);

	/* Ensure the variables from the Control Set correspond to the variables in the Data Set */
	%IF %Varsindset(&DataSet,&Vars)=0 %THEN
		%DO;
			%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
			%PUT ERROR: Aborting IcarusIndexDset...;
			%GOTO exit;
		%END;

	%LET num = %numofobs(&ControlDataSet);

	%IF &num = 0 %THEN
		%DO;
			%PUT ERROR: ControlDataSet contains no observations;
			%PUT ERROR: Aborting IcarusIndexDset...;
			%GOTO exit;
		%END;

	/***************************/
	/* ACTUAL CALCULATION PART */
	/***************************/
	%DO I = 1 %TO &num;
		%icarusindex(		
			DataSet=&DataSet,
			Vars=%varkeeplistdset(&ControlDataSet,&I),
			Index1=&Index1Root.&I,
			Index2=&Index2Root.&I,
			ExcludeMissings=&ExcludeMissings,
			exp=&exp);
	%END;

	%exit:
%mend icarusindexdset;