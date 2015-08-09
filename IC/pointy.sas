%macro pointy(PointData=_DJM_NONE,PointVarA=_DJM_NONE,PointVarB=_DJM_NONE,
			DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
			VarsA=_DJM_NONE,VarsB=_DJM_NONE,
			prefixa=,prefixb=,
			outdata=work.pointed,DorV=V);
	%local PointVars PLVarsA PLVarsB RNVarsA RNVarsB;

	/*************************************************
	ERROR CHECKING PART
	*************************************************/
	%IF &pointdata=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply a valid pointdata parameter for the Pointy Macro to function properly;
			%PUT ERROR: You have not done so.;
			%PUT ERROR: Aborting Pointy Macro...;
			%GOTO exit;
		%END;

	%IF %dsetvalidate(&pointdata)=0 %THEN
		%DO;
			%PUT ERROR: &pointdata does not appear to exist;
			%PUT ERROR: Aborting Pointy Macro...;
		%END;

	/* Check DataSetA and DataSetB have been supplied */
	%IF &DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply a valid DataSetA and DataSetB option for the Pointy Macro to function properly;
			%PUT ERROR: You have not done so.;
			%PUT ERROR: Aborting Pointy Macro...;
			%GOTO exit;
		%END;

	/* Check DataSetA exists */
	%ELSE
		%DO;
			%IF %dsetvalidate(&DataSetA)=0 %THEN
				%DO;
					%PUT ERROR: &DataSetA does not exist;
					%PUT ERROR: Aborting Pointy Macro...;
					%GOTO exit;
				%END;

			/* Check DataSetB exists */
			%IF %dsetvalidate(&DataSetB)=0 %THEN
				%DO;
					%PUT ERROR: &DataSetB does not exist;
					%PUT ERROR: Aborting Pointy Macro...;
					%GOTO exit;
				%END;
		%END;

	/* Check to see whether the PointVarA and PointVarB variables are set on the Pointfile/pointdata.
	If they aren't, and the Pointfile/pointdata has two or more variables, then the first variable is PointVarA,
	and the second variable is PointVarB.*/
	%IF &pointVarA=_DJM_NONE OR &pointVarB=_DJM_NONE %THEN
		%DO;
			%PUT NOTE: PointVarA and PointVarB were not supplied.  Attempting to use first two variables of &PointData;

			/* Get variables from pointdata, check that there are at least two. If there are, put the first two in PointVarA and PointVarB. */
			%let PointVars=%varlistfromdset(&pointdata);

			%IF %countwords(&Vars,%STR( ))>=2 %THEN
				%DO;
					%LET PointVarA=%SCAN(&Vars,1,%str( ));
					%LET PointVarB=%SCAN(&Vars,2,%str( ));
				%END;
			%ELSE
				%DO;
					%PUT ERROR: There are not two variables on &pointdata;
					%PUT ERROR: So we cannot automatically assign two variables as PointVarA and PointVarB;
					%PUT ERROR: Aborting Pointy Macro...;
				%END;
		%END;
	%ELSE
		%DO;
			/* Check if PointVarA and PointVarB are found in pointdata */
			%IF %varsindset(&pointdata,&PointVarA)=0 %THEN
				%DO;
					%PUT ERROR: &PointVarA was not found in &pointdata;
					%PUT ERROR: Aborting Pointy Macro...;
					%GOTO exit;
				%END;

			%IF %varsindset(&pointdata,&PointVarB)=0 %THEN
				%DO;
					%PUT ERROR: &PointVarB was not found in &pointdata;
					%PUT ERROR: Aborting Pointy Macro...;
					%GOTO exit;
				%END;
		%END;

	/* Check if PointVarA and PointVarB are found in DataSetA and DataSetB */
	%IF &VarsA=_DJM_NONE %THEN
		%DO;
			%LET VarsA=%varlistfromdset(&DatasetA);
		%END;
	%ELSE %IF %varsindset(&DataSetA,&VarsA)=0 %THEN
		%DO;
			%PUT ERROR: All variables were not found in &DataSetA;
			%PUT ERROR: Aborting Pointy Macro...;
			%GOTO exit;
		%END;

	%IF &VarsB=_DJM_NONE %THEN
		%DO;
			%LET VarsB=%varlistfromdset(&DatasetB);
		%END;
	%ELSE %IF %varsindset(&DataSetB,&VarsB)=0 %THEN
		%DO;
			%PUT ERROR: All variables were not found in &DataSetB;
			%PUT ERROR: Aborting Pointy Macro...;
			%GOTO exit;
		%END;

	/*************************************************
	ACTUAL CALCULATION PART
	*************************************************/
	%LET PLVarsA=%PL(&VarsA,&prefixa);
	%LET PLVarsB=%PL(&VarsB,&prefixb);
	%LET RNVarsA=%tvtdl(&VarsA,&PLVarsA,%STR(=),%STR( ));
	%LET RNVarsB=%tvtdl(&VarsB,&PLVarsB,%STR(=),%STR( ));

	Data &outdata %IF &DorV=V %THEN /view=&outdata;;
		do until(_djm_eof);
			set &pointdata(keep=&PointVarA &PointVarB rename=(&PointVarA=_djm_pointerA &PointVarB=_djm_pointerB)) end=_djm_eof;
			set &DataSetA(keep=&VarsA rename=(&RNVarsA)) point=_djm_pointerA;
			set &DataSetB(keep=&VarsB rename=(&RNVarsB)) point=_djm_pointerB;
			output;
		end;

		stop;
	run;

	%exit:
%mend pointy;