%macro icarus_distvardel(ControlDataSet = _DJM_NONE, DistVar = , LocalSessionVar = N);
	%local myoplist oplist totallist;
	%let myoplist = Alias RWork IcarusGerminate;
	%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
	%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
	%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
	%let totallist = &myoplist &oplist;

	%IF %dsetvalidate(&ControlDataSet)=0 %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not exist.;
			%PUT ERROR: Aborting icarus_distvardel macro...;
			%GOTO exit;
		%END;

	%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN
		%DO;
			%PUT ERROR: &ControlDataSet does not meet the requirements of an;
			%PUT ERROR: icarus_connect control data set;
			%PUT ERROR: Aborting icarus_distvardel macro...;
			%GOTO exit;
		%END;

	%local num Nodealias i;
	%LET num = %numofobs(&ControlDataSet);

	%DO i = 1 %TO &num %BY 1;
		%let Nodealias = %obtomacro(&ControlDataSet, Alias, &i);

		%SYSLPUT _Icarus_temphold1=%BQUOTE(&DistVar) /remote=&NodeAlias;

rsubmit &NodeAlias;
	%nrstr(%symdel &_Icarus_temphold1);
	%nrstr(%symdel _Icarus_temphold1);
endrsubmit;
	%END;

	waitfor _ALL_
		%DO i = 1 %TO &num %BY 1;

	%obtomacro (&ControlDataSet,Alias,&i)
	&NodeAlias%STR( )
	%END;

	timeout=30;

	%IF &LocalSessionVar = Y %THEN
		%DO;
		%IF %symexist(&DistVar)=1 %THEN %DO;
			%symdel &DistVar;
			%END;
		
		%END;

%exit:

%mend icarus_distvardel;