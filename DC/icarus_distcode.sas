%macro icarus_distcode(ControlDataset=,
			Codedir=,
			Codename=,
			Wait=Y,
			timeout=30);

	%local myoplist oplist totallist;
	%let myoplist = Alias RWork IcarusGerminate;
	%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
	%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
	%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
	%let totallist = &myoplist &oplist;

/*	%IF %SUBSTR(&Codedir,%length(&Codedir),1)^=/ OR %SUBSTR(&Codedir,%LENGTH(&Codedir),1)^=\ %THEN %DO;*/
/*	%LET Codedir = &Codedir./;*/
/*	%END;*/

%IF %dsetvalidate(&ControlDataSet)=0 %THEN %DO;
	%PUT ERROR: &ControlDataSet does not exist.;
	%PUT ERROR: Aborting icarus_distcode macro...;
	%GOTO exit;
	%END;

	%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN %DO;
	%PUT ERROR: &ControlDataSet does not meet the requirements of an;
	%PUT ERROR: icarus_connect control data set;
	%PUT ERROR: Aborting icarus_distcode macro...;
	%GOTO exit;
	%END;

	%local num Nodealias i;

	%let Wait = %UPCASE(%SUBSTR(&Wait,1,1));
	%LET num = %numofobs(&ControlDataset);

	%DO i = 1 %TO &num %BY 1;
		%let Nodealias = %obtomacro(&ControlDataset, Alias, &i);

		%SYSLPUT _Icarus_temphold1=%BQUOTE(&Codedir) /remote=&NodeAlias;
		%SYSLPUT _Icarus_temphold2=%BQUOTE(&Codename) /remote=&NodeAlias;
rsubmit &NodeAlias;

	proc upload infile="&_Icarus_temphold1.&_Icarus_temphold2" outfile="%sysfunc(pathname(work))/&_Icarus_temphold2";
	run;

	%include "%sysfunc(pathname(work))/&_Icarus_temphold2" /lrecl=500;
	%nrstr(%symdel _Icarus_temphold1);
	%nrstr(%symdel _Icarus_temphold2);
endrsubmit;
	%END;

	%IF &Wait=Y %THEN
		%DO;
			waitfor _ALL_
				%DO i = 1 %TO &num %BY 1;

			%obtomacro (&ControlDataSet,Alias,&i)
			&NodeAlias%STR( )
		%END;

	timeout=&timeout;
%END;

%exit:
%mend icarus_distcode;