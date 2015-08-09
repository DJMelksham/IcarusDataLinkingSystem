%macro icarus_connect(ControlDataSet=);

	%local numi i;
	%let numi=%numofobs(&ControlDataSet);
	%local myoplist oplist myoplistval oplistval totallist;
	%let myoplist = Alias RWork IcarusGerminate;
	%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
	%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
	%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
	%let totallist = &myoplist &oplist;


	/******************/
	/* Error Checking */
	/******************/

	%IF %dsetvalidate(&ControlDataSet)=0 %THEN %DO;
	%PUT ERROR: &ControlDataSet does not exist.;
	%PUT ERROR: Aborting icarus_connect macro...;
	%GOTO exit;
	%END;

	%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN %DO;
	%PUT ERROR: &ControlDataSet does not meet the requirements of an;
	%PUT ERROR: icarus_connect control data set;
	%PUT ERROR: Aborting icarus_connect macro...;
	%GOTO exit;
	%END;

	/* Main loop body */
	%do i = 1 %to &numi;
		%let myoplistval = %obtomacro(&ControlDataSet,&myoplist,&i);
		%let oplistval = %obtomacro(&ControlDataSet,&oplist,&i);

		/* Assign Alias */
		%IF %scan(&myoplistval,1,%STR( ))^= . %THEN

			%DO;
				%let blah=%scan(&myoplistval,1,%STR( ));
				%local &blah;
				%let &blah = %scan(&oplistval,3,%STR( ));
			%END;
		/**************/
		/* Signing on */
		/**************/

		signon 

			/* AuthDomain */

		%IF %scan(&oplistval,1,%STR( ))^=. %THEN
			%scan(&oplist,1,%STR( ))=%scan(&oplistval,1,%STR( ));

		/* CMacVar */
		%IF %scan(&oplistval,2,%STR( ))^=. %THEN %DO;
			%scan(&oplist,2,%STR( ))=%scan(&oplistval,2,%STR( ))
			%END;

		/* ConnectRemote */
		%IF %scan(&myoplistval,1,%STR( ))^=. AND %scan(&oplistval,3,%STR( ))^=. %THEN
			%DO;
				%scan(&oplist,3,%STR( ))=%scan(&myoplistval,1,%STR( ))
			%END;
		%ELSE %IF %scan(&oplistval,3,%STR( ))^=. %THEN
			%scan(&oplist,3,%STR( ))=%scan(&oplistval,3,%STR( ));

		/* ConnectStatus */
		%IF %scan(&oplistval,4,%STR( ))^=. %THEN
			%scan(&oplist,4,%STR( ))=%scan(&oplistval,4,%STR( ));

		/* ConnectWait */
		%IF %scan(&oplistval,5,%STR( ))^=. %THEN
			%scan(&oplist,5,%STR( ))=%scan(&oplistval,5,%STR( ));

		/* CScript */
		%IF %scan(&oplistval,6,%STR( ))^=. %THEN
			%scan(&oplist,6,%STR( ))=%scan(&oplistval,6,%STR( ));

		/* CSysRPutSync */
		%IF %scan(&oplistval,7,%STR( ))^=. %THEN
			%scan(&oplist,7,%STR( ))=%scan(&oplistval,7,%STR( ));

		/* InheritLib */
		%IF %scan(&oplistval,8,%STR( ))^=. %THEN
			%scan(&oplist,8,%STR( ))=%scan(&oplistval,8,%STR( ));

		/* Log*/
		%IF %scan(&oplistval,9,%STR( ))^=. %THEN
			%scan(&oplist,9,%STR( ))=%scan(&oplistval,9,%STR( ));

		/* Output*/
		%IF %scan(&oplistval,10,%STR( ))^=. %THEN
			%scan(&oplist,10,%STR( ))=%scan(&oplistval,10,%STR( ));

		/* NoCScript*/
		%IF %scan(&oplistval,11,%STR( ))^=. %THEN
			%scan(&oplist,11,%STR( ))=%scan(&oplistval,11,%STR( ));

		/* Notify */
		%IF %scan(&oplistval,12,%STR( ))^=. %THEN
			%scan(&oplist,12,%STR( ))=%scan(&oplistval,12,%STR( ));

		/* Password*/
		%IF %scan(&oplistval,13,%STR( ))^=. %THEN
			%scan(&oplist,13,%STR( ))=%scan(&oplistval,13,%STR( ));

		/* Sascmd */
		%IF %scan(&oplistval,14,%STR( ))^=. %THEN
			%scan(&oplist,14,%STR( ))=%scan(&oplistval,14,%STR( ));

		/* Server */
		%IF %scan(&oplistval,15,%STR( ))^=. %THEN
			%scan(&oplist,15,%STR( ))=%scan(&oplistval,15,%STR( ));

		/* Serverv */
		%IF %scan(&oplistval,16,%STR( ))^=. %THEN
			%scan(&oplist,16,%STR( ))=%scan(&oplistval,16,%STR( ));

		/* SignonWait */
		%IF %scan(&oplistval,17,%STR( ))^=. %THEN
			%scan(&oplist,17,%STR( ))=%scan(&oplistval,17,%STR( ));

		/* Subject */
		%IF %scan(&oplistval,18,%STR( ))^=. %THEN
			%scan(&oplist,18,%STR( ))=%scan(&oplistval,18,%STR( ));

		/* TBufSize*/
		%IF %scan(&oplistval,19,%STR( ))^=. %THEN
			%scan(&oplist,19,%STR( ))=%scan(&oplistval,19,%STR( ));
		;
		/* Establishing Remote Work Library*/
		
		%IF %scan(&myoplistval,2,%STR( )) ^= . %THEN %DO;
		libname %scan(&myoplistval,2,%STR( )) server=%scan(&myoplistval,1,%STR( )) slibref=work;
		%END;
		/* Germinate */
		


		%IF %UPCASE(%SUBSTR(%scan(&myoplistval,3,%STR( )),1,1)) = Y %THEN %DO;
		%icarus_germinate(NodeAlias=%scan(&myoplistval,1,%STR( )),
					Icaruslocation=&_Icarus_installation);
		%END;
	
		

	%end;

%exit:
%mend icarus_connect;