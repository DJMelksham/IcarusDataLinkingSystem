%macro hashcount(   DataSet=_DJM_NONE,
					Vars=_DJM_NONE,
					CountVar=_DJM_count,
					DorV=D,
					Outdata=work.counted,exp=12);


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
			%PUT ERROR: Aborting Hash Sort...;
			%GOTO exit;
		%END;

%IF &Vars=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply some variables to the SortVar parameter;
			%PUT ERROR: This lets the Hash Sort program know which variables to sort on;
			%PUT ERROR: Aborting Hash Sort...;
			%GOTO exit;
		%END;


	/* If Vars has been supplied, are they in the data set */

%IF %Varsindset(&DataSet,&Vars)=0 %THEN
				%DO;
					%PUT ERROR: All Sortvars are not present in &DataSet;
					%PUT ERROR: Aborting Hash Sort...;
					%GOTO exit;
				%END;

				%let QCVars=%QClist(&Vars);
/**************************************************************
 * BEGINNING OF ACTUAL HASHING PART *
***************************************************************/

Data &Outdata(keep=&Vars &CountVar) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSet;
								

								dcl hash djmhash (/*dataset:"&DataSet"*/hashexp: &exp,suminc:'_djm_counter');
								djmhash.definekey (&QCVars);
								djmhash.definedone();
								
								_djm_counter=1;
								do while(not eof);
								set &dataset(keep=&Vars) end=eof;
								djmhash.ref();
								end;

								declare hiter hi('djmhash');
								_iorc_ = hi.first();
								do while (_iorc_ = 0);
								djmhash.sum(sum: &CountVar);
								output;
								_iorc_ = hi.next();
								end;

								stop;
							run;

%exit:

%mend hashcount;