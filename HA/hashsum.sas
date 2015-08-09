%macro hashsum(		DataSet=_DJM_NONE,
					SumVar=_DJM_NONE,
					ClassVar=_DJM_NONE,
					OutSumVar=_djm_sum,
					DorV=D,
					Outdata=work.summed,exp=12
				);

%local QCClassVar;

%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let SumVar=%UPCASE(&SumVar);
%let ClassVar=%UPCASE(&ClassVar);

	/*****************************/
	/* Some initial error checks */
	/*****************************/
	/* Does DataSet exist? */
	%IF %DSETVALIDATE(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &Dataset does not exist;
			%PUT ERROR: Aborting Hash Sum...;
			%GOTO exit;
		%END;

%IF &SumVar=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply some variables to the SumVars parameter;
			%PUT ERROR: This lets the Hash Sum program know which variables to sum;
			%PUT ERROR: Aborting Hash Sum...;
			%GOTO exit;
		%END;

%IF &ClassVar=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply some variables to the ClassVar parameter;
			%PUT ERROR: This lets the Hash Sum program know which categories to sum for;
			%PUT ERROR: Aborting Hash Sum...;
			%GOTO exit;
		%END;

%IF %Varsindset(&DataSet,&Sumvar)=0 %THEN
				%DO;
					%PUT ERROR: The SumVar &Sumvar is not present in &DataSet;
					%PUT ERROR: Aborting Hash Sum...;
					%GOTO exit;
				%END;

%IF %countwords(&Sumvar,%STR( ))>1 %THEN %DO;
%PUT ERROR: You must only enter one SumVar;
%PUT ERROR: Aborting Hash Sum...;
%END;

%IF %Varsindset(&DataSet,&ClassVar)=0 %THEN
				%DO;
					%PUT ERROR: All ClassVar are not present in &DataSet;
					%PUT ERROR: Aborting Hash Sum...;
					%GOTO exit;
				%END;

	/*************************************************************************************************
 * BEGINNING OF ACTUAL HASHING PART ***************************************************************
 **************************************************************************************************/

%let QCClassVar=%QClist(&ClassVar);

Data &Outdata(keep=&ClassVar &outsumvar) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSet;

								dcl hash djmhash (/*dataset:"&DataSet",*/hashexp: &exp,suminc:"&SumVar");
								djmhash.definekey (&QCClassVar);
								djmhash.definedone();
								
								do while(not eof);
								set &dataset(keep=&ClassVar &SumVar) end=eof;
								djmhash.ref();
								end;

								declare hiter hi('djmhash');
								_iorc_ = hi.first();
								do while (_iorc_ = 0);
								djmhash.sum(sum: &outsumvar);
								output;
								_iorc_ = hi.next();
								end;

								stop;
							run;

%exit:


%mend hashsum;