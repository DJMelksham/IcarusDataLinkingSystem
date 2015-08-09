%macro local_fam(indata=,
			outdata=,
			ida=,
			idb=,
			keepvars=_DJM_NONE,
			locfamvar=,
			exp=12,
			sasfileoption=N);
	%local num;
	%local outdatahold libhold changeflag;

	%let changeflag=0;
	%let num=%numofobs(&indata);
	%LET ida=%UPCASE(&ida);
	%LET idb=%UPCASE(&idb);
	%LET locfamvar=%UPCASE(&locfamvar);
	%LET keepvars=%UPCASE(&keepvars);
	%LET sasfileoption=%UPCASE(%SUBSTR(&sasfileoption,1,1));

	%IF &keepvars=_DJM_NONE %THEN
		%DO;
			%LET keepvars = %varlistfromdset(&indata);
		%END;

	%LET keepvars = %removewordfromlist(&ida, &keepvars);
	%LET keepvars = %removewordfromlist(&idb, &keepvars);
	%LET keepvars = %removewordfromlist(&locfamvar, &keepvars);

	%IF %vordset(&indata)=V %THEN %DO;
		%IF &sasfileoption=Y %THEN %DO;
		%PUT Note: If target data set is a view, it cant be used with the SASfileoption;
		%PUT NOTE: Resetting sasfileoption to N and continuing...;
		%let sasfileoption=N;
		%END;

		%IF &indata=&outdata %THEN %DO;
		%PUT ERROR: Local_fam macro is trying to write out to the same view its reading in;
		%PUT ERROR: This just aint gonna happen.;
		%PUT ERROR: Either change the view to a data set, or output to a different named file;
		%PUT ERROR: Aborting local_fam macro...;
		%GOTO exit;
		%END;
	%END;

	%IF &sasfileoption = Y %THEN
		%DO;
			%IF &indata = &outdata %THEN
				%DO;
					%let changeflag=1;
					%let outdatahold=&outdata;
					%let libhold = %libnameparse(&outdata);
					%let outdata = &libhold.._djm_locfamtemp;
				%END;

			sasfile &indata load;;
		%END;

	data &outdata(keep= &ida &idb &keepvars &locfamvar);
		length _djm_pointvar 8 _djm_locfamhold_a 8 _djm_locfamhold_b 8 
			&locfamvar 8 _djm_rc1 8 _djm_rc2 8 _djm_sum1 8 _djm_sum2 8 
			_djm_totalsum1 8 _djm_totalsum2 8 &locfamvar 8 _djm_pointvar 8
			_djm_iteratevar 8 _djm_totalsumflag $ 1;
		set &indata(keep= &ida &idb &keepvars) &indata(keep= &ida &idb &keepvars);

		if _N_=1 then
			do;
				dcl hash _djm_hash1(hashexp:&exp);
				_djm_hash1.definekey("&ida");
				_djm_hash1.definedata("_djm_locfamhold_a");
				_djm_hash1.definedone();
				dcl hash _djm_hash2(hashexp:&exp);
				_djm_hash2.definekey("&idb");
				_djm_hash2.definedata("_djm_locfamhold_b");
				_djm_hash2.definedone();
			end;

		/* first iteration through, populate _djm_fam_a and _djm_fam_b
		with the lowest _N_ number to represent their family */
		if _N_<=&num then
			do;
				/* hash 1 population */
				_djm_rc1 = _djm_hash1.find();
				_djm_rc2 = _djm_hash2.find();

				if _djm_rc1^=0 then
					do;
						if _djm_rc2=0 then
							do;
								_djm_locfamhold_a = _djm_locfamhold_b;
								_djm_hash1.add();
							end;
						else
							do;
								_djm_locfamhold_a = _N_;
								_djm_hash1.add();
							end;
					end;

				/* hash 2 population */
				if _djm_rc2^=0 then
					do;
						if _djm_rc1=0 then
							do;
								_djm_locfamhold_b = _djm_locfamhold_a;
								_djm_hash2.add();
							end;
						else
							do;
								_djm_locfamhold_b = _N_;
								_djm_hash2.add();
							end;
					end;

				/* And if they're both already there */
				if _djm_rc1 = 0 and _djm_rc2 = 0 then
					do;
						if _djm_locfamhold_a > _djm_locfamhold_b then
							do;
								_djm_locfamhold_a=_djm_locfamhold_b;
								_djm_hash1.replace();
							end;
						else if _djm_locfamhold_a < _djm_locfamhold_b then
							do;
								_djm_locfamhold_b=_djm_locfamhold_a;
								_djm_hash2.replace();
							end;
					end;
			end;

		/* Part that finds the correct loc fam for records */
		if _N_=&num then
			do;
				_djm_totalsum1 = 0;
				_djm_totalsum2 = 0;
				_djm_sum1 = 0;
				_djm_sum2 = 0;
				declare hiter _djm_hashiter1('_djm_hash1');
				declare hiter _djm_hashiter2('_djm_hash2');
				_djm_iteratevar = _djm_hashiter1.first();

				do while (_djm_iteratevar = 0);
					_djm_sum1 = _djm_sum1 + _djm_locfamhold_a;
					_djm_iteratevar = _djm_hashiter1.next();
				end;

				_djm_iteratevar = _djm_hashiter2.first();

				do while (_djm_iteratevar = 0);
					_djm_sum2 = _djm_sum2 + _djm_locfamhold_b;
					_djm_iteratevar = _djm_hashiter2.next();
				end;

				_djm_totalsum2 = _djm_sum1 + _djm_sum2;

				do until (_djm_totalsumflag = '1');
					do _djm_pointvar = 1 to &num;
						set &indata(keep= &ida &idb &keepvars) point=_djm_pointvar;
						_djm_rc1 = _djm_hash1.find();
						_djm_rc2 = _djm_hash2.find();

						if _djm_locfamhold_a > _djm_locfamhold_b then
							do;
								_djm_locfamhold_a=_djm_locfamhold_b;
								_djm_hash1.replace();
							end;
						else if _djm_locfamhold_a < _djm_locfamhold_b then
							do;
								_djm_locfamhold_b=_djm_locfamhold_a;
								_djm_hash2.replace();
							end;
					end;

					_djm_sum1 = 0;
					_djm_sum2 = 0;
					_djm_iteratevar = _djm_hashiter1.first();

					do while (_djm_iteratevar = 0);
						_djm_sum1 = _djm_sum1 + _djm_locfamhold_a;
						_djm_iteratevar = _djm_hashiter1.next();
					end;

					_djm_iteratevar = _djm_hashiter2.first();

					do while (_djm_iteratevar = 0);
						_djm_sum2 = _djm_sum2 + _djm_locfamhold_b;
						_djm_iteratevar = _djm_hashiter2.next();
					end;

					_djm_totalsum1 = _djm_sum1 + _djm_sum2;

					if _djm_totalsum1 = _djm_totalsum2 then
						_djm_totalsumflag = '1';
					_djm_totalsum2 = _djm_totalsum1;
				end;
			end;

		/* Once the locfam has been found, we then have to go through
									and populate the remaining records with the correct values */
		if _N_>&num then
			do;
				_djm_hash1.find();
				&locfamvar = _djm_locfamhold_a;
				output;
			end;
	run;

	%IF &sasfileoption = Y %THEN
		%DO;
			%IF &changeflag=1 %THEN
				%DO;
					sasfile &indata close;
					%deletedsets(&outdatahold);

					proc datasets lib=&libhold nolist;
						change _djm_locfamtemp = %dsetparse(&outdatahold);
					run;

				%END;
				%ELSE %DO;

			sasfile &indata close;
			%END;
		%END;

		%exit:
%mend local_fam;