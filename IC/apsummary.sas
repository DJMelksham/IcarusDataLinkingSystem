%macro apsummary(dataset=_DJM_NONE,
			outdata=work.apsummary,
			dropvars=_DJM_NONE,
			countvar=count,
			DorV=D,
			exp=12);

	%local vars i dropnum;
	%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));

	%IF &DataSet = _DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the dataset parameter;
			%PUT ERROR: Aborting apsummary...;
			%GOTO exit;
		%END;

	%IF %dsetvalidate(&DataSet) = 0 %THEN
		%DO;
			%PUT ERROR: &dataset does not exist;
			%PUT ERROR: Aborting apsummary...;
			%GOTO exit;
		%END;

	%IF &dropvars ^= _DJM_NONE %THEN
		%DO;
			%IF %varsindset(&dropvars) = 0 %THEN
				%DO;
					%PUT ERROR: All of the dropvars are not found in &dataset;
					%PUT ERROR: Aborting apsummary...;
					%GOTO exit;
				%END;
		%END;

	%let vars = %UPCASE(%varlistfromdset(&dataset));

	%IF &dropvars^=_DJM_NONE %THEN
		%DO;
			%let I = 1;
			%let dropvars=%UPCASE(&dropvars);

			%DO %WHILE (%scan(&dropvars,&i,%STR( )) ^= %STR( ));
				%let vars = %removewordfromlist(&dropvars,&vars,%str( ));

				%EVAL(&I + 1);
			%END;
		%END;

	%HashCount(DataSet=&dataset,
		VARS=&vars,
		CountVar=&countvar,
		DorV=&DorV,
		Outdata=&outdata,
		exp=&exp);

	%exit:

%mend apsummary;