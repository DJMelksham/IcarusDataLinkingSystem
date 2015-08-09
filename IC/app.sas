%macro app(Vars=_DJM_NONE,nums=2,outdata=work.APP,DorV=V,missings=N);
	%local varcount I J;
	%let I=1;
	%let varcount=0;
	%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));

	%IF &Vars=_DJM_NONE %THEN %DO;
	%PUT ERROR: You must supply variables to the macro via the Vars parameter.;
	%PUT ERROR: Aborting.;
	%GOTO exit;
	%END;
	
	%LET missings = %UPCASE(%SUBSTR(&missings,1,1));
	%IF &missings = Y %THEN %LET nums=%EVAL(&nums+1);

	%do %while(%scan(&Vars,&I,%str( )) ne %str());
		%let varcount=%EVAL(&varcount+1);
		%let i=%EVAL(&I+1);
	%end;

	/* Option to take if missing is equal to N */
%IF &missings = N %THEN %DO;
	data &outdata %IF &DorV=V %THEN / VIEW=&outdata;;
		%let I=1;
		length
			%do %while(%scan(&Vars,&I,%str( )) ne %str());

		%scan(&Vars,&I,%str( )) 8%STR( )
		%let i=%EVAL(&I+1);
%end;
		;

		%let I=1;

		%do %while(%scan(&Vars,&I,%str( )) ne %str());
			do %scan(&Vars,&I,%str( ))= 0 to %EVAL(&nums-1);
				%let I=%EVAL(&I+1);
		%end;

		%let I=1;

		%do %while(%scan(&Vars,&I,%str( )) ne %str());
			%IF &I=1 %THEN
					output;;
			end;

			%let I=%EVAL(&I+1);
		%end;

		stop;
	run;

	%END;

	/* Option to take is missing is equal to Y */
	%ELSE %IF &missings = Y %THEN %DO;
		data &outdata(keep=&vars) %IF &DorV=V %THEN / VIEW=&outdata;;
		%let I=1;
		length
			%do %while(%scan(&Vars,&I,%str( )) ne %str());

		%scan(&Vars,&I,%str( )) 8%STR( )
		%let i=%EVAL(&I+1);
%end;
		;

		%let I=1;

		%do %while(%scan(&Vars,&I,%str( )) ne %str());
			do %scan(%PL(&Vars,_djm_),&I,%str( ))= 0 to %EVAL(&nums-1);
				%let I=%EVAL(&I+1);
		%end;

		%let I=1;

		%do %while(%scan(&Vars,&I,%str( )) ne %str());
			%IF &I=1 %THEN %DO;
					%LET J = 1;
							%do %while(%scan(&Vars,&J,%str( )) ne %str());
								IF %scan(%PL(&Vars,_djm_),&J,%str( )) = %EVAL(&nums-1) then
									call missing(%scan(&Vars,&J,%str( )));
									else %scan(&Vars,&J,%str( ))=%scan(%PL(&Vars,_djm_),&J,%str( ));
								%LET J = %EVAL(&J+1);
							%end;
					output;
					%END;
			end;

			%let I=%EVAL(&I+1);
		%end;

		stop;
	run;
	%END;

%exit:

%mend app;