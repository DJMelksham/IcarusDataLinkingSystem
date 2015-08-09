/* I do not claim to be the  author of the original macro, 
Indeed I believe it can be gotten from the SAS website.

However, I have made some significant changes and updates. 

Included now are explicit local variables. 

Keyword arguments rather than positional arguments are now supplied for greater flexibility.

The option to return variables in open code as a macro variable, or it will
place the directory and the files into a data set (say if there are too many to fit
into a variable, or you don't care about data step boundaries).

-Damien John Melksham
*/
%macro filesindir(dir=,ext=Y,extension=sas7bdat,datasetflag=N,dataset=work.files,pathvar=Path,filevar=File,extvar=Extension,delimiter=%STR( ));
	%local rc did filrf memcnt i name ext result v1 v2 v3;
	%let ext=%UPCASE(%SUBSTR(&ext,1,1));
	%let datasetflag=%UPCASE(%SUBSTR(&Datasetflag,1,1));
	%let filrf=mydir;

	/* Assigns the fileref of mydir to the directory and opens the directory */
	%let rc=%sysfunc(filename(filrf,&dir));
	%let did=%sysfunc(dopen(&filrf));

	/* Returns the number of members in the directory */
	%let memcnt=%sysfunc(dnum(&did));

	/*****************************************
	Path to take if dataset flag is NOT set
	*****************************************/
	%IF &Datasetflag=N %THEN
		%DO;
			/* Loops through entire directory */
			%do i = 1 %to &memcnt;

				/* If ext=Y then do this branch */
				%IF &ext=Y %THEN
					%DO;
						/* Returns the extension from each file */
						%let name=%qscan(%qsysfunc(dread(&did,&i)),-1,.);

						/* Checks to see if file contains an extension */
						%if %qupcase(%qsysfunc(dread(&did,&i))) ne %qupcase(&name) %then
							%do;
								/* Checks to see if the extension matches the parameter value */
								/* If condition is true prints the full name to the log       */
								%if (%superq(extension) ne %STR() and %qupcase(&name) = %qupcase(&extension)) or                                                                       
									(%superq(extension) = %STR() and %superq(name) ne %STR()) %then
									%do;
										%IF &result=%STR() %THEN
											%let result=%qsysfunc(dread(&did,&i));
										%ELSE %LET result=&result.&delimiter.%qsysfunc(dread(&did,&i));
									%end;
							%END;
					%end;
				%ELSE
					%DO;
						%IF &i=1 %THEN
							%let result=%qsysfunc(dread(&did,&i));
						%ELSE %LET result=&result.&delimiter.%qsysfunc(dread(&did,&i));
					%END;
			%end;

			&result
		%END;

	/*****************************************
	Path to take if dataset flag is set
	*****************************************/
	%ELSE
		%DO;
			/* Loops through entire directory */
			Data &Dataset;
				%let v1=;
				%let v2=0;
				%let v3=0;

				%DO i=1 %to &memcnt;
					%let v1=%length(%qscan(%qsysfunc(dread(&did,&i)),1,.));

					%IF %superq(v1)>&v2 %THEN
						%LET v2=%superq(v1);
					%let v1=%length(%SYSFUNC(STRIP(%qscan(%qsysfunc(dread(&did,&i)),-1,.))));

					%IF %superq(v1)>&v3 %THEN
						%LET v3=%superq(v1);
				%END;

				length &pathvar $ %length(&dir) &fileVar $ &v2 &extVar $ &v3;

				%do i = 1 %to &memcnt;

					/* If ext=Y then do this branch */
					%IF &ext=Y %THEN
						%DO;
							/* Returns the extension from each file */
							%let name=%qscan(%qsysfunc(dread(&did,&i)),-1,.);

							/* Checks to see if file contains an extension */
							%if %qupcase(%qsysfunc(dread(&did,&i))) ne %qupcase(&name) %then
								%do;
									/* Checks to see if the extension matches the parameter value */
									/* If condition is true prints the full name to the log       */
									%if (%superq(extension) ne %STR() and %qupcase(&name) = %qupcase(&extension)) or                                                                       
										(%superq(extension) = %STR() and %superq(name) ne %STR ()) %then
										%do;
											&pathVar="&dir";
											&fileVar="%qscan(%qsysfunc(dread(&did,&i)),1,.)";
											&extVar="%superq(name)";
											output;
										%end;
								%end;
						%END;
					%ELSE %do i = 1 %to &memcnt;
					&pathVar="&dir";
					&fileVar="%qscan(%qsysfunc(dread(&did,&i)),1,.)";
					&extVar="%qscan(%qsysfunc(dread(&did,&i)),-1,.)";

					%IF %qscan(%qsysfunc(dread(&did,&i)),1,.)=%qscan(%qsysfunc(dread(&did,&i)),-1,.) %THEN

						if &fileVar=&extVar then
							call missing (&extvar);;
						output;
				%END;
		%end;

	stop;
			run;

%END;

			/* Closes the directory */
			%let rc=%sysfunc(dclose(&did));
%mend filesindir;

/* First parameter is the directory of where your files are stored. */
/* Second parameter is the extension you are looking for.           */
/* Leave 2nd paramater blank if you want a list of all the files.   */
/*%filesindir(dir=\\corp\PeopleDfs\melkda\My Documents\SASDB\,ext=N,Datasetflag=Y);*/