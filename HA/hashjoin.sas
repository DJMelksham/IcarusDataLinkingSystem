%macro hashjoin(DataSetA=,DataSetB=,
			JoinVars=_DJM_NONE,JoinVarsA=_DJM_NONE,JoinVarsB=_DJM_NONE,
			Datavars=_DJM_NONE,DataVarsA=_DJM_NONE,DataVarsB=_DJM_NONE,
			PrefixA=,PrefixB=,Jointype=IJ,DorV=D,Outdata=work.joined,exp=16,
			ForceA=N,ForceAKey=N,ForceB=N,ForceBKey=N,ExcludeMissings=N);
	%local Force DataSetAHold DataSetBHold DSADV DSBDV DSADataSize DSBDataSize DSAKeySize DSBKeySize 
DSASize DSBSize DSAKeyOptSize DSBKeyOptSize RealMem HashOrder AHash BHash Hash AKey BKey Key Smaller;
%local BothVarsA PLBothVarsA PLDataVarsA PLJoinVarsA RNBothVarsA RNDataVarsA RNJoinVarsA QCDataVarsA 
QCJoinVarsA KKJoinVarsA BothVarsB PLBothVarsB PLDataVarsB PLJoinVarsB RNBothVarsB RNDataVarsB RNJoinVarsB 
QCDataVarsB QCJoinVarsB KKJoinVarsB WJoinVarsA WJoinVarsB;

options NOQUOTELENMAX;

%let jointype=%UPCASE(&jointype);
%let ForceA=%SUBSTR(%UPCASE(&FORCEA),1,1);
%let ForceAKey=%SUBSTR(%UPCASE(&FORCEAKey),1,1);
%let ForceB=%SUBSTR(%UPCASE(&FORCEB),1,1);
%let ForceBKey=%SUBSTR(%UPCASE(&FORCEBKey),1,1);
%let ExcludeMissings=%SUBSTR(%UPCASE(&Excludemissings),1,1);


%IF &ForceA=Y OR &ForceB=Y OR &ForceAKey=Y OR &ForceBKey=Y %THEN
%let FORCE=Y;

	%if &DataVars=_DJM_NONE AND &DataVarsA=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
		%do;
			%let DataVarsA=%varlistfromdset(&DataSetA);
			%let DataVarsB=%varlistfromdset(&DataSetB);
		%end;
	%ELSE
		%DO;
			%if &DataVars=_DJM_NONE AND &DataVarsA=_DJM_NONE %then
				%let DataVarsA=%varlistfromdset(&DataSetA);

			%if &DataVars=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
				%let DataVarsB=%varlistfromdset(&DataSetB);

			%if &DataVars^=_DJM_NONE AND &DataVarsA=_DJM_NONE %then
				%let DataVarsA=&DataVars;

			%if &DataVars^=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
				%let DataVarsB=&DataVars;
		%END;

	/*****************************/
	/* Some initial error checks */
	/*****************************/
	/* Does DataSetA exist? */
	%IF %DSETVALIDATE(&DataSetA)=0 %THEN
		%DO;
			%PUT ERROR: Data Set A does not exist;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;

	/* Does DataSetB exist? */
	%IF %DSETVALIDATE(&DataSetB)=0 %THEN
		%DO;
			%PUT ERROR: Data Set B does not exist;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;

	/* Have join vars been supplied? */
	%IF (&JoinVars=_DJM_NONE AND &JoinVarsA=_DJM_NONE AND &JoinVarsB=_DJM_NONE) %THEN
		%DO;
			%PUT ERROR: Either JoinVars, JoinVarsA or JoinVarsB must be supplied to the hash macros;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;

	/* If joinvars has not been supplied, have both JoinVarsA and JoinVarsB been supplied */
	%IF (&JoinVars=_DJM_NONE AND (&JoinVarsA=_DJM_NONE OR &JoinVarsB=_DJM_NONE)) %THEN
		%DO;
			%PUT ERROR: If JoinVars is not supplied, then JoinVarsA or JoinVarsB must both be supplied to the hash macros;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;

	/* If joinvars has been supplied, are the join vars present in data set A and data set B */
	%IF &joinvars^=_DJM_NONE %THEN
		%DO;
			%IF %Varsindset(&DataSetA,&joinvars)=0 %THEN
				%DO;
					%PUT ERROR: All joinvars are not present in Data Set A;
					%PUT ERROR: Aborting Hash Join...;
					%GOTO exit;
				%END;

			%IF %Varsindset(&DataSetB,&joinvars)=0 %THEN
				%DO;
					%PUT ERROR: All joinVars are not present in Data Set B;
					%PUT ERROR: Aborting Hash Join...;
					%GOTO exit;
				%END;
		%END;

	/* And if we have two different join vars, then we do this option for an errorcheck instead*/
	%ELSE
		%DO;
			%IF %Varsindset(&DataSetA,&joinvarsA)=0 %THEN
				%DO;
					%PUT ERROR: All joinVarsA are not present in Data Set A;
					%PUT ERROR: Aborting Hash Join...;
					%GOTO exit;
				%END;

			%IF %Varsindset(&DataSetB,&joinvarsB)=0 %THEN
				%DO;
					%PUT ERROR: All joinVarsB are not present in Data Set B;
					%PUT ERROR: Aborting Hash Join...;
					%GOTO exit;
				%END;
		%END;

	/* We populate JoinVarsA and JoinVarsB with JoinVars if that's what we want to do.*/
	%IF &JoinVars^=_DJM_NONE AND &JoinVarsA=_DJM_NONE AND &JoinVarsB=_DJM_NONE %THEN
		%DO;
			%let JoinVarsA=&JoinVars;
			%let JoinVarsB=&JoinVars;
		%END;

	/* Are join vars of the same type */
	%IF %vartype(&DataSetA,&JoinVarsA)^=%vartype(&DataSetB,&JoinVarsB) %THEN
		%DO;
			%PUT ERROR: The joinvars are not of the same type on both of the data sets;
			%PUT ERROR: These algorithms require join variables to be of the same data type;
			%GOTO exit;
		%END;

	/* Are the Datavars present in data set A and data set B */
	%IF %Varsindset(&DataSetA,&DataVarsA)=0 %THEN
		%DO;
			%PUT ERROR: All DataVarsA are not present in Data Set A;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;

	%IF %Varsindset(&DataSetB,&DataVarsB)=0 %THEN
		%DO;
			%PUT ERROR: All DataVarsB are not present in Data Set B;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;


/* This little section has been put in to try to ensure there is a prefix option when LO or RO is chosen as default. */
		/* Its a bit of a hack at a very late stage of the project */
		/* The hope is that it will help avoid little warning messages when variables are of different lengths */

		%IF &Jointype = LO %THEN %DO;
		%LET prefixb = _djm_;
		%END;

		%ELSE %IF &Jointype = RO %THEN %DO;
		%LET prefixa = _djm_;
		%END;

	/***********************************************************
	 * ANALYTICAL SECTION TO DECIDE WHICH HASH ALGORITHMS TO RUN*
 ***********************************************************/

	/*Set defaults for hashing options: Hashing data set A is given arbitrary preference */

	/* But otherwise we have set options such that nothing should run, and will only run once we have changed them after tests have passed. 
	So: 

	HashOrder dictates whether it is Data Set A or Data Set B that we will try to put into a Hash table.

	A Hash is a flag for our preference for allowing Data Set A to be fully hashed: N=NO,Y=YES,NP=NOT POSSIBLE
	B Hash is a flag for our preference for allowing Data Set B to be fully hashed: N=NO,Y=YES,NP=NOT POSSIBLE 
	Hash is a flag combining our preferences: N=NO, Y=YES, NP=NOT POSSIBLE 

	AKey is a flag for our preference for allowing Data Set A to be key hashed: N=NO,Y=YES,NP=NOT POSSIBLE
	BKey is a flag for our preference for allowing Data Set B to be key hashed: N=NO,Y=YES,NP=NOT POSSIBLE 
	Key is a flag combining our preferences: N=NO, Y=YES, NP=NOT POSSIBLE

	Smaller is a flag to determine which of the two data sets is the smaller of the two, as we wish to err
	on the side of caution when it comes to memory constraints: Options are A or B.
	*/
	%let HashOrder=A;
	%let AHash=N;
	%let BHash=N;
	%let Hash=N;
	%let AKey=N;
	%let BKey=N;
	%let Key=N;

	/* Set variables to test whether the items are Data Sets or Views, understanding that we do not want to try to use point methods with Views */
	%let DSADV=%VORDSET(&DataSetA);
	%let DSBDV=%VORDSET(&DataSetB);

	/* Filling Data for Data Set A if Data Set A is a Data Set, because a view might be slower to get this data for */
	%IF &DSADV=D AND &FORCE^=Y %THEN
		%DO;
			%LET DSADataSize=%EstimateSize(&DataSetA,&DataVarsA);
			%LET DSAKeySize=%EstimateSize(&DataSetA,&JoinVarsA);
			%lET DSASize=%EVAL(&DSAKeySize+&DSADataSize);
			%LET DSAKeyOptSize=%EVAL(&DSAKeySize+(%numofobs(&DataSetA)*8));

			%IF &DSASize < %RealMem %THEN
				%DO;
					%LET AHash=Y;
					%LET AKey=Y;
				%END;
			%ELSE %IF &DSAKeyOptSize < %RealMem %THEN
				%DO;
					%LET AHash=NP;
					%LET AKey=Y;
				%END;
			%ELSE
				%DO;
					%LET BHash=NP;
					%LET BKey=NP;
				%END;
		%END;

	/* Filling Data for Data Set B if Data Set B is a Data Set, because a view might be slower to get this data for */
	%IF &DSBDV=D AND &FORCE^=Y %THEN
		%DO;
			%LET DSBDataSize=%EstimateSize(&DataSetB,&DataVarsB);
			%LET DSBKeySize=%EstimateSize(&DataSetB,&JoinVarsB);
			%LET DSBSize=%EVAL(&DSBKeySize+&DSBDataSize);
			%LET DSBKeyOptSize=%EVAL(&DSBKeySize+(%numofobs(&DataSetB)*8));

			%IF &DSBSize < %RealMem %THEN
				%DO;
					%LET BHash=Y;
					%LET BKey=Y;
				%END;
			%ELSE %IF &DSBKeyOptSize < %RealMem %THEN
				%DO;
					%LET BHash=NP;
					%LET BKey=Y;
				%END;
			%ELSE
				%DO;
					%LET BHash=NP;
					%LET BKey=NP;
				%END;
		%END;

	/* Now we do some analysis on the results from DataSetA and DataSetB if they were SAS data sets */

	/* We're going to hash the smallest one just to make things easier for memory, and also given
	that we have to do one read from both data sets at the very least anyway */
	%IF &AHash=Y AND &BHash=Y AND &FORCE^=Y %THEN
		%DO;
			%IF &DSBSize<&DSASize %THEN
				%LET HashOrder=B;
		%END;
	%ELSE %IF &AKey=Y AND &BKey=Y AND &FORCE^=Y %THEN
		%DO;
			%IF &DSBKeyOptSize<&DSAKeyOptSize %THEN
				%LET HashOrder=B;
		%END;
	%ELSE %IF (&AHash=NP OR &AHash=N) AND &BHash=Y AND &FORCE^=Y %THEN
		%DO;
			%LET HashOrder=B;
		%END;
	%ELSE %IF (&AKey=NP OR &AKey=N) AND &BKey=Y AND &FORCE^=Y %THEN
		%DO;
			%LET HashOrder=B;
		%END;

	%IF &AHash=Y OR &BHash=Y %THEN
		%LET Key=N;
	%ELSE %IF &AKey=Y OR &BKey=Y %THEN
		%LET Key=Y;

	/* So, if we've gotten this far, we're at the stage where we can either conclude that our hashing strategy is set, 
	and what that hashing strategy will be, or we're at the stage where the hashing strategy will fail, or, some bright
	spark has decided to try to automatically hash two views.

	If its the view case, and we're not trying to force things, we'll try to do some calculations as to whether we can
	legitimately hash the requested table, but it might be slow since we can't just calcualte this from meta data for a view.

	Rather than do this to both views unconditionally, we'll do it on one at a time, and only do it on the other one if it
	turns out that our first attempt is a failure.

	Also, we cannot use the point option, since views supply records sequentially.

	If the user wishes, they can avoid all this by using the force option.
	*/
	%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y AND &DSADV=V %THEN
		%DO;
			%LET DSASize=%EstimateSize(&DataSetA,&JoinVarsA &DataVarsA);

			%IF &DSASize<%RealMem %THEN
				%LET AHash=Y;
		%END;

	%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y AND &DSBDV=V %THEN
		%DO;
			%LET DSBSize=%EstimateSize(&DataSetB,&JoinVarsB &DataVarsB);

			%IF &DSBSize<%RealMem %THEN
				%LET BHash=Y;
		%END;

	/* Now that is all done, one last check.  If we've done all that, and we can't find an acceptable strategy, we're going to abort
	the algorithm, otherwise, we're going to continue on to the actual hashing parts*/
	%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y %THEN
		%DO;
			%PUT ERROR: Cannot find an acceptable hash strategy given the size and qualities of the tables/variables involved;
			%PUT ERROR: Aborting Hash Join...;
			%GOTO exit;
		%END;


	%LET JoinVarsA=%UPCASE(&JoinVarsA);
	%LET JoinVarsB=%UPCASE(&JoinVarsB);
	%LET DataVarsA=%UPCASE(&DataVarsA);
	%LET DataVarsB=%UPCASE(&DataVarsB);
	%LET BothVarsA=%UniqueWords(&JoinVarsA &DataVarsA);
	%LET PLBothVarsA=%PL(&BothVarsA,&prefixA);
	%LET PLDataVarsA=%PL(&DataVarsA,&prefixA);
	%LET PLJoinVarsA=%PL(&JoinVarsA,&prefixA);
	%LET RNBothVarsA=%tvtdl(&BothVarsA,&PLBothVarsA,%STR(=),%STR( ));
	%LET RNDataVarsA=%tvtdl(&DataVarsA,&PLDataVarsA,%STR(=),%STR( ));
	%LET RNJoinVarsA=%tvtdl(&JoinVarsA,&PLJoinVarsA,%STR(=),%STR( ));
	%LET WJoinVarsA=%termlistpattern(&PLJoinVarsA,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
	%LET QCDataVarsA=%QCList(&PLDataVarsA);
	%LET QCJoinVarsA=%QCList(&PLJoinVarsA);
	%LET KKJoinVarsA=%tvtdl(%repeater(%STR(Key:),%countwords(&PLJoinVarsA,%STR( )),%STR( )),&PLJoinVarsA,%STR( ),%STR(,));
	%LET BothVarsB=%UniqueWords(&JoinVarsB &DataVarsB);
	%LET PLBothVarsB=%PL(&BothVarsB,&prefixB);
	%LET PLDataVarsB=%PL(&DataVarsB,&prefixB);
	%LET PLJoinVarsB=%PL(&JoinVarsB,&prefixB);
	%LET RNBothVarsB=%tvtdl(&BothVarsB,&PLBothVarsB,%STR(=),%STR( ));
	%LET RNDataVarsB=%tvtdl(&DataVarsB,&PLDataVarsB,%STR(=),%STR( ));
	%LET RNJoinVarsB=%tvtdl(&JoinVarsB,&PLJoinVarsB,%STR(=),%STR( ));
	%LET QCDataVarsB=%QCList(&PLDataVarsB);
	%LET QCJoinVarsB=%QCList(&PLJoinVarsB);
	%LET KKJoinVarsB=%tvtdl(%repeater(%STR(Key:),%countwords(&PLJoinVarsB,%STR( )),%STR( )),&PLJoinVarsB,%STR( ),%STR(,));
	%LET WJoinVarsB=%termlistpattern(&PLJoinVarsB,%STR(IS NOT MISSING),%STR( ),%STR( AND ));;

	/*************************************************************************************************
 * BEGINNING OF ACTUAL HASHING PART ***************************************************************
 **************************************************************************************************
 **************************************************************************************************
 * EXCESSIVE COMMENTS HERE JUST SO I CAN SEE SUCH THINGS EASIER DURING DEVELOPMENT ****************
 **************************************************************************************************
 **************************************************************************************************
 * WOW COMMENTS!!!!!*******************************************************************************
 **************************************************************************************************
 **************************************************************************************************
 *************************************************************************************************/

	/********************************************************************************
 * IJ TREE ***********************************************************************
 ********************************************************************************/
	%IF &jointype=IJ %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_=0 then
											do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								do until (_djm_b_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_b_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_=0 then
											do while (_iorc_=0);
											set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								do until (eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_=0 then
											do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_=0 then
											do while (_iorc_=0);
											set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

%ELSE %IF &jointype=LI %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_=0 then
											do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;




								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								do until (_djm_b_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_b_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_=0 then
											do while (_iorc_=0);
											set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;



								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								do until (eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsA);
										
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;
											
										else do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;											

										else do while (_iorc_=0);
											set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

%ELSE %IF &jointype=RI %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsB);
										
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;
											
										else do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;											

										else do while (_iorc_=0);
											set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

																do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_=0 then
											do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

																do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_=0 then
											do while (_iorc_=0);
											set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

		%ELSE %IF &jointype=FI %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsB);
										
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;
											
										else do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;											

										else do while (_iorc_=0);
											set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								do until (eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsA);
										
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;
											
										else do while (_iorc_=0);
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;


						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;											

										else do while (_iorc_=0);
											set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
												output;
												_iorc_=djmhash.find_next();
											end;
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

%ELSE %IF &jointype=LO %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								do until (eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsA);
							
										if _iorc_^=0 then do;
											output;
										end;
											
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_^=0 then do;
											output;
										end;											
								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

%ELSE %IF &jointype=RO %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
										_iorc_=djmhash.find(&KKJoinVarsB);
										
										if _iorc_^=0 then do;
											output;
										end;
								
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_^=0 then do;
											output;
										end;											
								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											output;
										end;

								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

%ELSE %IF &jointype=FO %THEN
		%DO;
			/* Tree to be taken if we decide that it is Data Set A that will be hashed */
			%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata (&QCDataVarsA);
								djmhash.definedone();

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;
							
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsA);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_a_eof);
								set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
								djmhash.add();
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsB);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsA));
											output;
										end;											

								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsB));
											output;
										end;

								end;

								stop;
							run;

						%END;

					/* Tree to be taken if we are attempting the HashMap strategy */
					
				%END;

			/* Tree to be taken if we decide that it is Data Set B that will be hashed */
			%ELSE
				%DO;
					/* Tree to be taken if we decide we will use a regular Hash strategy*/
					%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
						%DO;

							Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
								%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
								;
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata (&QCDataVarsB);
								djmhash.definedone();

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);
										
										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;
									
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;


						%END;

					/* Tree to be taken if we decide that we will use a Hash/Point strategy */
					%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
						%DO;

						Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
								if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
								if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););

								length _DJM_ID 8;
								dcl hash djmhash (hashexp: &exp,multidata: "Y");
								
								djmhash.definekey (&QCJoinVarsB);
								djmhash.definedata ('_DJM_ID');
								djmhash.definedone();

								do _DJM_ID = 1 by 1 until (_djm_b_eof);
								set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
								djmhash.add();
								end;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.find(&KKJoinVarsA);

										if _iorc_^=0 then do;
											call missing (%Commalist(&PLDataVarsB));
											output;
										end;											
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsA);
										if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
								end;

								_djm_a_eof=0;

								do until (_djm_a_eof);
									set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
										_iorc_=djmhash.check(&KKJoinVarsB);
										if _iorc_=0 then do;
											call missing(%Commalist(&PLDataVarsA));
											output;
										end;

								end;

								stop;
							run;

						%END;
					
				%END;
		%END;

	%exit:

%mend hashjoin;