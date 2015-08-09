/*************************************************************
EXPECTATION STEP COMPILATION FOR EM 2 STATE 
**************************************************************/

%macro expect_2_compile	(LinkVar=,dataset=_DJM_NONE, countvar=_DJM_NONE);

	data work._djm_expectation (keep = &countvar g1 g0 %pl(&LinkVar,g1T_) %pl(&LinkVar,g0T_)) /PGM=work._djm_expectation;
		set &dataset;

		if _n_ = 1 then
			set work._djm_maximisation;

		/**************;
		*Define arrays;
		**************/;
		/*Parameter arrays*/;
		array MProb {*} %pl(&LinkVar,m_);
		array UProb {*} %pl(&LinkVar,u_);

		/*Comparison vectors*/;
		array Theta {*}  &LinkVar;

		/*Arrays for intermediate variables (summed in proc means)*/;
		array g1_Theta{*} %pl(&LinkVar, g1T_);
		array g0_Theta{*} %pl(&LinkVar, g0T_);

		/*Calculate Expected Gj*/;
		TotMTerm = 1;
		TotUTerm = 1;

		do i = 1 to dim(MProb);
			TotMTerm = TotMTerm * ((MProb[i]**Theta[i])*((1-MProb[i])**(1-Theta[i])));
			TotUTerm = TotUTerm * ((UProb[i]**Theta[i])*((1-UProb[i])**(1-Theta[i])));
		end;

		TotMTerm = TotMTerm;
		TotUTerm = TotUTerm;

		*Final calculation of g data;
		g1 = P_hat*TotMterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
		g0 = (1-P_hat)*TotUterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);

		do i = 1 to dim(Theta);
			g1_Theta[i] = g1*Theta[i];
			g0_Theta[i] = g0*Theta[i];
		end;
	run;

%mend expect_2_compile;
