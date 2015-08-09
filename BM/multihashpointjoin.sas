%macro multihashpointjoin(HashedDataSet=_DJM_NONE, 
			HashedDataSetVars=_DJM_NONE,
			PrefixHashedDataSet=b_,
			OtherDataSet=_DJM_NONE,
			OtherDataSetVars=_DJM_NONE,
			PrefixOtherDataSet=a_,
			ControlDataSet=_DJM_NONE,
			Indexviewroot=work.mhpjindex,
			Outdata=work.mhpjoined,
			DorV=V,
			ExcludeMissings=N,
			exp=12);

	%local i Vars Viewvars;
	%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
	%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMissings,1,1));
	%LET HashedDataSetVars = %UPCASE(&HashedDataSetVars);
	%LET OtherdataSetVars = %UPCASE(&OtherDataSetVars);
	%LET PrefixHashedDataSet = %UPCASE(&PrefixHashedDataSet);
	%LET PrefixOtherDataSet = %UPCASE(&PrefixOtherDataSet);

	/**************************************/
	/* ERROR CHECKING AND MAIN-SETUP PART */
	/**************************************/
	/* Checking for the existence of HashedDataSet*/
	%IF %dsetvalidate(&HashedDataSet)=0 %THEN
		%DO;
			%PUT ERROR: HashedDataSet does not exist;
			%PUT ERROR: Aborting multihashjoin...;
			%GOTO exit;
		%END;

	/* Checking for the existence of OtherDataSet*/
	%IF %dsetvalidate(&OtherDataSet)=0 %THEN
		%DO;
			%PUT ERROR: Other data set does not exist;
			%PUT ERROR: Aborting multihashjoin...;
			%GOTO exit;
		%END;
	
	%IF &ControlDataSet = _DJM_NONE %THEN %DO;
			%PUT ERROR: Must supply a control data set;
			%PUT ERROR: Aborting multihashjoin...;
			%GOTO exit;
	%END;

	/* If a ControlDataSet has been specified, do the following checks and setups...*/
	%IF &ControlDataSet^=_DJM_NONE %THEN
		%DO;
			/* Check for existance of Control Data Set */
			%IF %dsetvalidate(&ControlDataSet)=0 %THEN
				%DO;
					%PUT ERROR: Control Data Set does not exist;
					%PUT ERROR: Aborting multihashjoin...;
					%GOTO exit;
				%END;

			%LET Vars = %varlistfromdset(&ControlDataSet);

			/* Check that vars in control data set are also in the Hashed Data Set */
			%IF %Varsindset(&HashedDataSet,&Vars)=0 %THEN
				%DO;
					%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
					%PUT ERROR: Aborting multihashjoin...;
					%GOTO exit;
				%END;
		%END;

	/***************************************************/
	/* CREATE VARIABLES FOR PROGRAMMING PART           */
	/***************************************************/
	/* Get all the variables worth keeping for the indexed data set */
	%local keepvarsA renamevarsA keepvarsB renamevarsB OutVarsA OutVarsB;

	%IF &OtherDataSetVars = _DJM_NONE %THEN
		%LET OtherDataSetVars = %varlistfromdset(&OtherDataSet);

	%IF &HashedDataSetVars = _DJM_NONE %THEN
		%LET HashedDataSetvars = %varlistfromdset(&HashedDataSet);

	/* Process to populate the various variables that I will use later in the macro.*/
	/* Keepvars are the variables that will be coming in from both of the original variables */
	/* Renamevars are those same variables with the respective prefixes added */
	/* OutVars are the prefixed variables that will be kept after output */
	%let keepVarsA =;
	%let renameVarsA =;
	%let keepVarsB =;
	%let renameVarsB =;

	%DO I = 1 %TO %numofobs(&ControlDataSet);
		%let keepVarsA = %Uniquewords(&keepVarsA %varkeeplistdset(&ControlDataSet,&I));
	%END;


	%let KeepVarsB = &keepVarsA;
	%let keepVarsA = %Uniquewords(&keepVarsA &HashedDataSetVars);
	%let keepVarsA = %Uniquewords(%UPCASE(&keepVarsA));
	%let renamevarsA = %PL(&keepVarsA,&PrefixHashedDataSet);
	%let keepVarsB = %Uniquewords(%UPCASE(&keepVarsB &OtherDataSetVars));
	%let OutVarsA = %PL(&HashedDataSetVars,&PrefixHashedDataSet);
	%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);

/**************************************************************/
/* Creating the views in which point information is contained */
/**************************************************************/
	
	%DO I = 1 %TO %numofobs(&ControlDataSet);
	%let Viewvars = %varkeeplistdset(&ControlDataSet,&I);
	 Data &Indexviewroot.&i %IF &ExcludeMissings=Y %THEN (where=(%termlistpattern(&Viewvars, %STR(IS NOT MISSING),%STR( ),%STR( AND )))); /view=&Indexviewroot.&i;
		length _djm_mhjpoint 8;
		set &HashedDataSet(keep=&ViewVars);
		_djm_mhjpoint = _N_;
	 run;
	%END;
	
	/*********************************************************/
	/* ACTUAL WORK PART                                      */
	/*********************************************************/

	Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
		length _ic__djm_rc1 8 _ic__djm_rc2 8 _ic__djm_mhjpoint 8;

		IF _N_ = 0 then
			set &HashedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,_ic_),%STR(=),%STR( ))));

		IF _N_ = 1 then
			do;
				call missing(_ic__djm_rc1, _ic__djm_rc2, _ic__djm_mhjpoint);
				%DO I = 1 %TO %numofobs(&ControlDataSet) %BY 1;
					%HashWriter(Hashname=_djm_iij&i,	
						DataSet=&Indexviewroot.&i,
						DataVars=_djm_mhjpoint,
						KeyVars=%UPCASE(%varkeeplistdset(&ControlDataSet,&I)),
						addprefix=_ic_,
						removeprefix=_DJM_NONE,
						ExcludeMissings=&ExcludeMissings,
						exp=&exp,
						MultiData=Y)
				%END;

				/* Tracking Hash Creation */
				declare hash _djm_thash(hashexp:&exp, multidata:"N");
				_djm_thash.defineKey("_ic__djm_mhjpoint");
				_djm_thash.definedone();
			end;

		/* Load record from the sequentially accessed data set */
		set &OtherDataSet(keep=&KeepVarsB rename=(%tvtdl(&KeepVarsB,%PL(&KeepVarsB,&PrefixOtherDataSet),%STR(=),%STR( ))));

		/* Set macro loop to retrieve records and implement tracking hash */
		%local releventkey;

		%DO I = 1 %TO %numofobs(&ControlDataSet);
			%LET releventkey = %varkeeplistdset(&ControlDataSet,&I);
			%LET releventkey = %PL(&releventkey,&PrefixOtherDataSet);
			%LET releventkey = %tvtdl(%repeater(%STR(Key: ),%countwords(&releventkey,%STR( ))),&releventkey,%STR( ),%STR(,));

						/* Code for first hash check, trackin hash will be empty, so can add pointer without checks */

						%IF &I = 1 %THEN %DO;
								_iorc_ = _djm_iij&i..find(&releventkey);
								do while (_iorc_=0);
								set &HashedDataSet(keep=&HashedDataSetVars rename=(%tvtdl(&HashedDataSetVars,%PL(&HashedDataSetVars,&PrefixHashedDataSet),%STR(=),%STR( )))) point = _ic__djm_mhjpoint;
								output;
								_djm_thash.add();
								_iorc_ = _djm_iij&i..find_next();
								end;
						%END;
						/* Code for following hash checks, tracking hash will now possibly have some members, so need to check it */
						%ELSE %IF &I ^= 1 %THEN %DO;
						_iorc_ = _djm_iij&i..find(&releventkey);
								do while (_iorc_=0);
								
								_ic__djm_rc1 = _djm_thash.check();
								if _ic__djm_rc1 ^= 0 then do;
									set &HashedDataSet(keep=&HashedDataSetVars rename=(%tvtdl(&HashedDataSetVars,%PL(&HashedDataSetVars,&PrefixHashedDataSet),%STR(=),%STR( )))) point = _ic__djm_mhjpoint;
									_ic__djm_rc2 = _djm_thash.add();
									output;
									end;
								_iorc_ = _djm_iij&i..find_next();
								end;
							
						%END;
		%END;

		/* Clear the tracking hash ready for the next record */
		_djm_thash.clear();
	run;

	%exit:
%mend multihashpointjoin;