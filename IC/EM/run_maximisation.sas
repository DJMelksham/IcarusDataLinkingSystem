%macro run_maximisation(linkvar=,model=3,countvar=);

	proc summary data=work._djm_expectation;
		var g1 g0 %pl(&LinkVar, g1T_) %pl(&linkvar, g0T_)
			%IF &model=3 %THEN
			%DO;
				%pl(&linkvar, g1mT_) %pl(&linkvar, g0mT_)
			%END;
		;
		weight &countvar;
		output out = work._djm_maximisation (drop = _type_ _freq_) sum =;
	run;

	data pgm=work._djm_maximisation;
	run;

	data pgm=work._djm_estimates;
	run;

%mend run_maximisation;
