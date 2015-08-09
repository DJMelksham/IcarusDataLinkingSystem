%macro djm_avgnoise(indata=,
						outdata=,
						ida=,
						idb=,
						weightvar=,
						locfamvar=,
						avgnoisevar=,
						exp=12);

/* Average noise for djm_assignment */
	%local num;
	%let num=%numofobs(&indata);

	Data &outdata(keep= &ida &idb &weightvar &locfamvar &avgnoisevar);
		length _djm_sum_a 8 _djm_sum_b 8 _djm_num_a 8 _djm_num_b 8 _djm_rc1 8 _djm_rc2 8 &avgnoisevar 8;
		if _N_=0 then set &indata(keep= &ida &idb &weightvar);
		set &indata(keep= &ida &idb &weightvar &locfamvar) &indata(keep=&ida &idb &weightvar &locfamvar);
		

		if _N_=1 then
			do;
				dcl hash _djm_hash1(hashexp:&exp);
				_djm_hash1.definekey("&ida");
				_djm_hash1.definedata("_djm_sum_a","_djm_num_a");
				_djm_hash1.definedone();

				dcl hash _djm_hash2(hashexp:&exp);
				_djm_hash2.definekey("&idb");
				_djm_hash2.definedata("_djm_sum_b","_djm_num_b");
				_djm_hash2.definedone();

			end;

		if _N_<=&num then
			do;
				/* hash 1 population */
				_djm_rc1 = _djm_hash1.find();

				if _djm_rc1=0 then
					do;
						_djm_sum_a = _djm_sum_a + &weightvar;
						_djm_num_a = _djm_num_a + 1;
						_djm_hash1.replace();
					end;
				else
					do;
						_djm_sum_a = &weightvar;
						_djm_num_a = 1;
						_djm_hash1.add();
					end;

				/* hash 2 population */
				_djm_rc2 = _djm_hash2.find();

				if _djm_rc2=0 then
					do;
						_djm_sum_b = _djm_sum_b + &weightvar;
						_djm_num_b = _djm_num_b + 1;
						_djm_hash2.replace();
					end;
				else
					do;
						_djm_sum_b = &weightvar;
						_djm_num_b = 1;
						_djm_hash2.add();
					end;
			end;

		/* What to do after the first pass through, and hash is populated */
		else
			do;
				_djm_hash1.find();
				_djm_hash2.find();

				&avgnoisevar = ((_djm_sum_a/_djm_num_a)+(_djm_sum_b/_djm_num_b));
				output;
			end;
	run;


%mend djm_avgnoise;