%macro djm_oap_bigwclause(dset);
	%local number numberm1 i varlist varlist2 whereclause;
	%let number = %numofobs(&dset);
	
	%let i = 1;

	%DO %WHILE (&i <= &number);
		%let varlist = %varkeeplistdset(&dset,&i);
		
		%IF &varlist ^= %STR() %THEN
			%DO;
				%let whereclause = (%STR(NOT)(%termlistpattern(&varlist,1,%STR( = ),%STR( AND ))));
				&whereclause

				%IF (&i < &number) %THEN %STR( AND );
			%END;

		%LET i = %EVAL(&i + 1);
	%END;
%mend djm_oap_bigwclause;
