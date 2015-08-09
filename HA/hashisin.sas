%macro hashisin	(		DataSet=_DJM_NONE,
							Vars=_DJM_NONE,
							InDataSet=_DJM_NONE,
							InVars=_DJM_NONE,
							DorV=D,
							Outdata=work.IsIn,exp=12
				);

%local CLVars QCInVars;

%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);
%IF &InVars=_DJM_NONE %THEN %LET InVars=&Vars;

	/*****************************/
	/* Some initial error checks */
	/*****************************/
	/* Does DataSet exist? */
	%IF %DSETVALIDATE(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &Dataset does not exist;
			%PUT ERROR: Aborting Hash Distinct...;
			%GOTO exit;
		%END;

%IF &Vars=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply some variables to the Vars parameter;
			%PUT ERROR: This lets the Hash Distinct program know which variables you are interested in;
			%PUT ERROR: Aborting Hash Distinct...;
			%GOTO exit;
		%END;


%IF %Varsindset(&DataSet,&Vars)=0 %THEN
				%DO;
					%PUT ERROR: The Variables: &Vars are not present in &DataSet;
					%PUT ERROR: Aborting Hash Distinct...;
					%GOTO exit;
				%END;

%IF %Varsindset(&InDataSet,&InVars)=0 %THEN
				%DO;
					%PUT ERROR: The Variables: &Vars are not present in &DataSet;
					%PUT ERROR: Aborting Hash Distinct...;
					%GOTO exit;
				%END;

/*************************************************************************************************
 * BEGINNING OF ACTUAL HASHING PART ***************************************************************
 **************************************************************************************************/

%let CLVars=%Commalist(&Vars);
%let QCInVars=%QClist(&InVars);


Data &Outdata(keep=&Vars) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &InDataSet(keep=&InVars);

								dcl hash djmhash (dataset:"&InDataSet",hashexp: &exp);
								djmhash.definekey (&QCInVars);
								djmhash.definedone();

								do until (_djm_eof);
								set &DataSet end=_djm_eof;
								_iorc_=djmhash.find(key: &CLVars);
								if _iorc_=0 then do;
								output;
								djmhash.remove(key:&CLVars);
								end;
								end;
								stop;
							run;

%exit:

%mend hashisin;