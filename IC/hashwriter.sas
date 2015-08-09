/* Remove prefix removes a prefix from the actual variables on the file, not from the variables listed in the macro call.
This lets you use standard variable names even when there may be a prefix attached to the variables on a certain data set,
but the variables will be renamed to those without the prefix.

Add prefix adds a prefix to the actual variables on the file, which hopefully correspond to the variables supplied to the macro
anyway.

If you are in that rare case where you want to remove a prefix from the variables on the data set, 
and then replace it with another one, you would need to supply both the removeprefix and the addprefix arguments.*/
%macro hashwriter(Hashname=,	
			DataSet=,
			DataVars=,
			KeyVars=,
			addprefix=_DJM_NONE,
			removeprefix=_DJM_NONE,
			ExcludeMissings=Y,
			exp=16,
			MultiData=Y);
	/**************************/
	/* Calculations section   */
	/**************************/

	%local p_KeyVars pq_KeyVars pqc_KeyVars p_DataVars pq_DataVars nmiss_KeyVars nmiss_DataSet uniqueVars Var1 Var2 Var3 Var4;
	%LET MultiData=%UPCASE(%SUBSTR(&MultiData,1,1));
	%LET ExcludeMissings=%UPCASE(%SUBSTR(&ExcludeMissings,1,1));

	/* Settings when no prefix is added or removed. */
	%IF &addprefix=_DJM_NONE AND &removeprefix=_DJM_NONE %THEN
		%DO;
			%LET p_KeyVars=&KeyVars;
			%LET pq_KeyVars=%QUOTElist(&p_KeyVars);
			%LET pqc_KeyVars=%QClist(&p_KeyVars);
			%LET pqc_DataVars=%QCList(&DataVars);
			%let Var1=%UniqueWords(&DataVars &Keyvars);
			%let Var3=%termlistpattern(&KeyVars,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
		%END;

	/* Settings when a prefix is removed */
	%ELSE %IF &removeprefix^=_DJM_NONE AND &addprefix=_DJM_NONE %THEN
		%DO;
			%LET pqc_KeyVars=%QCList(&KeyVars);
			%LET pqc_DataVars=%QCList(&DataVars);
			%let Var1=%UniqueWords(%PL(&DataVars &Keyvars,&removeprefix));
			%let Var2=%tvtdl(&Var1,%RPL(&Var1,&removeprefix),%STR(=),%STR( ));
			%let Var3=%termlistpattern(&KeyVars,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
		%END;

	/* Settings when a prefix is added */
	%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
		%DO;
			%LET pqc_KeyVars=%QCList(%PL(&Keyvars,&addprefix));
			%LET pqc_DataVars=%QCList(%PL(&DataVars,&addprefix));
			%let Var1=%UniqueWords(&DataVars &Keyvars);
			%let Var2=%tvtdl(&Var1,%PL(&Var1,&addprefix),%STR(=),%STR( ));
			%let Var3=%termlistpattern(%PL(&KeyVars,&addprefix),%STR(IS NOT MISSING),%STR( ),%STR( AND ));
		%END;

	/* Settings when a prefix removed and then added*/
	%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
		%DO;
			%LET pqc_KeyVars=%QCList(%PL(&Keyvars,&addprefix));
			%LET pqc_DataVars=%QCList(%PL(&Datavars,&addprefix));
			%let Var1=%UniqueWords(%PL(&DataVars &Keyvars,&removeprefix));
			%let Var2=%tvtdl(&Var1,%PL(%RPL(&Var1,&removeprefix),&addprefix),%STR(=),%STR( ));
			%let Var3=%termlistpattern(%PL(&KeyVars,&addprefix),%STR(IS NOT MISSING),%STR( ),%STR( AND ));
		%END;

	/***********************/
	/* Actual Work Section */
	/***********************/
	%IF &ExcludeMissings=N %THEN
		%DO;
			%IF &removeprefix=_DJM_NONE and &addprefix=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1)", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
		%END;
	%ELSE
		%DO;
			%IF &removeprefix=_DJM_NONE and &addprefix=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
			%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
			dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
		%END;
	;
	&hashname..definekey(&pqc_KeyVars);

	%IF &DataVars^=%STR() %THEN %DO;
		&hashname..definedata(&pqc_DataVars);
		%END;
	&hashname..definedone();
%mend HashWriter;