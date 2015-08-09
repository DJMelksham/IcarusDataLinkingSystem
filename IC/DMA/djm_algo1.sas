%macro djm_algo1(indata=,
			outdata=,
			ida=,
			idb=,
			weightvar=,
			exp=12);
	/* Algorithm 1 for djm_assignment */
	%local num;
	%let num=%numofobs(&indata);

	Data &outdata(keep= &ida &idb &weightvar);
		length _djm_flag_a $ 1 _djm_flag_b $ 1 _djm_weightvar1 8 _djm_weightvar2 8 _djm_rc1 8 _djm_rc2 8;
		set &indata(keep= &ida &idb &weightvar) &indata(keep=&ida &idb &weightvar);

		if _N_=1 then
			do;
				dcl hash _djm_hash1(hashexp:&exp);
				_djm_hash1.definekey("&ida");
				_djm_hash1.definedata("_djm_weightvar1","_djm_flag_a");
				_djm_hash1.definedone();

				dcl hash _djm_hash2(hashexp:&exp);
				_djm_hash2.definekey("&idb");
				_djm_hash2.definedata("_djm_weightvar2","_djm_flag_b");
				_djm_hash2.definedone();
			end;

		if _N_<=&num then
			do;
				/* hash 1 population */
				_djm_rc1 = _djm_hash1.find();

				if _djm_rc1=0 then
					do;
						if &weightvar > _djm_weightvar1 then
							do;
								_djm_weightvar1 = &weightvar;
								_djm_flag_a = '1';
								_djm_hash1.replace();
							end;
						else if &weightvar = _djm_weightvar1 then
							do;
								_djm_flag_a = '0';
								_djm_hash1.replace();
							end;
					end;
				else
					do;
						_djm_weightvar1 = &weightvar;
						_djm_flag_a = '1';
						_djm_hash1.add();
					end;

				/* hash 2 population */
				_djm_rc2 = _djm_hash2.find();

				if _djm_rc2=0 then
					do;
						if &weightvar > _djm_weightvar2 then
							do;
								_djm_weightvar2 = &weightvar;
								_djm_flag_b = '1';
								_djm_hash2.replace();
							end;
						else if &weightvar = _djm_weightvar2 then
							do;
								_djm_flag_b = '0';
								_djm_hash2.replace();
							end;
					end;
				else
					do;
						_djm_weightvar2 = &weightvar;
						_djm_flag_b = '1';
						_djm_hash2.add();
					end;
			end;

		/* What to do after the first pass through, and hash is populated */
		else
			do;
				_djm_hash1.find();

				if _djm_flag_a='1' and &weightvar = _djm_weightvar1 then
					do;
						_djm_hash2.find();

						if _djm_flag_b='1' and &weightvar = _djm_weightvar2 then
							output;
					end;
			end;
	run;

%mend djm_algo1;