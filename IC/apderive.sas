%macro apderive(DataSet=_DJM_NONE,
			LinkVarsA=_DJM_NONE,
			LinkVarsB=_DJM_NONE,
			OutVars=_DJM_NONE,
			Outdata=work.AgreementPattern,
			AdditionalKeepVars=_DJM_NONE,
			DorV=V,
			Case=3,
			Comptypes=_DJM_NONE,
			Compvals=_DJM_NONE);
	%local I J a_Var b_var comparison comp1 comp2;
	%local numcheck1 numcheck2 numcheck3 numcheck4 numcheck5;
	%local outty_var tempcheck;
	%let Comptypes=%UPCASE(&Comptypes);
	%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));

	/* Check that Case is equal to 2 or 3 */
	%IF &Case^=2 AND &Case^=3 %THEN
		%DO;
			%PUT ERROR: Case must be set equal to 2 or 3;
			%PUT ERROR: Case is current set to &Case;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	/* Validating the existance of the data set from which we are going to generate the agreement patterns*/
	%IF %dsetvalidate(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: &DataSet does not exist;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	/* Ensuring correct specification of the Linking Variables */
	%IF &LinkVarsA=_DJM_NONE OR &LinkVarsB=_DJM_NONE OR &OutVars=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply valid values for LinkVarsA, LinkVarsB;
			%PUT ERROR: and OutVars...;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	/* Check Linking Variables A exist in dset */
	%IF %varsindset(&DataSet,&LinkVarsA)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables listed;
			%PUT ERROR: in LinkVarsA does not exist in &DataSet;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	/* Check Linking Varaibles B exist in dset*/
	%IF %varsindset(&DataSet,&LinkVarsB)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables listed;
			%PUT ERROR: in LinkVarsB does not exist in &DataSet;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	%IF &AdditionalKeepVars^=_DJM_NONE %THEN
		%DO;
			%IF %varsindset(&DataSet,&AdditionalKeepVars)=0 %THEN
				%DO;
					%PUT ERROR: At least one of the Additional Keep Variables listed;
					%PUT ERROR: in AdditionalKeepVars does not exist in &DataSet;
					%PUT ERROR: Aborting derivation of agreement patterns...;
					%GOTO exit;
				%END;
		%END;
	%ELSE %let additionalkeepvars =;
	%LET numcheck1=%countwords(&LinkVarsA,%STR( ));
	%LET numcheck2=%countwords(&LinkVarsB,%STR( ));
	%LET numcheck3=%countwords(&Comptypes,%STR( ));
	%LET numcheck4=%countwords(&Compvals,%STR( ));
	%LET numcheck5=%countwords(&Outvars,%STR( ));

	/* Using transative properties to check number of all the variables are equal to each other */
	%IF &numcheck1^=&numcheck2 OR &numcheck2^=&numcheck3 OR &numcheck3^=&numcheck4 or &numcheck4^=&numcheck5 %THEN
		%DO;
			%PUT ERROR: CONFLICTING NUMBER OF PARAMETERS ENTERED.;
			%PUT ERROR: There were &numcheck1 LinkVarA members;
			%PUT ERROR: There were &numcheck2 LinkVarB members;
			%PUT ERROR: There were &numcheck3 Comptypes members;
			%PUT ERROR: There were &numcheck4 Compvals members;
			%PUT ERROR: There were &numcheck5 Outvars members;
			%PUT ERROR: Above parameters must all have the same number of members;
			%PUT ERROR: Aborting derivation of agreement patterns...;
			%GOTO exit;
		%END;

	%let I=1;

	%do %while(&I<=&numcheck4);
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

	/**************************************************************
	ACTUAL CALCULATION PART
	***************************************************************/
	Data &outdata(keep=&Outvars &AdditionalKeepVars) %IF &DorV=V %THEN /view=&outdata;;
		set &DataSet(keep=&LinkVarsA &LinkVarsB &AdditionalKeepVars);

		/* When we want only two possible states in our agreement patterns */
		%IF &Case=2 %THEN
			%DO;
				%let I=1;

				%do %while(&I<=&numcheck1);
					%let a_Var = %scan(&LinkVarsA,&I,%str( ));
					%let b_Var = %scan(&LinkVarsB,&I,%str( ));
					%let comparison = %scan(&Comptypes,&I,%str( ));
					%let comp1 = %scan(&Compvals,&I,%str( ));
					%let outty_Var = %scan(&OutVars,&I,%STR( ));
					%Put &comparison 2;

					%IF &comparison = E %THEN
						%DO;
							IF &a_Var^=&b_var THEN
								&outty_Var=0;
							ELSE IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=0;
							ELSE &outty_Var=1;
						%END;
					%ELSE %IF &comparison=WI %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=0;
							ELSE IF winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
								&outty_Var=0;
							ELSE &outty_Var=1;
						%END;
					%ELSE %IF &comparison=JA %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_Var=0;
							ELSE IF jaro(&a_Var,&b_Var)<&comp1 THEN
								&outty_Var=0;
							ELSE &outty_Var=1;
						%END;
					%ELSE %IF &comparison=HF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=0;
							ELSE &outty_var = Highfuzz(&a_Var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=GF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=0;
							ELSE &outty_var = Genfuzz(&a_Var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=LF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=0;
							ELSE &outty_var = Lowfuzz(&a_Var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=CL %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								&outty_var=0;
							ELSE IF complev(&a_var,&b_var)<&comp1 THEN
								&outty_var=1;
							ELSE &outty_var=0;
						%END;

					%let I = %eval(&I+1);
				%end;
			%END;

		/* When we want only three possible states in our agreement patterns */
		%ELSE %IF &Case=3 %THEN
			%DO;
				%let I=1;

				%do %while(&I<=&numcheck1);
					%let a_Var = %scan(&LinkVarsA,&I,%str( ));
					%let b_Var = %scan(&LinkVarsB,&I,%str( ));
					%let comparison = %scan(&Comptypes,&I,%str( ));
					%let comp1 = %scan(&Compvals,&I,%str( ));
					%let outty_Var = %scan(&OutVars,&I,%STR( ));

					%IF &comparison=E %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_var);
							ELSE IF &a_Var ^= &b_Var THEN
								&outty_Var = 0;
							ELSE &outty_Var=1;
						%END;
					%ELSE %IF &comparison=WI %THEN
						%DO;
							IF missing(&a_Var) or missing(&b_Var) then
								call missing(&outty_var);
							ELSE IF &a_Var=&b_Var then
								&outty_Var=1;
							ELSE IF Winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
								&outty_Var=0;
							ELSE &outty_var=1;
						%END;
					%ELSE %IF &comparison=JA %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_var);
							ELSE IF &a_Var=&b_Var THEN
								&outty_Var=1;
							ELSE IF Jaro(&a_Var,&b_Var)<&comp1 THEN
								&outty_Var=0;
							ELSE &outty_var=1;
						%END;
					%ELSE %IF &comparison=HF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_var);
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=1;
							ELSE &outty_var=highfuzz(&a_var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=GF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_var);
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=1;
							ELSE &outty_var=Genfuzz(&a_var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=LF %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_var);
							ELSE IF &a_Var=&b_Var THEN
								&outty_var=1;
							ELSE &outty_var=Lowfuzz(&a_var,&b_Var,&comp1);
						%END;
					%ELSE %IF &comparison=CL %THEN
						%DO;
							IF missing(&a_Var) OR missing(&b_Var) THEN
								call missing(&outty_Var);
							ELSE IF &a_Var=&b_Var THEN
								&outty_Var=1;
							ELSE IF Complev(&a_Var,&b_Var)<&Comp1 THEN
								&outty_Var=1;
							ELSE &outty_Var=0;
						%END;

					%let I = %eval(&I+1);
				%END;
			%END;
	run;

	%exit:
%mend apderive;