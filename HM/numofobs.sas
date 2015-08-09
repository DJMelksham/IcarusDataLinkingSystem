%macro numofobs(data);
	%local dsid anobs whstmt counted rc;

	%IF %dsetvalidate(&data)=0 %THEN %DO;
		%PUT ERROR: &Data does not exist...;
		%PUT ERROR: Aborting numofobs macro...;
		%let counted = ERROR;
		%GOTO exit;
	%END;

	%let DSID = %sysfunc(open(&DATA., IS));

			%let anobs = %sysfunc(attrn(&DSID, ANOBS));
			%let whstmt = %sysfunc(attrn(&DSID, WHSTMT));

	%if &anobs = 1 AND &whstmt = 0 %then
		%let counted = %sysfunc(attrn(&DSID, NLOBS));
	%else
		%do;
			%if %sysfunc(getoption(msglevel)) = I %then
			%let counted = 0;

			%do %while (%sysfunc(fetch(&DSID)) = 0);
				%let counted = %eval(&counted + 1);
			%end;
		%end;

	%let rc = %sysfunc(close(&DSID));

	%exit:
	&counted

%mend numofobs;

