%macro djm_rdeleter(deleter_dset=,
						deletee_dset=,
						outdata=,
						ida=,
						idb=,
						keepvars=,
						exp=12);

data &outdata(drop= _djm_rc1 _djm_rc2);
set &deletee_dset(keep= &ida &idb &keepvars);
length _djm_rc1 8 _djm_rc2 8;
if _N_ = 0 then set &deletee_dset(keep= &ida &idb &keepvars);

if _N_ = 1 then do;
dcl hash _djm_hash1(dataset:"&deleter_dset.(keep= &ida)",hashexp:&exp);
_djm_hash1.definekey("&ida");
_djm_hash1.definedone();

dcl hash _djm_hash2(dataset:"&deleter_dset.(keep= &idb)",hashexp:&exp);
_djm_hash2.definekey("&idb");
_djm_hash2.definedone();
end;

_djm_rc1 = _djm_hash1.check();
	if _djm_rc1 ^= 0 then do;
		_djm_rc2 = _djm_hash2.check();
		if _djm_rc2 ^= 0 then output;
		end;

run;

%mend djm_rdeleter;