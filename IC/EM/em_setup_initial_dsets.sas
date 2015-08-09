%macro em_setup_initial_dsets(Linkvars=,
							mstart=_DJM_NONE,
							ustart=_DJM_NONE,
							mmstart=_DJM_NONE,
							mustart=_DJM_NONE,
							model=3,
							P_hatInitial=);

	data work._djm_estimates work._djm_maximisation(keep= P_hat %pl(&Linkvars,m_) %pl(&Linkvars,u_) 
	%IF &MODEL=3 %THEN %pl(&Linkvars,mm_) %pl(&Linkvars,mu_); 
		);
		length converge $6;
		Iteration=0;
		Epsilon=1;
		P_hat=&P_hatInitial;
		Converge='no';

		%tvtdl(%pl(&Linkvars,m_),&mstart,%STR(=),%STR(;));
		%tvtdl(%pl(&Linkvars,u_),&ustart,%STR(=),%STR(;));

		/* Additional Variables if the 3 Prob model is being selected */

		%IF &model=3 %THEN
			%DO;
				%tvtdl(%pl(&Linkvars,mm_),&mmstart,%STR(=),%STR(;));
				%tvtdl(%pl(&Linkvars,mu_),&mustart,%STR(=),%STR(;));
			%END;
	run;

%mend em_setup_initial_dsets;
