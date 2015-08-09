%macro VorDset(indata);

	%local dthing vthing thing;

	%IF %SYSFUNC(exist(&indata)) %THEN
		%LET dthing=1;
	%ELSE %LET dthing=0;

	%IF %SYSFUNC(exist(&indata,VIEW)) %THEN
		%LET vthing=1;
	%ELSE %LET vthing=0;
	%LET thing=0;

	%IF &dthing=1 %THEN
		%LET thing=D;

	%IF &vthing=1 %THEN
		%LET thing=V;
	&thing
%mend VorDSet;

