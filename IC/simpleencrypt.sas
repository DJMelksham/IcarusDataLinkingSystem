

%macro simpleencrypt(DataSet=,Outdata=work.encrypted,EncryptVars=_DJM_NONE,Hashfunction=MD5,sd=12);

%local i numvars charred allvars var;

%IF %DSETVALIDATE(&Dataset)=0 %THEN
		%DO;
			%PUT ERROR: Data set &dataset does not exist;
			%PUT ERROR: Aborting Simple Encrypt...;
			%GOTO exit;
		%END;

%IF &EncryptVars=_DJM_NONE %THEN %DO;
%let EncryptVars=%varlistfromdset(&DataSet);
%END;
%ELSE %IF %varsindset(&DataSet,&EncryptVars)=0 %THEN %DO;
%PUT ERROR: Variables listed in EncryptVars are not found in the data set &Dataset;
%PUT ERROR: Aborting Simple Encrypt...;
%END;

%LET Numvars=%countwords(&EncryptVars,%STR( ));
%LET charred=%numstochars(&DataSet,&EncryptVars,&sd);

/******************************************************
ACTUAL CALCULATION PART
******************************************************/
Data &outdata(drop=&EncryptVars rename=(
%LET I=1;
%DO %WHILE (&I<=&numvars);
%LET var=%scan(&EncryptVars,&I,%STR( ));
_djm_&I%STR(=)&var%STR( )
%LET I=%EVAL(&I+1);
%END;
));
length 
%LET I=1;
%DO %WHILE (&I<=&numvars);
_djm_&i $ 32
%LET I=%EVAL(&I+1);
%END;
;
set &Dataset;
%LET I=1;
%DO %WHILE (&I<=&numvars);
%LET var=%scan(&charred,&I,%STR( ));
%IF &hashfunction=MD5 %THEN _djm_&i=put(MD5(&var),hex32.);;
%LET I=%EVAL(&I+1);
%END;

run;

%exit:

%mend simpleencrypt;
