%macro plainblocking(	DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
			BlockVarsA=_DJM_NONE,BlockVarsB=_DJM_NONE,
			VarsA=_DJM_NONE,VarsB=_DJM_NONE,
			prefixa=a_,prefixb=b_,behaviour=1,exp=12,
			outdata=work.blocked,DorV=V,
			Excludemissings=Y);
	%local cartesian;
	%let cartesian = N;

	/************************************************
	ERROR CHECKING SECTION
	************************************************/

	/* Error Checking and Administration for Data sets */
	%IF (&DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE) %THEN
		%DO;
			%PUT ERROR: You must enter both Data Set A and Data Set B;
			%PUT ERROR: You cannot enter just one;
			%PUT ERROR: If both are the same, feel free to supply the same data set for both parameters;
			%PUT ERROR: Aborting the Plain Blocking Macro...;
			%GOTO exit;
		%END;

	/* Check DataSetA exists */
	%IF %dsetvalidate(&DataSetA)=0 %THEN
		%DO;
			%PUT ERROR: &DataSetA does not exist;
			%PUT ERROR: Aborting Plain Blocking Macro...;
			%GOTO exit;
		%END;

	/* Check DataSetB exists */
	%IF %dsetvalidate(&DataSetB)=0 %THEN
		%DO;
			%PUT ERROR: &DataSetB does not exist;
			%PUT ERROR: Aborting Plain Blocking Macro...;
			%GOTO exit;
		%END;

	/* Error checking and Administraion for BlockVars*/
	%IF &BlockVarsA=_DJM_NONE AND &BlockVarsB=_DJM_NONE %THEN
		%DO;
			%LET cartesian = Y;
			%let behaviour = 2;
			%LET Excludemissings = N;
		%END;
	%ELSE %IF (&BlockVarsA=_DJM_NONE OR &BlockVarsB=_DJM_NONE) %THEN
		%DO;
			%PUT ERROR: You must enter both BlockVars A and BlockVars B;
			%PUT ERROR: You cannot enter just one;
			%PUT ERROR: Aborting the Plain Blocking Macro...;
			%GOTO exit;
		%END;
	%ELSE %IF &BlockVarsA^=&BlockVarsB %THEN
		%DO;
			%IF %countwords(&BlockVarsA,%STR( ))^=%countwords(&BlockVarsB,%STR( )) %THEN
				%DO;
					%PUT ERROR: A different number of variables have been specified in BlockVarsA and BlockVarsB;
					%PUT ERROR: Aborting the Plain Blocking Macro...;
					%GOTO exit;
				%END;
		%END;

	/* Check BlockVarsA exists in DataSetA if its not _DJM_NONE */
	/* Check BlockVarsB exists in DataSetB if its not _DJM_NONE*/
	%IF &BlockVarsA^=_DJM_NONE AND &BlockVarsB^=_DJM_NONE %THEN
		%DO;
			%IF %varsindset(&DataSetA,&BlockVarsA)=0 %THEN
				%DO;
					%PUT ERROR: At least one of the blocking variables does not exist on &DataSetA;
					%PUT ERROR: Aborting Plain Blocking Macro...;
					%GOTO exit;
				%END;

			%IF %varsindset(&DataSetB,&BlockVarsB)=0 %THEN
				%DO;
					%PUT ERROR: At least one of the blocking variables does not exist on &DataSetB;
					%PUT ERROR: Aborting Plain Blocking Macro...;
					%GOTO exit;
				%END;
		%END;

	/* autofill vars if they are not supplied */
	%IF &VarsA=_DJM_NONE %THEN
		%DO;
			%LET VarsA=%varlistfromdset(&DataSetA);
		%END;

	%IF &VarsB=_DJM_NONE %THEN
		%DO;
			%LET VarsB=%varlistfromdset(&DataSetB);
		%END;

	/* Check VarsA exists in DataSetA */
	%IF %varsindset(&DataSetA,&VarsA)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables does not exist on &DataSetA;
			%PUT ERROR: Aborting Plain Blocking Macro...;
			%GOTO exit;
		%END;

	/* Check VarsB exists in DataSetB*/
	%IF %varsindset(&DataSetB,&VarsB)=0 %THEN
		%DO;
			%PUT ERROR: At least one of the Linking variables does not exist on &DataSetB;
			%PUT ERROR: Aborting Plain Blocking Macro...;
			%GOTO exit;
		%END;

	/********************************************
	SECTION FOR ACTUAL OPERATION
	*********************************************/

	/* If the behaviour option is set to 1, then we will use the HashJoin Algorithm to 
	construct the blocked data set */
	%IF &behaviour=1 %THEN
		%DO;
			%HashJoin(DataSetA=&DataSetA,DataSetB=&DataSetB,JoinVarsA=&BlockVarsA,JoinVarsB=&BlockVarsB,DataVarsA=&VarsA,DataVarsB=&VarsB,exp=&exp,outdata=&outdata,DorV=&DorV,prefixA=&prefixA,prefixB=&prefixB,Excludemissings=&Excludemissings,jointype=IJ
				);
		%END;

	/* Else, if the behaviour option is set to 2 or 3, then we'll simply rely on regular SQL instead */
	%ELSE %IF &behaviour=2 %THEN
		%DO;

			PROC SQL;
				%IF &DorV=D %THEN
					CREATE TABLE &Outdata AS;
				%ELSE %IF &DorV=V %THEN
					CREATE VIEW &Outdata AS;
				SELECT %tvtdl(%PL(&VarsA,a.),%PL(&VarsA,&prefixa),%STR( AS ) ,%STR(,)),%tvtdl(%PL(&VarsB,b.),%PL(&VarsB,&prefixb),%STR( AS ),%STR(,))
					FROM &DataSetA as a, &DataSetB as b

					%IF &cartesian=N %THEN
						%DO;
							WHERE %tvtdl(%PL(&BlockVarsA,a.),%PL(&BlockVarsB,b.),%STR(=),%STR( AND )) %IF &Excludemissings=Y %THEN AND %termlistpattern(%PL(&BlockVarsA,a.),IS NOT MISSING,%STR( ),%STR( AND ));
						%END;
					;
			QUIT;

		%END;

	%exit:
%mend plainblocking;