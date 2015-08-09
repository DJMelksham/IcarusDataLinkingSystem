%macro simpleevidence(DataSet=_DJM_NONE,
			IDA=_DJM_NONE,
			IDB=_DJM_NONE,
			WeightData=_DJM_NONE,
			Outdata=work.evidenced,
			DorV=V,
			Prefixa=,
			Prefixb=,
			Comptypes=_DJM_NONE,
			Compvals=_DJM_NONE,
			SumVar=TotalWeight,
			KeepNonSumVars=N);
	/************************************
	ERROR CHECKING AND ADMIN PART
	************************************/
	%local I J a_Var b_var comparison comp1 comp2;
	%local linkvars rnalinkvars rnblinkvars iclinkvars;
	%local icrnalinkvars icrnalinkvars;
	%local weightagree weightdisagree weightmissing;
	%local weighta weightd weightm;
	%local numcheck1 numcheck2 numcheck3;
	%local outty_var tempcheck;
	%local Case;
	%let Comptypes=%UPCASE(&Comptypes);
	%let DorV=%UPCASE(%SUBSTR(&DorV,1,1));
	%let KeepNonSumVars=%UPCASE(%SUBSTR(&KeepNonSumVars,1,1));

	/* Validating the existance of DataSetA */
	%IF %dsetvalidate(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: DataSet does not exist or was not supplied;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	/* Validating the existance of Weightdata */
	%IF %dsetvalidate(&WeightData)=0 %THEN
		%DO;
			%PUT ERROR: Weightdata does not exist or was not supplied;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	/* Check IDA and IDB exist in their respective dsets */
	%IF %varsindset(&DataSet,&IDA)=0 %THEN
		%DO;
			%PUT ERROR: ID Variable &IDA was not found on &DataSet;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	%IF %varsindset(&DataSet,&IDB)=0 %THEN
		%DO;
			%PUT ERROR: ID Variable &IDB was not found on &DataSet;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	/* Get linking variables from weight data set */
	%let linkvars=%varlistfromdset(&WeightData);
	%let rnalinkvars=%PL(&linkvars,&prefixa);
	%let rnblinkvars=%PL(&linkvars,&prefixb);
	%let icrnalinkvars=%tvtdl(&rnalinkvars,%PL(&rnalinkvars,_ic_),%STR(=),%STR( ));
	%let icrnblinkvars=%tvtdl(&rnblinkvars,%PL(&rnblinkvars,_ic_),%STR(=),%STR( ));

	/* Check Linking Variables exist in dsets */
	%IF %varsindset(&DataSet, &rnalinkvars)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables listed;
			%PUT ERROR: &rnalinkvars;
			%PUT ERROR: Does not exist on &DataSet;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	%IF %varsindset(&DataSet, &rnblinkvars)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables listed;
			%PUT ERROR: &rnblinkvars;
			%PUT ERROR: Does not exist on &DataSet;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	/* Access WeightData and populate the three weight macro variables */
	%LET weightdisagree=%obtomacro(&WeightData,&linkvars,1);
	%LET weightagree=%obtomacro(&WeightData,&linkvars,2);
	%LET weightmissing=%obtomacro(&WeightData,&linkvars,3);

	/* If comptypes and compvals are not populated, populate them with Es and 0s */
	%IF &comptypes=_DJM_NONE %THEN
		%DO;
			%LET comptypes = %repeater(E,%countwords(&Linkvars,%STR( )),%STR( ));
		%END;

	%IF &compvals=_DJM_NONE %THEN
		%DO;
			%LET compvals = %repeater(0,%countwords(&Linkvars,%STR( )),%STR( ));
		%END;

	/* Numchecks on the linkvars, comptypes, compvals, */
	%LET numcheck1=%countwords(&LinkVars,%STR( ));
	%LET numcheck2=%countwords(&Comptypes,%STR( ));
	%LET numcheck3=%countwords(&Compvals,%STR( ));

	/* Using transative properties to check number of all the variables are equal to each other */
	%IF &numcheck1^=&numcheck2 OR &numcheck2^=&numcheck3 %THEN
		%DO;
			%PUT ERROR: CONFLICTING NUMBER OF PARAMETERS ENTERED.;
			%PUT ERROR: There were &numcheck1 LinkVars members;
			%PUT ERROR: There were &numcheck2 Comptypes members;
			%PUT ERROR: There were &numcheck3 Compvals members;
			%PUT ERROR: Above parameters must all have the same number of members;
			%PUT ERROR: Aborting simple evidence macro...;
			%GOTO exit;
		%END;

	%let I=1;

	/* Do a check on whether compvals contains valid values */
	%do %while(&I<=&numcheck2);
		%let tempcheck = %SCAN(&Comptypes,&I,%STR( ));

		%IF &tempcheck ^= E AND &tempcheck ^= WI AND &tempcheck ^= JA AND &tempcheck ^= HF 
			AND &tempcheck ^= GF AND &tempcheck ^= LF AND &tempcheck ^= CL %THEN
			%DO;
				%PUT &tempcheck;
				%PUT ERROR: Compvals can only include the following:;
				%PUT ERROR: E,WI,JA,HF,GF,LF,CL;
				%PUT ERROR: Aborting apderive...;
				%GOTO exit;
			%END;

		%LET I = %EVAL(&I + 1);
	%END;

	/* Doing a check for efficiencies of missing and disagreement weights being the same */
	/* If they are the same, we can change the macro to operate in Case 2 mode */
	/* Otherwise it has to operate in Case 3 mode */
	%let I=1;
	%let tempcheck=0;

	%do %while(&I<=&numcheck2);
		%IF %QUOTE(%scan(&weightdisagree,&I,%STR( )))^=%QUOTE(%scan(&weightmissing,&I,%STR( ))) %THEN %DO;
			%LET tempcheck=1;
			%LET I=&numcheck2;
			%END;
		%LET I = %EVAL(&I + 1);
	%END;

	%IF &tempcheck=1 %THEN
		%LET Case=3;
	%ELSE %LET Case=2;

	/**************************************************************
	ACTUAL CALCULATION PART
	***************************************************************/
	Data &outdata(keep=&IDA &IDB &SumVar %IF &KeepNonSumVars=Y %THEN &Linkvars;) %IF &DorV=V %THEN /view=&outdata;;
		set &DataSet(keep=&IDA &IDB &rnalinkvars &rnblinkvars rename=(&icrnalinkvars &icrnblinkvars));

		/* When we want only two possible states in our agreement patterns */
		%IF &Case=2 %THEN
			%DO;
				%let I=1;

				%do %while(&I<=&numcheck1);
					%let a_Var = %scan(%PL(&rnalinkvars,_ic_),&I,%str( ));
					%let b_Var = %scan(%PL(&rnblinkvars,_ic_),&I,%str( ));
					%let comparison = %scan(&Comptypes,&I,%str( ));
					%let comp1 = %scan(&Compvals,&I,%str( ));
					%let outty_Var = %scan(&LinkVars,&I,%STR( ));
					%let weighta = %scan(&weightagree,&I,%STR( ));
					%let weightd = %scan(&weightdisagree,&I,%STR( ));
					%let weightm = %scan(&weightmissing,&I,%STR( ));

					%IF &comparison = E %THEN
						%DO;
							IF &a_Var^=&b_var THEN
								&outty_Var=&weightd;
							ELSE IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=&weightm;
							ELSE &outty_Var=&weighta;
						%END;
					%ELSE %IF &comparison=WI %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=&weightm;
							ELSE IF winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
								&outty_Var=&weightd;
							ELSE &outty_Var=&weighta;
						%END;
					%ELSE %IF &comparison=JA %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=&weightm;
							ELSE IF jaro(&a_Var,&b_Var)<&comp1 THEN
								&outty_Var=&weightd;
							ELSE &outty_Var=&weighta;
						%END;
					%ELSE %IF &comparison=HF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF Highfuzz(&a_Var,&b_Var,&comp1) = 0 then
								&outty_Var = &weightd;
							ELSE &outty_Var = &weighta;
						%END;
					%ELSE %IF &comparison=GF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF Genfuzz(&a_Var,&b_Var,&comp1) = 0 then
								&outty_Var = &weightd;
							ELSE &outty_Var = &weighta;
						%END;
					%ELSE %IF &comparison=LF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF Lowfuzz(&a_Var,&b_Var,&comp1) = 0 then
								&outty_Var = &weightd;
							ELSE &outty_Var = &weighta;
						%END;
					%ELSE %IF &comparison=CL %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF complev(&a_var,&b_var)>=&comp1 THEN
								&outty_var=&weightd;
							ELSE &outty_var=&weighta;
						%END;

					%let I = %eval(&I+1);
				%end;

				/* The part where we actually sum up the weights */
				&SumVar = 
					%LET I = 1;

				%do %while(&I<=&numcheck1);
					%scan(&LinkVars,&I,%STR( ))

					%IF &I ^= &numcheck1 %THEN
						%STR(+);
					%LET I = %EVAL(&I+1);
				%END;
				;
			%END;

		/* When we want only three possible states in our agreement patterns */
		%ELSE %IF &Case=3 %THEN
			%DO;
				%let I=1;

				%do %while(&I<=&numcheck1);
					%let a_Var = %scan(%PL(&rnalinkvars,_ic_),&I,%str( ));
					%let b_Var = %scan(%PL(&rnblinkvars,_ic_),&I,%str( ));
					%let comparison = %scan(&Comptypes,&I,%str( ));
					%let comp1 = %scan(&Compvals,&I,%str( ));
					%let outty_Var = %scan(&LinkVars,&I,%STR( ));
					%let weighta = %scan(&weightagree,&I,%STR( ));
					%let weightd = %scan(&weightdisagree,&I,%STR( ));
					%let weightm = %scan(&weightmissing,&I,%STR( ));

					%IF &comparison=E %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF &a_Var ^= &b_Var THEN
								&outty_Var = &weightd;
							ELSE &outty_Var=&weighta;
						%END;
					%ELSE %IF &comparison=WI %THEN
						%DO;
							IF missing(&a_Var) or missing(&b_Var) then
								&outty_var=&weightm;
							ELSE IF &a_Var=&b_Var then
								&outty_Var=&weighta;
							ELSE IF Winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
								&outty_Var=&weightd;
							ELSE &outty_var=&weighta;
						%END;
					%ELSE %IF &comparison=JA %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF &a_Var=&b_Var THEN
								&outty_Var=&weighta;
							ELSE IF Jaro(&a_Var,&b_Var)<&comp1 THEN
								&outty_Var=&weightd;
							ELSE &outty_var=&weighta;
						%END;
					%ELSE %IF &comparison=HF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=&weighta;
							ELSE IF highfuzz(&a_var,&b_Var,&comp1)=0 then
								&outty_var=&weightd;
							ELSE &outty_var=&weighta;
						%END;
					%ELSE %IF &comparison=GF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=&weighta;
							ELSE IF genfuzz(&a_var,&b_Var,&comp1)=0 then
								&outty_var=&weightd;
							ELSE &outty_var=&weighta;
						%END;
					%ELSE %IF &comparison=LF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=&weightm;
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=&weighta;
							ELSE IF lowfuzz(&a_var,&b_Var,&comp1)=0 then
								&outty_var=&weightd;
							ELSE &outty_var=&weighta;
						%END;
					%ELSE %IF &comparison=CL %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=&weightm;
							ELSE IF &a_Var=&b_Var THEN
								&outty_Var=&weighta;
							ELSE IF Complev(&a_Var,&b_Var)>=&Comp1 THEN
								&outty_Var=&weightd;
							ELSE &outty_Var=&weighta;
						%END;

					%let I = %eval(&I+1);
				%END;

				&SumVar = 
					%LET I = 1;

				%do %while(&I<=&numcheck1);
					%scan(&LinkVars,&I,%STR( ))

					%IF &I ^= &numcheck1 %THEN
						%STR(+);
					%LET I = %EVAL(&I+1);
				%END;
				;
			%END;
	run;

%exit:
%mend simpleevidence;