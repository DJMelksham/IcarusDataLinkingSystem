%macro djm_oap_sumview(dset=,
					Varlist=_DJM_NONE,
					SumVar=_djm_sumvar,
					outview=work._djm_sumview);

%local number i variable;

Data &outview /view=&outview;
set &dset;
&SumVar = 0;

%let i=1;
%do %WHILE (%scan(&varlist,&i,%str( ))^=%STR( ));
%LET variable = %scan(&varlist,&i,%str( ));

IF &variable = 1 then &SumVar = &SumVar + 1;

%LET i=%EVAL(&I+1);
%END;

run;

%mend djm_oap_sumview;