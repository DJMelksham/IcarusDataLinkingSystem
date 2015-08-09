%macro hashdistinct	(		DataSet=_DJM_NONE,
							Vars=_DJM_NONE,
							DorV=D,
							Outdata=work.distinct,exp=12
				);

%local QCVars;

%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);

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

/*************************************************************************************************
 * BEGINNING OF ACTUAL HASHING PART ***************************************************************
 **************************************************************************************************/

%let QCVars=%QClist(&Vars);

Data &Outdata(keep=&Vars) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSet;

								dcl hash djmhash (dataset:"&DataSet",hashexp: &exp);
								djmhash.definekey (&QCVars);
								djmhash.definedone();

								declare hiter hi('djmhash');
								_iorc_ = hi.first();
								do while (_iorc_ = 0);
								output;
								_iorc_ = hi.next();
								end;

								stop;
							run;

%exit:

%mend hashdistinct;