%macro icarus_germinate(NodeAlias=_DJM_NONE,
						Icaruslocation=&_Icarus_installation);

						%local temphold localcode ;
						%global _IC_germstatus;
						%let _IC_germstatus=0;

%SYSLPUT _Icarus_temphold1=%BQUOTE(&Icaruslocation.icarus_install.sas) /remote=&NodeAlias;

rsubmit &NodeAlias. connectwait=YES;

proc upload infile="&_Icarus_temphold1" outfile="%sysfunc(pathname(work))/icarus_install.sas"; run;
%include "%sysfunc(pathname(work))/icarus_install.sas";
%icarus_install(Location=%sysfunc(pathname(work)));
%nrstr(%symdel _Icarus_temphold1);
%NRSTR(%SYSRPUT _IC_germstatus = %dsetvalidate(work.icarus_functions));
endrsubmit;

waitfor &NodeAlias timeout=30;

%IF &SYSRC^=0 %THEN %DO;
%PUT ERROR: Timeout while waiting for Icarus to germinate on &NodeAlias;
%PUT ERROR: There is a good chance the germination has failed;
%END;
%ELSE %IF &_IC_germstatus^=1 %THEN %DO;
%PUT ERROR: It appears that the germination has failed on &NodeAlias;
%END;
%ELSE %IF &_IC_germstatus=1 %THEN %DO;
%PUT NOTE: ICARUS GERMINATED ON %UPCASE(&NodeAlias);
%END;

%IF %SYMEXIST(_IC_germstatus) %THEN %SYMDEL _IC_germstatus;

%mend icarus_germinate;