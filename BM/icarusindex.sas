%macro icarusindex(		
			DataSet=_DJM_NONE,
			Vars=DJM_NONE,
			Index1=work.Index1_1,
			Index2=work.Index2_1,
			ExcludeMissings=N,
			exp=12);
	%Local i tempquote;
	%LET ExcludeMissings=%UPCASE(%SUBSTR(&ExcludeMissings,1,1));

	/**************************/
	/* Error checking section */
	/*****************************/

	/* Does DataSet exist? */
	%IF %DSETVALIDATE(&DataSet)=0 %THEN
		%DO;
			%PUT ERROR: Data Set does not exist;
			%PUT ERROR: Aborting IcarusIndex...;
			%GOTO exit;
		%END;

	/* Have index vars been supplied? */
	%IF (&Vars=_DJM_NONE) %THEN
		%DO;
			%PUT ERROR: Vars must be supplied to the TwoIndexCreation macros;
			%PUT ERROR: Aborting IcarusIndex...;
			%GOTO exit;
		%END;

	/* If Vars has been supplied, are the join vars present in data set A and data set B */
	%IF %Varsindset(&DataSet,&Vars)=0 %THEN
		%DO;
			%PUT ERROR: All Vars are not present in Data Set;
			%PUT ERROR: Aborting IcarusIndex...;
			%GOTO exit;
		%END;


	/***********************/
	/* Create Second Index */
	/***********************/
	Data work._djm_temp /view=work._djm_temp;
		set &Dataset(keep=&Vars);
		_djm_pointer=_N_;
	run;

	Data work._djm_index1;
		set
			work._djm_temp(Keep=&Vars _djm_pointer

			%IF &ExcludeMissings=Y %THEN WHERE=(%termlistpattern(&Vars,%STR(IS NOT MISSING),%STR( ),%STR( AND )));
			);
	run;

	%deletedsets(work._djm_temp);

	proc sort data=work._djm_index1;
		by &Vars _djm_pointer;
	run;

	data work._djm_temp /view=work._djm_temp;
	set work._djm_index1;
	_djm_pointer2=_N_;
	run;

	/***********************/
	/* Create First Index  */
	/***********************/
	Data &Index2(keep=_djm_pointer) &Index1(keep=&Vars _djm_start _djm_end);
		
		IF _N_=0 then
			set work._djm_temp;

			length _djm_start 8 _djm_end 8;

		IF _N_=1 THEN
			DO;
				declare hash _djm_indexhash(hashexp:&exp);
				_djm_indexhash.defineKey(%QClist(&Vars));
				_djm_indexhash.defineData(%QClist(&Vars),"_djm_start", "_djm_end");
				_djm_indexhash.definedone();
				declare hiter _djm_ihashiter('_djm_indexhash');
				call missing(_djm_start,_djm_end);
			END;

		do until (_djm_eof);
			set work._djm_temp end=_djm_eof;
			_iorc_=_djm_indexhash.check();

			if _iorc_^=0 then
				do;
					_djm_start=_djm_pointer2;
					_djm_end=_djm_pointer2;
					_djm_indexhash.add();
				end;
			else
				do;
					_djm_indexhash.find();
					_djm_end=_djm_pointer2;
					_djm_indexhash.replace();
				end;

			output &Index2;


		end;

		_iorc_=_djm_ihashiter.first();

		do while(_iorc_=0);
			output &Index1;
			_iorc_=_djm_ihashiter.next();
		end;

		stop;
	run;

	%Deletedsets(work._djm_temp work._djm_index1);

	%exit:
%mend icarusindex;