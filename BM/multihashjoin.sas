%macro multihashjoin(HashedDataSet=_DJM_NONE, 
			HashedDataSetVars=_DJM_NONE,
			PrefixHashedDataSet=b_,
			HashDataSetIDVar=_DJM_NONE,
			OtherDataSet=_DJM_NONE,
			OtherDataSetVars=_DJM_NONE,
			PrefixOtherDataSet = a_,
			ControlDataSet=_DJM_NONE,
			Outdata=work.multihashjoined,
			DorV=V,
			ExcludeMissings=N,
			exp=12);

	%local i Vars;
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

	%IF &HashDataSetIDVar=_DJM_NONE %THEN %DO;
		%PUT ERROR: You must supply a HashDataSetIDVar;
		%PUT ERROR: So the algorithm knows how to identify records from the hashdataset;
		%PUT ERROR: that have already been compared to each record in the other;
		%PUT ERROR: data set.  Aborting multihashjoin...;
		%GOTO exit;
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
	%let keepVarsA = %Uniquewords(%UPCASE(&keepVarsA &HashDataSetIDVar));
	%let renamevarsA = %PL(&keepVarsA,&PrefixHashedDataSet);
	%let keepVarsB = %Uniquewords(%UPCASE(&keepVarsB &OtherDataSetVars));
	%let OutVarsA = %PL(&HashedDataSetVars,&PrefixHashedDataSet);
	%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);

	/* Get all the variables worth keeping for the other data set */
	/*********************************************************/
	/* ACTUAL WORK PART                                      */
	/*********************************************************/

	Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
		length _ic__djm_rc1 8 _ic__djm_rc2 8;

		IF _N_ = 0 then
			set &HashedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,&PrefixHashedDataSet),%STR(=),%STR( ))));

		IF _N_ = 1 then
			do;
				call missing(_ic__djm_rc1, _ic__djm_rc2);
				%DO I = 1 %TO %numofobs(&ControlDataSet) %BY 1;
					%HashWriter(Hashname=_djm_iij&i,	
						DataSet=&HashedDataSet,
						DataVars=&HashedDataSetVars,
						KeyVars=%UPCASE(%varkeeplistdset(&ControlDataSet,&I)),
						addprefix=&PrefixHashedDataSet,
						removeprefix=_DJM_NONE,
						ExcludeMissings=&ExcludeMissings,
						exp=&exp,
						MultiData=Y)
				%END;

				/* Tracking Hash Creation */
				declare hash _djm_thash(hashexp:&exp, multidata:"N");
				_djm_thash.defineKey("&PrefixHashedDataSet.&HashDataSetIDVar");
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
								output;
								_djm_thash.add();
								_iorc_ = _djm_iij&i..find_next();
								end;
						%END;
						/* Code for following hash checks, tracking hash will now possible have some members, so need to check */
						%ELSE %IF &I ^= 1 %THEN %DO;
						_iorc_ = _djm_iij&i..find(&releventkey);
								do while (_iorc_=0);
								
								_ic__djm_rc1 = _djm_thash.check();
								if _ic__djm_rc1 ^= 0 then do;
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
%mend multihashjoin;