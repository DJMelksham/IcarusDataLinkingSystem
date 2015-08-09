/************************************************************* 
THE MACRO THAT COMPILES THE MAXIMISATION STEP FOR 3 STEP
**************************************************************/
%macro maximise_3_compile(linkVar=,EpsConverge=);

	data _djm_maximisation (keep =  %pl(&LinkVar, m_)
		%pl(&LinkVar, u_)
		%pl(&LinkVar, mm_) 
		%pl(&LinkVar, mu_)
		P_hat) /pgm=work._djm_maximisation;
		set work._djm_maximisation;

		*Parameter arrays;
		array MProb {*}  %pl(&LinkVar, m_);
		array UProb {*} %pl(&LinkVar, u_);
		array MissingMProb {*} %pl(&LinkVar, mm_);
		array MissingUProb {*} %pl(&LinkVar, mu_);
		array g1_Theta[*] %pl(&LinkVar, g1T_);
		array g0_Theta[*]%pl(&LinkVar, g0T_);
		array g1miss_Theta{*} %pl(&LinkVar, g1mT_);
		array g0miss_Theta{*} %pl(&LinkVar, g0mT_);

		*Calculate M and U Probability estimates for this iteration;
		do i = 1 to dim(MProb);
			MProb[i] = g1_Theta[i]/g1;
			UProb[i] = g0_Theta[i]/g0;
			MissingMProb[i] = g1miss_Theta[i]/g1;
			MissingUProb[i] = g0miss_Theta[i]/g0;
		end;

		*Calculate match rate;
		P_hat = g1/(g0+g1);
	run;

	/*********************************************************/
	/*   Store iteration results,                            */
	/*   Calculate differences in parameter estimates        */
	/*********************************************************/
	data work._djm_estimates /pgm=work._djm_estimates;
		set work._djm_estimates work._djm_maximisation;
		array AllProb {*} %pl(&LinkVar, m_) %pl(&LinkVar, u_) %pl(&LinkVar, mm_) %pl(&LinkVar, mu_) p_hat;

		*temporary array containing the lag of AllProb;
		array  LagAP {*} %pl(&LinkVar, Lm_) %pl(&LinkVar, Lu_) %pl(&LinkVar, Lmm_) %pl(&LinkVar, Lmu_) Lp_hat;

		do i = 1 to dim(AllProb);
			LagAP[i] = lag(AllProb[i]);
		end;

		if missing(iteration) then
			do;
				iteration = _n_ - 1;
				Epsilon = 0;

				do i = 1 to dim(AllProb);
					Epsilon = Epsilon + (AllProb[i] - LagAP[i])**2;
				end;

				drop i;
				Epsilon = sqrt(Epsilon);
				call symput('Epsilon',trim(left(put(Epsilon,BEST12.))));
				call symput('iteration',trim(left(put(iteration,8.))));

				if Epsilon<&EpsConverge and Epsilon^=. then
					do;
						Converge = 'yes';
						call symput('Converge',Converge);
					end;
				else if Epsilon^=. then
					Converge ='no';
				else if Epsilon=. then
					do;
						Converge ='KABOOM';
						call symput('Converge',Converge);
					end;
			end;

		drop %pl(&LinkVar, Lm_) %pl(&LinkVar, Lu_) %pl(&LinkVar, Lmm_) %pl(&LinkVar, Lmu_) Lp_hat;
	run;

%mend maximise_3_compile;
