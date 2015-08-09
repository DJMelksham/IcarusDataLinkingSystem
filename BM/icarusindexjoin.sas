%macro icarusindexjoin(IndexedDataSet=_DJM_NONE, 
			IndexedDataSetVars=_DJM_NONE,
			PrefixIndexedDataSet=,
			OtherDataSet=_DJM_NONE,
			OtherDataSetVars=_DJM_NONE,
			PrefixOtherDataSet=,
			ControlDataSet=_DJM_NONE,
			Index1Root=work.Icarusindex1_,
			Index2Root=work.Icarusindex2_,
			FirstIndexNumber=_DJM_NONE,
			LastIndexNumber=_DJM_NONE,
			Outdata=work.IcarusIndexJoined,
			DorV=V,
			ExcludeMissings=N,
			exp=12);
	%local i Vars;
	%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
	%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMissings,1,1));
	%LET IndexeddataSetVars = %UPCASE(&IndexedDataSetVars);
	%LET OtherdataSetVars = %UPCASE(&OtherDataSetVars);
	%LET PrefixIndexedDataSet = %UPCASE(&PrefixIndexedDataSet);
	%LET PrefixOtherDataSet = %UPCASE(&PrefixOtherDataSet);

	/**************************************/
	/* ERROR CHECKING AND MAIN-SETUP PART */
	/**************************************/
	/* Checking for the existence of IndexedDataSet*/
	%IF %DSETVALIDATE(&IndexedDataSet)=0 %THEN
		%DO;
			%PUT ERROR: IndexedDataSet does not exist;
			%PUT ERROR: Aborting IcarusIndexJoin...;
			%GOTO exit;
		%END;

	/* Checking for the existence of OtherDataSet*/
	%IF %DSETVALIDATE(&OtherDataSet)=0 %THEN
		%DO;
			%PUT ERROR: Other data set does not exist;
			%PUT ERROR: Aborting IcarusIndexJoin...;
			%GOTO exit;
		%END;

	/* If a ControlDataSet has been specified, do the following checks and setups...*/
	%IF &ControlDataSet^=_DJM_NONE %THEN
		%DO;
			/* Check for existance of Control Data Set */
			%IF %DSETVALIDATE(&ControlDataSet)=0 %THEN
				%DO;
					%PUT ERROR: Control Data Set does not exist;
					%PUT ERROR: Aborting IcarusIndexJoin...;
					%GOTO exit;
				%END;

			%LET FirstIndexNumber = 1;
			%LET LastIndexNumber = %numofobs(&ControlDataSet);
			%LET Vars = %varlistfromdset(&ControlDataSet);

			/* Check that vars in control data set are also in the Indexed Data Set */
			%IF %Varsindset(&IndexedDataSet,&Vars)=0 %THEN
				%DO;
					%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
					%PUT ERROR: Aborting IcarusIndexJoin...;
					%GOTO exit;
				%END;

			%IF &LastIndexNumber = 0 %THEN
				%DO;
					%PUT ERROR: ControlDataSet contains no observations;
					%PUT ERROR: Aborting IcarusIndexJoin...;
					%GOTO exit;
				%END;

			/* We call icarusindexdset macro to create the indexes if a control set has been supplied*/
			%icarusindexdset(DataSet=&IndexedDataSet,
				ControlDataset=&ControlDataSet,
				Index1Root=&Index1Root,
				Index2Root=&Index2Root,
				ExcludeMissings=&ExcludeMissings,
				exp=&exp);
		%END;

	/* If a Control Data Set has not been specified, we do these checks */
	%ELSE
		%DO;
			%IF &FirstIndexNumber = _DJM_NONE OR &LastIndexNumber = _DJM_NONE %THEN
				%DO;
					%PUT ERROR: If not specifying a control data set;
					%PUT ERROR: User must supply FirstIndexNumber and LastIndexNumber;
					%PUT ERROR: Aborting IcarusIndexJoin...;
					%GOTO exit;
				%END;

			%IF &FirstIndexNumber > &LastIndexNumber %THEN
				%DO;
					%PUT ERROR: FirstIndexNumber must be less than LastIndexNumber;
					%PUT ERROR: Aborting IcarusIndexJoin...;
					%GOTO exit;
				%END;

			%DO I = &FirstIndexNumber %TO &LastIndexNumber;
				%IF %DSETVALIDATE(&Index1Root.&i)=0 %THEN
					%DO;
						%PUT ERROR: &Index1Root.&i does not exist;
						%PUT ERROR: Aborting IcarusIndexJoin...;
						%GOTO exit;
					%END;

				%IF %DSETVALIDATE(&Index2Root.&i)=0 %THEN
					%DO;
						%PUT ERROR: &Index2Root.&i does not exist;
						%PUT ERROR: Aborting IcarusIndexJoin...;
						%GOTO exit;
					%END;
			%END;
		%END;

	/***************************************************/
	/* CREATE VARIABLES FOR PROGRAMMING PART           */
	/***************************************************/
	/* Get all the variables worth keeping for the indexed data set */
	%local keepvarsA renamevarsA keepvarsB renamevarsB OutVarsA OutVarsB;

	%IF &OtherDataSetVars = _DJM_NONE %THEN
		%LET OtherDataSetVars = %varlistfromdset(&OtherDataSet);

	%IF &IndexeddataSetVars = _DJM_NONE %THEN
		%LET Indexeddatasetvars = %varlistfromdset(&IndexedDataSet);

	/* Process to populate the various variables that I will use later in the macro.*/
	/* Keepvars are the variables that will be coming in from both of the original variables */
	/* Renamevars are those same variables with the respective prefixes added */
	/* OutVars are the prefixed variables that will be kept after output */
	%let keepVarsA =;
	%let renameVarsA =;
	%let keepVarsB =;
	%let renameVarsB =;

	%DO I = &FirstIndexNumber %TO &LastIndexNumber;
		%let keepVarsA = %Uniquewords(&keepVarsA %varlistfromdset(&index1Root.&i));
	%END;

	%let keepVarsA = %removewordfromlist(_djm_end, %removewordfromlist(_djm_start, &KeepVarsA));
	%let KeepVarsB = &keepVarsA;
	%let keepVarsA = %Uniquewords(&keepVarsA &IndexedDataSetVars);
	%let renamevarsA = %PL(&keepVarsA,&PrefixIndexedDataSet);
	%let keepVarsB = %Uniquewords(&keepVarsB &OtherDataSetVars);
	%let OutVarsA = %PL(&IndexedDataSetVars,&PrefixIndexedDataSet);
	%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);

	/* Get all the variables worth keeping for the other data set */
	/*********************************************************/
	/* ACTUAL WORK PART                                      */
	/*********************************************************/

	Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
		length _ic__djm_start 8 _ic__djm_end 8 _ic__djm_rc1 8 _ic__djm_rc2 8 _djm_pointer 8 _djm_index1pointer 8;

		IF _N_ = 0 then
			set &IndexedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,_ic_),%STR(=),%STR( ))));

		IF _N_ = 1 then
			do;
				call missing(_ic__djm_start,_ic__djm_end,_djm_pointer,_djm_index1pointer, _ic__djm_rc1, _ic__djm_rc2);
				%DO I = &FirstIndexNumber %TO &LastIndexNumber;
					%HashWriter(Hashname=_djm_iij&i,	
						DataSet=&Index1Root.&i,
						DataVars=_djm_start _djm_end,
						KeyVars=%removewordfromlist(_djm_end, %removewordfromlist(_djm_start, %varlistfromdset(&index1Root.&i))),
						addprefix=_ic_,
						removeprefix=_DJM_NONE,
						ExcludeMissings=&ExcludeMissings,
						exp=&exp,
						MultiData=N);
				%END;

				/* Tracking Hash Creation */
				declare hash _djm_thash(hashexp:&exp, multidata:"N");
				_djm_thash.defineKey("_djm_pointer");
				_djm_thash.definedone();
			end;

		/* Load record from the sequentially accessed data set */
		set &OtherDataSet(keep=&KeepVarsB rename=(%tvtdl(&KeepVarsB,%PL(&KeepVarsB,&PrefixOtherDataSet),%STR(=),%STR( ))));

		/* Set macro loop to retrieve records and implement tracking hash */
		%local releventkey;

		%DO I = &FirstIndexNumber %TO &LastIndexNumber;
			%LET releventkey = %removewordfromlist(_djm_end, %removewordfromlist(_djm_start, %varlistfromdset(&index1Root.&i)));
			%LET releventkey = %PL(&releventkey,&PrefixOtherDataSet);
			%LET releventkey = %tvtdl(%repeater(%STR(Key: ),%countwords(&releventkey,%STR( ))),&releventkey,%STR( ),%STR(,));
			_ic__djm_rc1 = _djm_iij&i..find(&releventkey);

			if _ic__djm_rc1 = 0 then
				do;
					do _djm_index1pointer = _ic__djm_start to _ic__djm_end by 1;
						set &index2Root.&i point = _djm_index1pointer;

						/* Code for first hash check, trackin hash will be empty, so can add pointer without checks */

						%IF &I = &FirstIndexNumber %THEN %DO;
								_djm_thash.add();
								set &IndexedDataSet(keep=&Indexeddatasetvars rename=(%tvtdl(&IndexedDataSetVars,%PL(&IndexedDataSetVars,&PrefixIndexedDataSet),%STR(=),%STR( )))) point = _djm_pointer;
								output;
						%END;
						/* Code for following hash checks, tracking hash will now possible have some members, so need to check */
						%ELSE %IF &I ^= &FirstIndexNumber %THEN %DO;
						_iorc_ = _djm_thash.check();
						if _iorc_ ^= 0 then
							do;
								_djm_thash.add();
								set &IndexedDataSet(keep=&Indexeddatasetvars rename=(%tvtdl(&IndexedDataSetVars,%PL(&IndexedDataSetVars,&PrefixIndexedDataSet),%STR(=),%STR( )))) point = _djm_pointer;
								output;
							end;
						%END;
					end;
				end;
		%END;

		/* Clear the tracking hash ready for the next record */
		_djm_thash.clear();
	run;

	%exit:
%mend icarusindexjoin;