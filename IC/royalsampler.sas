%macro royalsampler(DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
				VarsA=_DJM_NONE,VarsB=_DJM_NONE,
				prefixa=,prefixb=,
				outdata=work.RoyalSampled,DorV=V,
				NumRecords=1000000);

				%local DsetAcount DsetBcount PointVars PLVarsA PLVarsB RNVarsA RNVarsB;
/*************************************************
ERROR CHECKING PART
*************************************************/
		
	/* Check DataSetA and DataSetB have been supplied */
	%IF &DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply a valid DataSetA and DataSetB option for the Royal Sampler Macro to function properly;
			%PUT ERROR: You have not done so.;
			%PUT ERROR: Aborting Royal Sampler Macro...;
			%GOTO exit;
		%END;

	/* Check DataSetA exists */
	%ELSE %DO;
		%IF %dsetvalidate(&DataSetA)=0 %THEN
		%DO;
			%PUT ERROR: &DataSetA does not exist;
			%PUT ERROR: Aborting Royal Sampler Macro...;
			%GOTO exit;
		%END;

	/* Check DataSetB exists */
	%IF %dsetvalidate(&DataSetB)=0 %THEN
		%DO;
			%PUT ERROR: &DataSetB does not exist;
			%PUT ERROR: Aborting Royal Sampler Macro...;
			%GOTO exit;
		%END;
	%END;
	
	/* Check if VarsA and VarsB are found in DataSetA and DataSetB, and obtain them if not supplied */

%IF  &VarsA=_DJM_NONE %THEN %DO;
%LET VarsA=%varlistfromdset(&DatasetA);
%END;

%IF  &VarsB=_DJM_NONE %THEN %DO;
%LET VarsB=%varlistfromdset(&DatasetB);
%END;

%IF %varsindset(&DataSetA,&VarsA)=0 %THEN
		%DO;
			%PUT ERROR: All variables were not found in &DataSetA;
			%PUT ERROR: Aborting Royal Sampler Macro...;
			%GOTO exit;
		%END;
	%IF %varsindset(&DataSetB,&VarsB)=0 %THEN
		%DO;
			%PUT ERROR: All variables were not found in &DataSetB;
			%PUT ERROR: Aborting Royal Sampler Macro...;
			%GOTO exit;
		%END;


/*************************************************
ACTUAL CALCULATION PART
*************************************************/

%LET PLVarsA=%PL(&VarsA,&prefixa); 
%LET PLVarsB=%PL(&VarsB,&prefixb); 
%LET RNVarsA=%tvtdl(&VarsA,&PLVarsA,%STR(=),%STR( ));
%LET RNVarsB=%tvtdl(&VarsB,&PLVarsB,%STR(=),%STR( ));
%LET DsetACount=%numofobs(&DataSetA);
%LET DsetBCount=%numofobs(&DataSetB);


Data &outdata(drop=_djm_counter) %IF &DorV=V %THEN /view=&outdata;;

do _djm_counter = 1 to &NumRecords;
_djm_pointerA=FLOOR(RAND("UNIFORM")*&DsetACount)+1;
_djm_pointerB=FLOOR(RAND("UNIFORM")*&DsetBCount)+1;
set &DataSetA(keep=&VarsA rename=(&RNVarsA)) point=_djm_pointerA;
set &DataSetB(keep=&VarsB rename=(&RNVarsB)) point=_djm_pointerB;
output;
end;
stop;
run;

%exit:
%mend royalsampler;