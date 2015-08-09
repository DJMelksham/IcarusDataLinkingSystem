%macro genweight(MData=_DJM_NONE,
			UData=_DJM_NONE,
			MissMData=_DJM_NONE,
			MissUData=_DJM_NONE,
			outdata=work.Weightfile,
			Weighttype=1);
	%local i MProbVars UProbVars MissMProbVars MissUProbVars varnum Mvar Uvar MissMVar MissUVar outVar;
	%local RNProbVars1 RNProbVars2 RNProbVars3 RNProbVars4 NProbVars1 NProbVars2 NProbVars3 NProbVars4;

	/* Do some standard error checking depending upon the Weighttype entered */
	%IF &Weighttype^=1 AND &Weighttype^=2 AND &Weighttype^=3 AND &Weighttype^=4 %THEN
		%DO;
			%PUT ERROR: The Weighttype parameter must be equal to either 1, 2 or 3;
			%PUT ERROR: Aborting Weight Generation...;
			%GOTO exit;
		%END;

	%IF &weighttype^=4 %THEN
		%DO;
			%IF %DSETVALIDATE(&MData)=0 %THEN
				%DO;
					%PUT ERROR: M Probability Data Set &MData does not exist;
					%PUT ERROR: Aborting Weight Generation...;
					%GOTO exit;
				%END;
		%END;

	%IF %DSETVALIDATE(&UData)=0 %THEN
		%DO;
			%PUT ERROR: U Probability Data Set &UData does not exist;
			%PUT ERROR: Aborting Weight Generation...;
			%GOTO exit;
		%END;

	%IF &weighttype^=4 %THEN
		%DO;
			%let MProbVars=%varlistfromdset(&MData);
		%END;

	%let UProbVars=%varlistfromdset(&UData);

	%IF &MProbVars^=&UProbVars AND &weighttype^=4 %THEN
		%DO;
			%PUT ERROR: M Probability data set and U Probability data set contain different variables;
			%PUT ERROR: Aborting Weight Generation...;
			%GOTO exit;
		%END;

	%IF &weighttype^=4 %THEN
		%let varnum=%countwords(&MProbVars,%STR( ));
	%ELSE %let varnum=%countwords(&UProbVars,%STR( ));

	%IF &Weighttype=3 %THEN
		%DO;
			%IF (&MissMData^=_DJM_NONE AND &MissUData=_DJM_NONE) OR (&MissMData=_DJM_NONE AND &MissUData^=_DJM_NONE) %THEN
				%DO;
					%PUT ERROR: You cannot supply only one of MissMData and MissUData;
					%PUT ERROR: Either supply both, or none at all;
					%PUT ERROR: Aborting Weight Generator...;
					%GOTO exit;
				%END;

			%let MissMProbVars=%varlistfromdset(&MissMData);
			%let MissUProbVars=%varlistfromdset(&MissUData);

			%IF &MissMProbVars^=&MissUProbVars AND &MissMProbVars^=&MProbVars %THEN
				%DO;
					%PUT ERROR: Probability data sets contain different variables/different number of variables;
					%PUT ERROR: Aborting Weight Generation...;
					%GOTO exit;
				%END;
		%END;

	/* The three weighttype options are as follows:

	1: Missings are given a weight of zero. (requires M and U probs)
	2: Missings are treated as equivalent to disagreement. (requires M and U probs)
	3: Missings are calculated based upon the supplied values of MissMData and MissUData. (requires all 4)
	4: Only using U Probabilities. (only requires U probs)

	/*************************************************
	ACTUAL CALCULATIONS SECTION
	*************************************************/

	/* Weight type 1  */
	%IF &Weighttype=1 %THEN
		%DO;
			%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
			%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
			%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
			%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));

			Data &outdata(keep=&MProbVars);
				_djm_point=1;
				set &MData(rename=(&RNProbVars1)) point=_djm_point;
				set &UData(rename=(&RNProbVars2)) point=_djm_point;

				/* Disagreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&MProbVars,&I,%STR( ));
					&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Agreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Missing */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=0;
					%LET I=%EVAL(&I+1);
				%END;

				output;
				stop;
			run;

		%END;

	/* Weight type 2 */
	%ELSE %IF &Weighttype=2 %THEN
		%DO;
			%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
			%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
			%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
			%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));

			Data &outdata(keep=&MProbVars);
				_djm_point=1;
				set &MData(rename=(&RNProbVars1)) point=_djm_point;
				set &UData(rename=(&RNProbVars2)) point=_djm_point;

				/* Disagreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&MProbVars,&I,%STR( ));
					&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Agreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Missing */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&MProbVars,&I,%STR( ));
					&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;
				stop;
			run;

		%END;

	/* Weight type 3 calculations */
	%ELSE %IF &Weighttype=3 %THEN
		%DO;

			%let MProbVars=%varlistfromdset(&MData);
			%let UProbVars=%varlistfromdset(&UData);	
			%let MissMProbVars=%varlistfromdset(&MissMData);
			%let MissUProbVars=%varlistfromdset(&MissUData);
			%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
			%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
			%let NProbVars3=%repeaterandnum(_djm_MissM_Var,&varnum,%STR( ));
			%let NProbVars4=%repeaterandnum(_djm_MissU_Var,&varnum,%STR( ));
			%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
			%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
			%let RNProbVars3=%tvtdl(&MissMProbVars,&NProbVars3,%STR(=),%STR( ));
			%let RNProbVars4=%tvtdl(&MissUProbVars,&NProbVars4,%STR(=),%STR( ));

			Data &outdata(keep=&MProbVars);
				_djm_point=1;
				set &MData(rename=(&RNProbVars1)) point=_djm_point;
				set &UData(rename=(&RNProbVars2)) point=_djm_point;
				set &MissMData(rename=(&RNProbVars3)) point=_djm_point;
				set &MissUData(rename=(&RNProbVars4)) point=_djm_point;

				/* Disagreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&MProbVars,&I,%STR( ));
					&outvar=log((1-_djm_MVar&I-_djm_MissM_Var&I)/(1-_djm_UVar&I-_djm_MissU_Var&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Agreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Missing */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&MProbVars,&I,%STR( ));
					&outvar=log((_djm_MissM_Var&I)/(_djm_MissU_Var&I))/log(2);
					%LET I=%EVAL(&I+1);
				%END;

				output;
				stop;
			run;

		%END;

	/* Weight type 4 calculation */
	%ELSE %IF &Weighttype=4 %THEN
		%DO;
			%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
			%PUT &NProbVars2;
			%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
			%PUT &RNProbVars2;

			Data &outdata(keep=&UProbVars);
				_djm_point=1;
				set &UData(rename=(&RNProbVars2)) point=_djm_point;

				/* Disagreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=0;
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Agreement */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=log(1/_djm_UVar&I);
					%LET I=%EVAL(&I+1);
				%END;

				output;

				/* Missing */
				%let I=1;

				%DO %WHILE (&I<=&varnum);
					%let outvar=%scan(&UProbVars,&I,%STR( ));
					&outvar=0;
					%LET I=%EVAL(&I+1);
				%END;

				output;
				stop;
			run;

		%END;

	%exit:
%mend genweight;