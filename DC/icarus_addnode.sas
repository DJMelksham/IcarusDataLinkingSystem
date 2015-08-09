options nomlogic nomprint;

%macro icarus_addnode(
			ControlDataSet = _DJM_NONE,
			Alias = .,
			RWork = .,
			IcarusGerminate = .,
			AuthDomain = .,
			CMacVar= .,
			ConnectRemote = .,
			ConnectStatus = .,
			ConnectWait = .,
			CScript = .,
			CSysRPutSync = .,
			InheritLib =.,
			Log = .,
			Output = ., 
			NOCScript = .,
			Notify = .,
			Password = .,
			Sascmd = .,
			Server = .,
			Serverv = .,
			SignonWait = .,
			Subject = .,
			TBufSize = . 
			);
	/*****************/
	/* Initial Setup */
	/*****************/
	%local oplist myoplist myvarlist countvars i;
	%local loopvar loopvalue;
	%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
	%let oplist = &oplist CSysRPutSync InheritLib Log Output NOCScript Notify;
	%let oplist = &oplist Password Sascmd Server Serverv SignonWait Subject TBufSize;
	%let myvarlist = Alias RWork IcarusGerminate &oplist;
	%let myoplist = ControlDataSet Alias RWork IcarusGerminate;
	%let countvars = %countwords(&myvarlist,%STR( ));
	%LET IcarusGerminate = %UPCASE(%SUBSTR(&IcarusGerminate,1,1));
	%LET myoplist = %UPCASE(&myoplist);
	%LET myvarlist = %UPCASE(&myvarlist);
	%LET oplist = %UPCASE(&oplist);

	%IF &ControlDataSet = _DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply a reference for the Control Data Set;
			%PUT ERROR: Aborting icarus_addnode macro...;
			%GOTO exit;
		%END;

	/*********************************************/
	/* Checking for existance of Control DataSet */
	/* Use simple defaults if not found    		 */
	/*********************************************/
	/* If control data set doesn't exist, use default settings and create it */
	%IF %dsetvalidate(&ControlDataSet) = 0 %THEN
		%DO;
			/* Append the number one onto the alias because it will be observation number
							one on a new data set  */
		%IF &CMacVar ^= . %THEN %LET CMacVar = &CMacVar.1_status;
		%IF &Alias ^= . %THEN %LET Alias = &Alias.1;
			%IF RWork ^= . %THEN %let RWork = &RWork.1;
			

			Data &ControlDataSet;
				%LET I = 1;

				%DO %WHILE (&I<=&countvars);
					%LET loopvar = %scan(&myvarlist,&i,%STR( ));
					%LET loopvalue = "&&&loopvar";
					&loopvar = &loopvalue;
					%LET I = %EVAL(&I + 1);
				%END;

				output;
				stop;
			run;

		%END;

	/***************************************************************/
	/* If the data set does already exist, then we need to check   */
	/* that it is in fact an Icarus distributed computing control  */
	/* data set.  We then also need to check that the variable     */
	/* lengths are sufficient to store all new values.             */
	/* If they are not, we need to adjust the length variables on  */
	/* the control data set before adding the new observation      */
	/***************************************************************/
	%ELSE
		%DO;
			/* The data set exists, so check it is a valid Icarus 			*/
			/* distributed computing control data set.						*/
			%IF %UPCASE(%varlistfromdset(&ControlDataSet))^=&myvarlist %THEN
				%DO;
					%PUT ERROR: &ControlDataSet does not appear to be a valid;
					%PUT ERROR: Icarus distributed computing control data set;
					%PUT ERROR: Aborting icarus_addnode macro...;
					%GOTO exit;
				%END;

			/* The data set is valid, so now check and adjust lengths of 	*/
			/* the variables on the control data set against the lengths of */
			/* the new values that need to be appended                      */

			%local num;
			%let num=%EVAL(%numofobs(&ControlDataSet) + 1);
			%IF &CMacVar ^= . %THEN %LET CMacVar = &CMacVar.&num._status;
			%IF &Alias ^= . %THEN %LET Alias = &Alias.&num;
			%IF RWork ^= . %THEN %let RWork = &RWork.&num;

			%local newvarlengths oldvarlengths varlengths;
			%let oldvarlengths = %varlengths(&ControlDataSet, &myvarlist);
			%let newvarlengths =;
			%LET I = 1;

			%DO %WHILE (&I<=&countvars);
				%LET varlengths=%scan(&myvarlist,&i,%STR( ));
				%LET varlengths=&&&varlengths;
				%LET varlengths=%length(&varlengths);
				
				%IF &varlengths > %scan(&oldvarlengths,&I,%STR( )) %THEN
					%LET newvarlengths =&newvarlengths &varlengths;
				%ELSE %LET newvarlengths =&newvarlengths %scan(&oldvarlengths,&I,%STR( ));
				%LET I = %EVAL(&I + 1);
			%END;

			/* Write the new control data set output 						*/
			/* I decided to use this method instead of append because of the*/
			/* length issue, but also because efficiency is unlikely to be  */
			/* a realistic concern for data sets of this size               */

			

			Data &ControlDataSet;
				length 
					%LET I = 1;

				%DO %WHILE (&I<=&countvars);
					%scan(&myvarlist,&i,%STR( )) $ %scan(&newvarlengths,&i,%STR( )) 
					%LET I = %EVAL(&I + 1);
				%END;
				;
				set &ControlDataSet end=_djm_eof;
				output;

				if _djm_eof then
					do;
						%LET I = 1;

						%DO %WHILE (&I<=&countvars);
							%LET loopvar = %scan(&myvarlist,&i,%STR( ));
							%LET loopvalue = "&&&loopvar";
							&loopvar = &loopvalue;
							%LET I = %EVAL(&I + 1);
						%END;
						output;
						stop;
					end;
			run;

		%END;

	%exit:
%mend icarus_addnode;