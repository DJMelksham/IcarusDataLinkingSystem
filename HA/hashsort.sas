

%macro hashsort(DataSet=_DJM_NONE,
					SortVars=_DJM_NONE,
					DorV=D,
					AorD=A,
					Outdata=work.sorted,exp=12,
					TagSort=N);

%local DataVars QCDataVars QCVars;

%let TagSort=%SUBSTR(%UPCASE(&Tagsort),1,1);
%let AorD=%SUBSTR(%UPCASE(&AorD),1,1);
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Sortvars=%UPCASE(&Sortvars);
%let DataVars=%varlistfromdset(&DataSet);

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

%IF &Sortvars=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply some variables to the SortVar parameter;
			%PUT ERROR: This lets the Hash Sort program know which variables to sort on;
			%PUT ERROR: Aborting Hash Sort...;
			%GOTO exit;
		%END;


	/* If Sortvars has been supplied, are they in the data set */

%IF %Varsindset(&DataSet,&Sortvars)=0 %THEN
				%DO;
					%PUT ERROR: All Sortvars are not present in &DataSet;
					%PUT ERROR: Aborting Hash Sort...;
					%GOTO exit;
				%END;


%let DataVars=%varlistfromdset(&DataSet);
%let QCDataVars=%QClist(&DataVars);
%let QCVars=%QClist(&Sortvars);
/*************************************************************************************************
* BEGINNING OF ACTUAL HASHING PART ***************************************************************
**************************************************************************************************/

%IF &TAGSORT=N %THEN %DO;

Data &Outdata (drop= _djm_n _djm_i)%IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSet;

								dcl hash djmhash (dataset:"&DataSet",hashexp: &exp,multidata:"Y",ordered:"&AorD");
								djmhash.definekey (&QCVars);
								djmhash.definedata (&QCDataVars);
								djmhash.definedone();

								declare hiter hi('djmhash');
								
								_djm_n=djmhash.num_items-1;
								hi.first();
								do _djm_i=1 to _djm_n;
								output;
								hi.next();
								end;
								output;

								stop;
							run;

%END;
%ELSE %IF &TAGSORT=Y %THEN %DO;

Data &Outdata (drop= _djm_n _djm_i)%IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSet;
								length _DJM_ID 8;

								dcl hash djmhash (hashexp: &exp,multidata: "Y",ordered:"&AorD");
								
								djmhash.definekey (&QCVars);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSet(keep=&Sortvars) end=_djm_a_eof;
								djmhash.add();
								end;

								declare hiter hi('djmhash');
								
								_djm_n=djmhash.num_items-1;
								hi.first();
								
								do _djm_i=1 to _djm_n;
								set &Dataset point=_DJM_id;
								output;
								hi.next();
								end;
								set &Dataset point=_DJM_id;
								output;

								stop;
							run;

%END;

%exit:

%mend hashsort;