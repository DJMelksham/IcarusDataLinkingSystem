/***************************************************************************************************** 
icarus_em
THE PROGRAM RESPONSIBLE FOR RUNNING EVERYTHING TOGETHER IN SOME KIND OF 
HARMONISED BEAUTY... 
******************************************************************************************************/
%macro icarus_em	
			( 	
			LinkVars=_DJM_NONE, /* Linkvars separated by space.  If not included, aborts*/
			CountVar=_DJM_NONE, /* The variable that holds the count of each agreement pattern */
			mstart=_DJM_NONE, /* Starting M probabilities, listed to correspond with linking variables, separated by a space. */
			ustart=_DJM_NONE, /* Starting U probabilities, listed to correspond with linking variables, separated by a space. */
			mmstart=_DJM_NONE, /* If you specify model 3, you need to provide missing M probabilities as well */
			mustart=_DJM_NONE, /* If you specify model 3, you need to provide missing U probabilities as well */
			p_hatinitial=_DJM_NONE, /* The initial ratio of real links relative to the total number of comparisons */
			epsconverge=0.001, /* The variable that defines how close the iterations have to be before the EM algorithm has convereged*/
			maxiter=1000, /* The maximum number of iterations before everything gets canned and EM calls it quits */
			mdata=work.mprobs, /* The data set which will contain the final M prob estimates */
			udata=work.uprobs, /* The data set which will contain the final U prob estimates */
			mmdata=work.mmprobs, /* The data set which will contain the final MM prob estimates */
			mudata=work.muprobs, /* The data set which will contain the final MU prob estimates */
			dset=_DJM_NONE, /* The location of the agreement patterns the EM algorithm will work on. */
			model=3 /* Specifies whether you use the 2 or 3 state version of the EM algorithm. Defaults to 3 */
				);
	/* Set up EM local variables */
	%local Converge Epsilon Iteration;

	%IF &mstart^=_DJM_NONE AND &mstart^=%STR() AND %Numordset(&mstart)=D %THEN
		%DO;
			%IF %dsetvalidate(&mstart)=0 %THEN
				%DO;
					%PUT ERROR: &mstart does not exist;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;

			%IF %varsindset(&mstart,&LinkVars)= 0 %THEN
				%DO;
					%PUT ERROR: All Linkvars are not found in &mstart;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;
			%let mstart=%obtomacro(&mstart,&LinkVars,1);
		%END;

	%IF &ustart^=_DJM_NONE AND &ustart^=%STR() AND %Numordset(&ustart)=D %THEN %DO;
			%IF %dsetvalidate(&ustart)=0 %THEN
				%DO;
					%PUT ERROR: &ustart does not exist;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;

			%IF %varsindset(&ustart,&LinkVars)= 0 %THEN
				%DO;
					%PUT ERROR: All Linkvars are not found in &ustart;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;
		%let ustart=%obtomacro(&ustart,&LinkVars,1);
%END;

	%IF &mmstart^=_DJM_NONE AND &mmstart^=%STR() AND %Numordset(&mmstart)=D %THEN %DO;
			%IF %dsetvalidate(&mmstart)=0 %THEN
				%DO;
					%PUT ERROR: &mmstart does not exist;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;

			%IF %varsindset(&mmstart,&LinkVars)= 0 %THEN
				%DO;
					%PUT ERROR: All Linkvars are not found in &mmstart;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;
		%let mmstart=%obtomacro(&mmstart,&LinkVars,1);
%END;

	%IF &mustart^=_DJM_NONE AND &mustart^=%STR() AND %Numordset(&mustart)=D %THEN %DO;
			%IF %dsetvalidate(&mustart)=0 %THEN
				%DO;
					%PUT ERROR: &mustart does not exist;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;

			%IF %varsindset(&mustart,&LinkVars)= 0 %THEN
				%DO;
					%PUT ERROR: All Linkvars are not found in &mustart;
					%PUT ERROR: Aborting icarus_em...;
					%GOTO END_EM3;
				%END;
		%let mustart=%obtomacro(&mustart,&LinkVars,1);
%END;

	/* START OF THE EM PHASE */
	/* Create this data set because the code needs estimates to write out the results of each iteration, */
	/* And the expectation step needs a maximisation data set to read from. */
	/* In each subsequent iteration it is generated as output from the maximisation stage */
	%PUT NOTE: **********************************************************************;
	%PUT NOTE: CREATING INITIAL DATA SETS FOR EXPECTATION-MAXIMISATION ALGORITHM;
	%PUT NOTE: **********************************************************************;
	%PUT NOTE: %report_date;
	%PUT NOTE: %report_time;

	%em_setup_initial_dsets(LinkVars=&LinkVars,
		mstart=&mstart,
		ustart=&ustart,
		mmstart=&mmstart,
		mustart=&mustart,
		model=&model,
		P_hatInitial=&P_hatInitial);
	%PUT NOTE: **********************************************************************;
	%PUT NOTE: INITIAL DATA SETS CREATED;
	%PUT NOTE: **********************************************************************;
	%PUT NOTE: %report_date;
	%PUT NOTE: %report_time;
	%PUT NOTE: *************************************************;
	%PUT NOTE: COMPILING EXPECTATION AND MAXIMISATION CODE;
	%PUT NOTE: *************************************************;
	%PUT NOTE: %report_date;
	%PUT NOTE: %report_time;

	/* Compile the data steps programs for the requisite models */
	%IF &MODEL=2 %THEN
		%DO;
			%EXPECT_2_COMPILE(LinkVar=&LinkVars,dataset=&DSet,countvar=&countvar);
			%MAXIMISE_2_COMPILE(LinkVar=&LinkVars,EpsConverge=&EpsConverge);
		%END;
	%ELSE %IF &MODEL=3 %THEN
		%DO;
			%EXPECT_3_COMPILE(LinkVar=&LinkVars,dataset=&DSet,countvar=&countvar);
			%MAXIMISE_3_COMPILE(LinkVar=&LinkVars,EpsConverge=&EpsConverge);
		%END;
	%ELSE
		%DO;
			%PUT ERROR: INCORRECT MODEL SPECIFICATION. MODEL ARGUMENT MUST BE 2 OR 3. ABORTING...;
			%GOTO END_EM3;
		%END;

	%PUT NOTE: *************************************************;
	%PUT NOTE: EXPECTATION AND MAXIMISATION STEPS COMPILED;
	%PUT NOTE: *************************************************;
	%PUT NOTE: %report_date;
	%PUT NOTE: %report_time;
	%PUT NOTE: *************************************************;
	%PUT NOTE: *********     RUNNING EM ALGORITHM!     *********;
	%PUT NOTE: *************************************************;

	
		%do %until (&Converge=yes or &Converge=KABOOM or &Epsilon=. or &Iteration=&MaxIter);
	%RUN_EXPECTATION;
	%RUN_MAXIMISATION(Linkvar=&LinkVars,model=&model,countvar=&CountVar);

			%put NOTE: Epsilon is &Epsilon after &iteration iterations. TIME: %report_time;
		%end;
	/*output iteration history to report*/;
		%IF %UPCASE(&CONVERGE)=YES %THEN
			%PUT NOTE: ESTIMATES CONVERGED AFTER &ITERATION ITERATIONS.;
		%ELSE %IF %UPCASE(&CONVERGE)=NO %THEN
			%PUT NOTE: NO CONVERGENCE AFTER &ITERATION ITERATIONS. EPSILON IS &EPSILON.;
		%ELSE %IF %UPCASE(&CONVERGE)=KABOOM %THEN
			%PUT NOTE: KABOOM!!!! I DONT KNOW WHAT YOU DID, BUT YOU BROKE IT!;
	
		PROC PRINT DATA = work._djm_ESTIMATES NOOBS;
			%IF %UPCASE(&CONVERGE)=YES %THEN
				%DO;
					TITLE "PARAMETER ESTIMATES: CONVERGENCE AFTER &ITERATION ITERATIONS";
				%END;
			%ELSE %IF %UPCASE(&CONVERGE)=NO %THEN
				%DO;
					TITLE "PARAMETER ESTIMATES: CONVERGENCE CRITERIA NOT ACHIEVED AFTER &ITERATION ITERATIONS";
				%END;
			%ELSE %IF %UPCASE(&CONVERGE)=KABOOM %THEN
				%DO;
					TITLE "THIS IS THE WAY THE WORLD ENDS: NOT WITH A BANG BUT WITH MANY MISSING VARIABLES";
				%END;
		RUN;
	/* THE BIT TO OUTPUT MULTIPLE M and U prob datasets */
		%IF %UPCASE(&CONVERGE)=YES %THEN
			%DO;
	
				data 
				&mdata.(keep=%PL(&LinkVars,m_) rename=(%tvtdl(%PL(&LinkVars,m_),&LinkVars,%STR(=),%STR( ))))
				&udata.(keep=%PL(&LinkVars,u_) rename=(%tvtdl(%PL(&LinkVars,u_),&LinkVars,%STR(=),%STR( ))))
				%if &model=3 %THEN %DO;
				&mudata.(keep=%PL(&LinkVars,mm_) rename=(%tvtdl(%PL(&LinkVars,mm_),&LinkVars,%STR(=),%STR( ))))
				&mmdata.(keep=%PL(&LinkVars,mu_) rename=(%tvtdl(%PL(&LinkVars,mu_),&LinkVars,%STR(=),%STR( ))));
				%END;
				;
					set work._djm_estimates end=eof;
	
					if eof then
						output;
				run;
				
	
			%END;
	/* Finally: Cleaning up after ourselves */
		%deleteprograms(work._djm_expectation work._djm_maximisation work._djm_estimates);
		%deletedsets(work._djm_estimates work._djm_maximisation work._djm_expectation);
	%END_EM3:

		%IF &CONVERGE=KABOOM %THEN

			
			%DO;
				%PUT NOTE:*********************************************************************************;
				%PUT NOTE: ALAS! NOT EVERYTHING TURNED OUT QUITE LIKE WE HAD PLANNED!;
				%PUT NOTE:*********************************************************************************;
			%END;
%mend icarus_em;