/*************************************************************
EXPECTATION STEP COMPILATION FOR EM 3 STATE 
**************************************************************/
%macro expect_3_compile	(LinkVar=,dataset=_DJM_NONE,countvar=_DJM_NONE);

	data  work._djm_expectation (keep = &countvar g1 g0 %PL(&LinkVar,g1T_) 
											%PL(&LinkVar,g0T_) 
											%PL(&LinkVar,g1mT_) 
											%PL(&LinkVar,g0mT_) ) /PGM=work._djm_expectation;
		set &dataset;

		if _n_ = 1 then
			set work._djm_maximisation;

		/**************
		*Define arrays
		**************/
		/*Parameter arrays*/
		array MProb {*} %PL(&LinkVar, m_);
		array UProb {*} %PL(&LinkVar, u_);
		array MissingMProb {*} %PL(&LinkVar, mm_);
		array MissingUProb {*} %PL(&LinkVar, mu_);

		/*Comparison vectors*/
		array Theta {*}  &LinkVar;

		/*Arrays for intermediate variables (summed in proc means)*/
		array g1_Theta{*} %PL(&LinkVar, g1T_);
		array g0_Theta{*} %PL(&LinkVar, g0T_);
		array g1miss_Theta{*} %PL(&LinkVar, g1mT_);
		array g0miss_Theta{*} %PL(&LinkVar, g0mT_);

		*Calculate Expected Gj;
		TotMTerm = 1;
		TotUTerm = 1;

		do i = 1 to dim(MProb);
			IF Theta[i]=0 THEN
				DO;
					TotMTerm = TotMTerm * (1-MProb[i]-MissingMProb[i]);
					TotUTerm = TotUTerm * (1-UProb[i]-MissingUProb[i]);
				END;

			IF Theta[i]=1 THEN
				DO;
					TotMTerm = TotMTerm * MProb[i];
					TotUTerm = TotUTerm * UProb[i];
				END;

			IF missing(Theta[i]) THEN
				DO;
					TotMTerm = TotMTerm * MissingMProb[i];
					TotUTerm = TotUTerm * MissingUProb[i];
				END;
		end;

		*Final calculation of g data;
		g1 = P_hat*TotMterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
		g0 = (1-P_hat)*TotUterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);

		do i = 1 to dim(Theta);
			IF Theta[i]=0 THEN
				DO;
					g1_Theta[i] = 0;
					g0_Theta[i] = 0;
					g1miss_Theta[i] = 0;
					g0miss_Theta[i] = 0;
				END;
			ELSE IF Theta[i]=1 THEN
				DO;
					g1_Theta[i] = g1;
					g0_Theta[i] = g0;
					g1miss_Theta[i] = 0;
					g0miss_Theta[i] = 0;
				END;
			ELSE IF missing(Theta[i]) THEN
				DO;
					g1_Theta[i] = 0;
					g0_Theta[i] = 0;
					g1miss_Theta[i] = g1;
					g0miss_Theta[i] = g0;
				END;
		end;
	run;

%mend expect_3_compile;
