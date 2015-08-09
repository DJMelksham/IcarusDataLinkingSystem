%macro ngramlettersummary(Dataset=,Outdata=work.NGramSummary,Var=_DJM_NONE,Rollover=Y,N=2,NgramVar=Ngram,exp=12);

%local I Countstat NumofNGrams;
	%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));

	PROC SQL noprint;
	SELECT MAX(length(strip((&Var))))
	into :Countstat
	FROM &DataSet;
	QUIT;

	%IF Rollover=Y %THEN %LET NumofNgrams=&Countstat;
	%ELSE %LET NumofNGrams=%EVAL(&Countstat-&N+1);

%ngramdsetletter(Dataset=&DataSet,Outdata=_djm_temp,Var=&Var,Rollover=&Rollover,N=&N,NgramVar=&NgramVar,DorV=V);

Data _djm_temp2 /view=_djm_temp2;
set 
%DO I=1 %TO &NumofNgrams %BY 1;
_djm_temp(keep=&NgramVar.&I rename=(&NgramVar.&I=&NgramVar) where=(MISSING(&NgramVar)^=1)) 
%END;
;
run;


%hashcount(DataSet=_djm_temp2,
					Vars=&NGramVar,
					countvar=result,
					DorV=D,
					Outdata=&outdata,exp=&exp);

%deletedsets(_djm_temp _djm_temp2);

%mend ngramlettersummary;

/*%NGramDsetSLetter(Dataset=work.testing,Outdata=work.NGramSummary,Var=name,Rollover=Y,N=3,NgramVar=Ngram,exp=16);*/