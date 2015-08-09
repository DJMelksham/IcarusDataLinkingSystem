%macro icarus_distvar(ControlDataSet=_DJM_NONE, DistVar= , DistVarValue = _DJM_NONE, LocalSessionVar = N);
	%local myoplist oplist totallist;
	%let myoplist = Alias RWork IcarusGerminate;
	%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
	%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
	%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
	%let totallist = &myoplist &oplist;
	%LET LocalSessionVar = %UPCASE(%SUBSTR(&LocalSessionVar,1,1));

	%IF %dsetvalidate(&ControlDataSet)=0 %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not exist.;
			%PUT ERROR: Aborting icarus_distvar macro...;
			%GOTO exit;
		%END;

	%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not meet the requirements of an;
			%PUT ERROR: icarus_connect control data set;
			%PUT ERROR: Aborting icarus_distvar macro...;
			%GOTO exit;
		%END;

	%local num Nodealias i;
	%LET num = %numofobs(&ControlDataSet);

	%DO i = 1 %TO &num %BY 1;
		%let Nodealias = %obtomacro(&ControlDataSet, Alias, &i);

		%IF &DistVarValue = _DJM_NONE %THEN
			%SYSLPUT &DistVar = &i /remote=&NodeAlias;
		%ELSE %SYSLPUT &DistVar = &DistVarValue /remote=&NodeAlias;
	%END;

	%IF &LocalSessionVar = Y %THEN
		%DO;
			%GLOBAL &DistVar;

			%IF &DistVarValue = _DJM_NONE %THEN %DO;
				&DistVar = %EVAL(%numofobs(&ControlDataSet)+1);
				%END;
			%ELSE %DO;
			&DistVar = &DistVarValue;
			%END;
		%END;

	%exit:
%mend icarus_distvar;