%macro djm_algo2(indata=,
			outdata=,
			ida=,
			idb=,
			weightvar=,
			avgnoisevar=,
			locfamvar=,
			exp=12,
			sasfileoption=N);
	%local num;

	/* adding the local family and average noise information to the temp work dataset */
	%local_fam(indata=&indata,
		outdata=&indata,
		ida=&ida,
		idb=&idb,
		keepvars=&weightvar,
		locfamvar=&locfamvar,
		exp=&exp,
		sasfileoption=&sasfileoption);

	%djm_avgnoise(indata=&indata,
		outdata=&indata,
		ida=&ida,
		idb=&idb,
		weightvar=&weightvar,
		locfamvar=&locfamvar,
		avgnoisevar=&avgnoisevar,
		exp=&exp);

	/* Outputting (one of) the best records for each local family */
	%let num=%numofobs(&indata);

	data &outdata (keep=&ida &idb &weightvar);
	if _N_=0 then set &indata(keep= &ida &idb &weightvar &locfamvar &avgnoisevar);

		set &indata(keep= &ida &idb &weightvar &locfamvar &avgnoisevar) 
			&indata(keep = &ida &idb &weightvar &locfamvar &avgnoisevar);
		length _djm_flag $ 1 _djm_weight_hold 8 _djm_avgnoise_hold 8
			_djm_rc1 8;

		if _N_ = 1 then
			do;
				dcl hash _djm_hash1(hashexp:&exp);
				_djm_hash1.definekey("&locfamvar");
				_djm_hash1.definedata("_djm_weight_hold","_djm_avgnoise_hold","_djm_flag");
				_djm_hash1.definedone();
			end;

		If _N_ <= &num then
			do;
				_djm_rc1 = _djm_hash1.find();

				if _djm_rc1 ^= 0 then
					do;
						_djm_weight_hold = &weightvar;
						_djm_avgnoise_hold = &avgnoisevar;
						_djm_flag='0';
						_djm_hash1.add();
					end;
				else
					do;
						if _djm_weight_hold>&weightvar then
							do;
								_djm_weight_hold = &weightvar;
								_djm_avgnoise_hold = &avgnoisevar;
								_djm_flag='0';
								_djm_hash1.replace();
							end;
						else if _djm_weight_hold=&weightvar then
							do;
								if _djm_avgnoise_hold < &avgnoisevar then
									do;
										_djm_weight_hold = &weightvar;
										_djm_avgnoise_hold = &avgnoisevar;
										_djm_flag='0';
										_djm_hash1.replace();
									end;
							end;
					end;
			end;

		/* Step to take after loading hash */
		else
			do;
				_djm_hash1.find();

				if _djm_flag='0' then
					do;
						if &weightvar=_djm_weight_hold and &avgnoisevar = _djm_avgnoise_hold then
							do;
								_djm_flag='1';
								_djm_hash1.replace();
								output;
							end;
					end;
			end;
	run;

%mend djm_algo2;