%macro icarus_install(Location=,
Functionlib=work);
options noquotelenmax;
%let Functionlib=&Functionlib..icarus_functions;
%IF %STR()=%sysfunc(getoption(cmplib)) %THEN options cmplib = &Functionlib;
%ELSE %PUT NOTE: User will need to manually add &Functionlib to their cmplib option;
%global _Icarus_installation _Icarus_customfunc;
%let _Icarus_installation = &Location;
%let _Icarus_customfunc = &Functionlib;
%macro djm_oap_bigwclause(dset);
%local number numberm1 i varlist varlist2 whereclause;
%let number = %numofobs(&dset);
%let i = 1;
%DO %WHILE (&i <= &number);
%let varlist = %varkeeplistdset(&dset,&i);
%IF &varlist ^= %STR() %THEN
%DO;
%let whereclause = (%STR(NOT)(%termlistpattern(&varlist,1,%STR( = ),%STR( AND ))));
&whereclause
%IF (&i < &number) %THEN %STR( AND );
%END;
%LET i = %EVAL(&i + 1);
%END;
%mend djm_oap_bigwclause;
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
%macro optimiseap(dset=,
excludevars=_DJM_NONE,
outdata=work.Optimised_AP);
%local varlist i num var currentmin;
%let varlist=%varlistfromdset(&dset);
%IF &excludevars ^= _DJM_NONE %THEN
%DO;
%let i = 1;
%DO %WHILE (%scan(&excludevars,&i,%STR( ))^=%STR( ));
%let var = %scan(&excludevars,&i,%STR( ));
%let varlist = %removewordfromlist(&var,&varlist);
%let i = %EVAL(&i + 1);
%END;
%END;
Data work._djm_oap_temp;
set &dset;
run;
%let num = %numofobs(&dset);
%IF %dsetvalidate(&outdata) %THEN %DO;
%deletedsets(&outdata);
%END;
%do %while (&num ^= 0);
%djm_oap_sumview(dset=_djm_oap_temp,
varlist=&varlist,
sumvar=_djm_sumvar,
outview=work._djm_sumview);
PROC SQL noprint;
SELECT MIN(_djm_sumvar)
INTO :currentmin
FROM work._djm_sumview;
%IF &currentmin = 0 %THEN %DO;
%deletedsets(_djm_oap_temp _djm_sumview);
%PUT ERROR: You cannot optimise a set of agreement patterns;
%PUT ERROR: where one of the patterns involves no matches;
%GOTO exit;
%END;
data work._djm_oap_tempaphold(keep = &varlist);
set work._djm_sumview(where=(_djm_sumvar = &currentmin));
run;
Data work._djm_oap_temp;
set work._djm_oap_temp(where=(%djm_oap_bigwclause(_djm_oap_tempaphold)));
run;
PROC APPEND BASE=&outdata data=_djm_oap_tempaphold force nowarn;
run;
%deletedsets(_djm_oap_tempaphold _djm_sumview);
%let num = %numofobs(_djm_oap_temp);
%END;
%deletedsets(_djm_oap_temp);
%PUT NOTE: ****************************;
%PUT NOTE: AGREEMENT PATTERNS OPTIMISED;
%PUT NOTE: ****************************;
%exit:
%mend optimiseap;
%macro ngramdsetletter(Dataset=,Outdata=work.ngrammed,Var=_DJM_NONE,Rollover=N,N=2,NgramVar=Ngram,DorV=D);
%local MaxLengthofwords NumofNgrams LengthofNgrams NumofROLetters Error I Value number;
%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));
%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
%LET ERROR=&N;
Data _null_;
set &Dataset end=_djm_eof;
length _djm_wordlength 8 _djm_wordlengthstore 8;
retain _djm_wordlength _djm_wordlengthstore;
if _n_=1 then
do;
_djm_wordlength=1;
_djm_wordlengthstore=1;
end;
_djm_wordlength=length(strip(&Var));
IF _djm_wordlength<&N then do;
call symput('Error',put(_djm_wordlength,BEST12.));
call symput('Value',SFNAME);
call symput('Number',put(_N_,BEST12.));
end;
IF _djm_wordlength>_djm_wordlengthstore THEN
_djm_wordlengthstore=_djm_wordlength;
if _djm_eof then
do;
call symput('MaxLengthofwords',put(_djm_wordlengthstore,best12.));
end;
run;
%IF &N=1 %THEN
%LET Rollover=N;
%IF &Rollover=Y %THEN
%DO;
%LET NumofNgrams=%EVAL(&MaxLengthofwords);
%LET NumofROLetters=%EVAL(&N-1);
%END;
%ELSE
%DO;
%LET NumofNGrams=%EVAL(&MaxLengthofWords-&N+1); 
%LET NumofROLetters=0;
%END;
%IF &Rollover=Y %THEN
%DO;
Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
set &Dataset;
length _djm_ngcount 8 _djm_olength 8
%DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I $&N
%END;
;
array rolett {&NumofROLetters} $1 _temporary_;
array alllett {%EVAL(&NumofROLetters+&MaxLengthofwords)} $1 _temporary_;
array _djm_NG {&NumofNGrams} $&N %DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I
%END;
;
IF _N_=1 THEN
DO;
_djm_olength=length(strip(&Var));
_djm_ngcount=_djm_olength-&N+1;
_djm_rowordcount=0;
_djm_larraylen=_djm_olength;
do _djm_i=1 to _djm_larraylen by 1;
alllett[_djm_i]=substr(&Var,_djm_I,1);
end;
END;
ELSE
DO;
_djm_olength=length(strip(&Var));
_djm_ngcount=_djm_olength;
_djm_rowordcount=&NumofROLetters;
_djm_larraylen=_djm_olength+&NumofROLetters;
do _djm_i=1 to &NumofROLetters by 1;
alllett[_djm_i]=rolett[_djm_i];
end;
do _djm_i=%EVAL(&NumofROLetters+1) to _djm_larraylen by 1;
alllett[_djm_i]=substr(&Var,_djm_I-&NumofROLetters,1);
end;
END;
do _djm_i=1 to _djm_ngcount by 1;
_djm_ng[_djm_i]=CAT(
%DO I=1 %TO &N %BY 1;
%IF &I^=&N %THEN
%DO;
alllett[%EVAL(&I-1)+_djm_i],
%END;
%ELSE
%DO;
alllett[%EVAL(&I-1)+_djm_i]
%END;
%END;
);
end;
do _djm_i=1 to &NumofROLetters by 1;
rolett[_djm_i]=substr(&Var,_djm_olength-&NumofROLetters+_djm_i,1);
end;
run;
%END;
%ELSE
%DO;
Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
set &Dataset;
length _djm_ngcount 8 _djm_olength 8
%DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I $&N
%END;
;
array alllett {%EVAL(&NumofROLetters+&MaxLengthofwords)} $1 _temporary_;
array _djm_NG {&NumofNGrams} $&N %DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I
%END;
;
_djm_olength=length(strip(&Var));
_djm_ngcount=_djm_olength-&N+1;
_djm_rowordcount=0;
_djm_larraylen=_djm_olength;
do _djm_i=1 to _djm_larraylen by 1;
alllett[_djm_i]=substr(&Var,_djm_I,1);
end;
do _djm_i=1 to _djm_ngcount by 1;
_djm_ng[_djm_i]=CAT(
%DO I=1 %TO &N %BY 1;
%IF &I^=&N %THEN
%DO;
alllett[%EVAL(&I-1)+_djm_i],
%END;
%ELSE
%DO;
alllett[%EVAL(&I-1)+_djm_i]
%END;
%END;
);
end;
run;
%END;
%exit:
%mend ngramdsetletter;
%macro ngramdsetword(Dataset=,Outdata=work.ngrammed,Var=_DJM_NONE,N=2,NgramVar=Ngram,Rollover=N,DorV=D,Delimiters=%STR( ),modifiers=o);
%local MaxNumofwords MaxLengthofwords NumofNgrams LengthofNgrams NumofROWords Error I;
%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));
%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
Data _null_;
set &Dataset end=_djm_eof;
length _djm_wordlength 8 _djm_wordlengthstore 8 _djm_wordnumber 8 _djm_wordnumberstore 8;
retain _djm_wordlength _djm_wordlengthstore _djm_wordnumber _djm_wordnumberstore;
if _n_=1 then
do;
_djm_wordlength=1;
_djm_wordlengthstore=1;
_djm_wordnumber=1;
_djm_wordnumberstore=1;
end;
_djm_wordnumber=countw(&Var,"&delimiters","&modifiers");
IF _djm_wordnumber>_djm_wordnumberstore THEN
_djm_wordnumberstore=_djm_wordnumber;
IF _djm_wordnumber<&N then
call symput('Error','ERROR');
do _djm_I= 1 to _djm_wordnumber;
_djm_wordlength=length(scan(&Var,_djm_I,"&delimiters","&modifiers"));
IF _djm_wordlength>_djm_wordlengthstore THEN
_djm_wordlengthstore=_djm_wordlength;
end;
if _djm_eof then
do;
call symput('MaxNumofwords',put(_djm_wordnumberstore,best12.));
call symput('MaxLengthofwords',put(_djm_wordlengthstore,best12.));
end;
run;
%IF &Error=ERROR %THEN
%DO;
%PUT ERROR: A record for the variable &Var contains less words than the number of N grams requested;
%PUT ERROR: Aborting...;
%GOTO exit;
%END;
%IF &N=1 %THEN
%LET Rollover=N;
%IF &Rollover=Y %THEN
%DO;
%LET NumofNgrams=%EVAL(&MaxNumofwords);
%LET LengthofNGrams=%EVAL((&MaxLengthofwords*&N)+(&N-1)); 
%LET NumofROWords=%EVAL(&N-1);
%END;
%ELSE
%DO;
%LET NumofNGrams=%EVAL(&MaxNumofwords-&N+1); 
%LET LengthofNGrams=%EVAL((&MaxLengthofwords*&N)+(&N-1)); 
%LET NumofROWords=0;
%END;
%IF &Rollover=Y %THEN
%DO;
Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
set &Dataset;
length _djm_ngcount 8 _djm_owordcount 8 _djm_rowordcount 8 _djm_warraylen 8
%DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I $&LengthofNGrams
%END;
;
array rowords {&NumofROWords} $&maxlengthofwords _temporary_;
array allwords {%EVAL(&maxnumofwords+&NumofROWords)} $&maxlengthofwords _temporary_;
array _djm_NG {&NumofNGrams} $&lengthofNgrams %DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I
%END;
;
IF _N_=1 THEN
DO;
_djm_owordcount=countw(&Var,"&delimiters","&modifiers");
_djm_ngcount=_djm_owordcount-&N+1;
_djm_rowordcount=0;
_djm_warraylen=_djm_owordcount;
do _djm_i=1 to _djm_warraylen by 1;
allwords[_djm_i]=scan(&Var,_djm_I,"&delimiters","&modifiers");
end;
END;
ELSE
DO;
_djm_owordcount=countw(&Var,"&delimiters","&modifiers");
_djm_ngcount=_djm_owordcount;
_djm_rowordcount=&numofROwords;
_djm_warraylen=_djm_owordcount+&NumofROWords;
do _djm_i=1 to &NumofROWords by 1;
allwords[_djm_i]=rowords[_djm_i];
end;
do _djm_i=%EVAL(&NumofROWords+1) to _djm_warraylen by 1;
allwords[_djm_i]=scan(&Var,_djm_I-&NumofROWords,"&delimiters","&modifiers");
end;
END;
do _djm_i=1 to _djm_ngcount by 1;
_djm_ng[_djm_i]=CATX(' ',
%DO I=1 %TO &N %BY 1;
%IF &I^=&N %THEN
%DO;
allwords[%EVAL(&I-1)+_djm_i],
%END;
%ELSE
%DO;
allwords[%EVAL(&I-1)+_djm_i]
%END;
%END;
);
end;
do _djm_i=1 to &NumofROWords by 1;
rowords[_djm_i]=scan(&Var,_djm_owordcount-&NumofROWords+_djm_i,"&delimiters","&modifiers");
end;
run;
%END;
%ELSE
%DO;
Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
set &Dataset;
length _djm_ngcount 8 _djm_owordcount 8 _djm_rowordcount 8 _djm_warraylen 8
%DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I $&LengthofNGrams
%END;
;
array allwords {%EVAL(&maxnumofwords+&NumofROWords)} $&maxlengthofwords _temporary_;
array _djm_NG {&NumofNGrams} $&lengthofNgrams %DO I=1 %TO &NumofNGrams %BY 1;
&NgramVar.&I
%END;
;
_djm_owordcount=countw(&Var,"&delimiters","&modifiers");
_djm_ngcount=_djm_owordcount-&N+1;
_djm_warraylen=_djm_owordcount;
do _djm_i=1 to _djm_warraylen by 1;
allwords[_djm_i]=scan(&Var,_djm_I,"&delimiters","&modifiers");
end;
do _djm_i=1 to _djm_ngcount by 1;
_djm_ng[_djm_i]=CATX(' ',
%DO I=1 %TO &N %BY 1;
%IF &I^=&N %THEN
%DO;
allwords[%EVAL(&I-1)+_djm_i],
%END;
%ELSE
%DO;
allwords[%EVAL(&I-1)+_djm_i]
%END;
%END;
);
end;
run;
%END;
%exit:
%mend ngramdsetword;
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
%macro ngramwordsummary(Dataset=,Outdata=work.NGramSummary,Var=_DJM_NONE,Rollover=Y,N=2,NgramVar=Ngram,Delimiters=%STR( ),modifiers=o,exp=12);
%local I Countstat NumofNGrams;
%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));
PROC SQL noprint;
SELECT MAX(countw(&Var,"&delimiters","&modifiers"))
into :Countstat
FROM &DataSet;
QUIT;
%IF Rollover=Y %THEN %LET NumofNgrams=&Countstat;
%ELSE %LET NumofNGrams=%EVAL(&Countstat-&N+1);
%ngramdsetword(Dataset=&Dataset,Outdata=_djm_temp,Var=&Var,N=&N,NgramVar=&NgramVar,DorV=V,Delimiters=&Delimiters,modifiers=&modifiers,Rollover=&Rollover);
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
%mend ngramwordsummary;
%macro em_setup_initial_dsets(Linkvars=,
mstart=_DJM_NONE,
ustart=_DJM_NONE,
mmstart=_DJM_NONE,
mustart=_DJM_NONE,
model=3,
P_hatInitial=);
data work._djm_estimates work._djm_maximisation(keep= P_hat %pl(&Linkvars,m_) %pl(&Linkvars,u_) 
%IF &MODEL=3 %THEN %pl(&Linkvars,mm_) %pl(&Linkvars,mu_); 
);
length converge $6;
Iteration=0;
Epsilon=1;
P_hat=&P_hatInitial;
Converge='no';
%tvtdl(%pl(&Linkvars,m_),&mstart,%STR(=),%STR(;));
%tvtdl(%pl(&Linkvars,u_),&ustart,%STR(=),%STR(;));
%IF &model=3 %THEN
%DO;
%tvtdl(%pl(&Linkvars,mm_),&mmstart,%STR(=),%STR(;));
%tvtdl(%pl(&Linkvars,mu_),&mustart,%STR(=),%STR(;));
%END;
run;
%mend em_setup_initial_dsets;
%macro expect_2_compile	(LinkVar=,dataset=_DJM_NONE, countvar=_DJM_NONE);
data work._djm_expectation (keep = &countvar g1 g0 %pl(&LinkVar,g1T_) %pl(&LinkVar,g0T_)) /PGM=work._djm_expectation;
set &dataset;
if _n_ = 1 then
set work._djm_maximisation;
;
;
array MProb {*} %pl(&LinkVar,m_);
array UProb {*} %pl(&LinkVar,u_);
;
array Theta {*}  &LinkVar;
;
array g1_Theta{*} %pl(&LinkVar, g1T_);
array g0_Theta{*} %pl(&LinkVar, g0T_);
;
TotMTerm = 1;
TotUTerm = 1;
do i = 1 to dim(MProb);
TotMTerm = TotMTerm * ((MProb[i]**Theta[i])*((1-MProb[i])**(1-Theta[i])));
TotUTerm = TotUTerm * ((UProb[i]**Theta[i])*((1-UProb[i])**(1-Theta[i])));
end;
TotMTerm = TotMTerm;
TotUTerm = TotUTerm;
*Final calculation of g data;
g1 = P_hat*TotMterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
g0 = (1-P_hat)*TotUterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
do i = 1 to dim(Theta);
g1_Theta[i] = g1*Theta[i];
g0_Theta[i] = g0*Theta[i];
end;
run;
%mend expect_2_compile;
%macro expect_3_compile	(LinkVar=,dataset=_DJM_NONE,countvar=_DJM_NONE);
data  work._djm_expectation (keep = &countvar g1 g0 %PL(&LinkVar,g1T_) 
%PL(&LinkVar,g0T_) 
%PL(&LinkVar,g1mT_) 
%PL(&LinkVar,g0mT_) ) /PGM=work._djm_expectation;
set &dataset;
if _n_ = 1 then
set work._djm_maximisation;
array MProb {*} %PL(&LinkVar, m_);
array UProb {*} %PL(&LinkVar, u_);
array MissingMProb {*} %PL(&LinkVar, mm_);
array MissingUProb {*} %PL(&LinkVar, mu_);
array Theta {*}  &LinkVar;
array g1_Theta{*} %PL(&LinkVar, g1T_);
array g0_Theta{*} %PL(&LinkVar, g0T_);
array g1miss_Theta{*} %PL(&LinkVar, g1mT_);
array g0miss_Theta{*} %PL(&LinkVar, g0mT_);
*Calculate Expected Gj;
TotMTerm = 1;
TotUTerm = 1;
do i = 1 to dim(MProb);
IF Theta[i]=0 THEN
DO;
TotMTerm = TotMTerm * (1-MProb[i]-MissingMProb[i]);
TotUTerm = TotUTerm * (1-UProb[i]-MissingUProb[i]);
END;
IF Theta[i]=1 THEN
DO;
TotMTerm = TotMTerm * MProb[i];
TotUTerm = TotUTerm * UProb[i];
END;
IF missing(Theta[i]) THEN
DO;
TotMTerm = TotMTerm * MissingMProb[i];
TotUTerm = TotUTerm * MissingUProb[i];
END;
end;
*Final calculation of g data;
g1 = P_hat*TotMterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
g0 = (1-P_hat)*TotUterm/(P_hat*TotMterm + (1-P_hat)*TotUterm);
do i = 1 to dim(Theta);
IF Theta[i]=0 THEN
DO;
g1_Theta[i] = 0;
g0_Theta[i] = 0;
g1miss_Theta[i] = 0;
g0miss_Theta[i] = 0;
END;
ELSE IF Theta[i]=1 THEN
DO;
g1_Theta[i] = g1;
g0_Theta[i] = g0;
g1miss_Theta[i] = 0;
g0miss_Theta[i] = 0;
END;
ELSE IF missing(Theta[i]) THEN
DO;
g1_Theta[i] = 0;
g0_Theta[i] = 0;
g1miss_Theta[i] = g1;
g0miss_Theta[i] = g0;
END;
end;
run;
%mend expect_3_compile;
%macro icarus_em	
( 	
LinkVars=_DJM_NONE, 
CountVar=_DJM_NONE, 
mstart=_DJM_NONE, 
ustart=_DJM_NONE, 
mmstart=_DJM_NONE, 
mustart=_DJM_NONE, 
p_hatinitial=_DJM_NONE, 
epsconverge=0.001, 
maxiter=1000, 
mdata=work.mprobs, 
udata=work.uprobs, 
mmdata=work.mmprobs, 
mudata=work.muprobs, 
dset=_DJM_NONE, 
model=3 
);
%local Converge Epsilon Iteration;
%IF &mstart^=_DJM_NONE AND &mstart^=%STR() AND %Numordset(&mstart)=D %THEN
%DO;
%IF %dsetvalidate(&mstart)=0 %THEN
%DO;
%PUT ERROR: &mstart does not exist;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%IF %varsindset(&mstart,&LinkVars)= 0 %THEN
%DO;
%PUT ERROR: All Linkvars are not found in &mstart;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%let mstart=%obtomacro(&mstart,&LinkVars,1);
%END;
%IF &ustart^=_DJM_NONE AND &ustart^=%STR() AND %Numordset(&ustart)=D %THEN %DO;
%IF %dsetvalidate(&ustart)=0 %THEN
%DO;
%PUT ERROR: &ustart does not exist;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%IF %varsindset(&ustart,&LinkVars)= 0 %THEN
%DO;
%PUT ERROR: All Linkvars are not found in &ustart;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%let ustart=%obtomacro(&ustart,&LinkVars,1);
%END;
%IF &mmstart^=_DJM_NONE AND &mmstart^=%STR() AND %Numordset(&mmstart)=D %THEN %DO;
%IF %dsetvalidate(&mmstart)=0 %THEN
%DO;
%PUT ERROR: &mmstart does not exist;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%IF %varsindset(&mmstart,&LinkVars)= 0 %THEN
%DO;
%PUT ERROR: All Linkvars are not found in &mmstart;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%let mmstart=%obtomacro(&mmstart,&LinkVars,1);
%END;
%IF &mustart^=_DJM_NONE AND &mustart^=%STR() AND %Numordset(&mustart)=D %THEN %DO;
%IF %dsetvalidate(&mustart)=0 %THEN
%DO;
%PUT ERROR: &mustart does not exist;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%IF %varsindset(&mustart,&LinkVars)= 0 %THEN
%DO;
%PUT ERROR: All Linkvars are not found in &mustart;
%PUT ERROR: Aborting icarus_em...;
%GOTO END_EM3;
%END;
%let mustart=%obtomacro(&mustart,&LinkVars,1);
%END;
%PUT NOTE: **********************************************************************;
%PUT NOTE: CREATING INITIAL DATA SETS FOR EXPECTATION-MAXIMISATION ALGORITHM;
%PUT NOTE: **********************************************************************;
%PUT NOTE: %report_date;
%PUT NOTE: %report_time;
%em_setup_initial_dsets(LinkVars=&LinkVars,
mstart=&mstart,
ustart=&ustart,
mmstart=&mmstart,
mustart=&mustart,
model=&model,
P_hatInitial=&P_hatInitial);
%PUT NOTE: **********************************************************************;
%PUT NOTE: INITIAL DATA SETS CREATED;
%PUT NOTE: **********************************************************************;
%PUT NOTE: %report_date;
%PUT NOTE: %report_time;
%PUT NOTE: *************************************************;
%PUT NOTE: COMPILING EXPECTATION AND MAXIMISATION CODE;
%PUT NOTE: *************************************************;
%PUT NOTE: %report_date;
%PUT NOTE: %report_time;
%IF &MODEL=2 %THEN
%DO;
%EXPECT_2_COMPILE(LinkVar=&LinkVars,dataset=&DSet,countvar=&countvar);
%MAXIMISE_2_COMPILE(LinkVar=&LinkVars,EpsConverge=&EpsConverge);
%END;
%ELSE %IF &MODEL=3 %THEN
%DO;
%EXPECT_3_COMPILE(LinkVar=&LinkVars,dataset=&DSet,countvar=&countvar);
%MAXIMISE_3_COMPILE(LinkVar=&LinkVars,EpsConverge=&EpsConverge);
%END;
%ELSE
%DO;
%PUT ERROR: INCORRECT MODEL SPECIFICATION. MODEL ARGUMENT MUST BE 2 OR 3. ABORTING...;
%GOTO END_EM3;
%END;
%PUT NOTE: *************************************************;
%PUT NOTE: EXPECTATION AND MAXIMISATION STEPS COMPILED;
%PUT NOTE: *************************************************;
%PUT NOTE: %report_date;
%PUT NOTE: %report_time;
%PUT NOTE: *************************************************;
%PUT NOTE: *********     RUNNING EM ALGORITHM!     *********;
%PUT NOTE: *************************************************;
%do %until (&Converge=yes or &Converge=KABOOM or &Epsilon=. or &Iteration=&MaxIter);
%RUN_EXPECTATION;
%RUN_MAXIMISATION(Linkvar=&LinkVars,model=&model,countvar=&CountVar);
%put NOTE: Epsilon is &Epsilon after &iteration iterations. TIME: %report_time;
%end;
;
%IF %UPCASE(&CONVERGE)=YES %THEN
%PUT NOTE: ESTIMATES CONVERGED AFTER &ITERATION ITERATIONS.;
%ELSE %IF %UPCASE(&CONVERGE)=NO %THEN
%PUT NOTE: NO CONVERGENCE AFTER &ITERATION ITERATIONS. EPSILON IS &EPSILON.;
%ELSE %IF %UPCASE(&CONVERGE)=KABOOM %THEN
%PUT NOTE: KABOOM!!!! I DONT KNOW WHAT YOU DID, BUT YOU BROKE IT!;
PROC PRINT DATA = work._djm_ESTIMATES NOOBS;
%IF %UPCASE(&CONVERGE)=YES %THEN
%DO;
TITLE "PARAMETER ESTIMATES: CONVERGENCE AFTER &ITERATION ITERATIONS";
%END;
%ELSE %IF %UPCASE(&CONVERGE)=NO %THEN
%DO;
TITLE "PARAMETER ESTIMATES: CONVERGENCE CRITERIA NOT ACHIEVED AFTER &ITERATION ITERATIONS";
%END;
%ELSE %IF %UPCASE(&CONVERGE)=KABOOM %THEN
%DO;
TITLE "THIS IS THE WAY THE WORLD ENDS: NOT WITH A BANG BUT WITH MANY MISSING VARIABLES";
%END;
RUN;
%IF %UPCASE(&CONVERGE)=YES %THEN
%DO;
data 
&mdata.(keep=%PL(&LinkVars,m_) rename=(%tvtdl(%PL(&LinkVars,m_),&LinkVars,%STR(=),%STR( ))))
&udata.(keep=%PL(&LinkVars,u_) rename=(%tvtdl(%PL(&LinkVars,u_),&LinkVars,%STR(=),%STR( ))))
%if &model=3 %THEN %DO;
&mudata.(keep=%PL(&LinkVars,mm_) rename=(%tvtdl(%PL(&LinkVars,mm_),&LinkVars,%STR(=),%STR( ))))
&mmdata.(keep=%PL(&LinkVars,mu_) rename=(%tvtdl(%PL(&LinkVars,mu_),&LinkVars,%STR(=),%STR( ))));
%END;
;
set work._djm_estimates end=eof;
if eof then
output;
run;
%END;
%deleteprograms(work._djm_expectation work._djm_maximisation work._djm_estimates);
%deletedsets(work._djm_estimates work._djm_maximisation work._djm_expectation);
%END_EM3:
%IF &CONVERGE=KABOOM %THEN
%DO;
%PUT NOTE:*********************************************************************************;
%PUT NOTE: ALAS! NOT EVERYTHING TURNED OUT QUITE LIKE WE HAD PLANNED!;
%PUT NOTE:*********************************************************************************;
%END;
%mend icarus_em;
%macro maximise_2_compile(LinkVar=,EpsConverge=);
data work._djm_maximisation (keep =  %pl(&LinkVar,m_) %pl(&LinkVar,u_) P_hat) /PGM=work._djm_maximisation;
set work._djm_maximisation;
*Parameter arrays;
array MProb {*}  %pl(&LinkVar, m_);
array UProb {*} %pl(&LinkVar, u_);
array g1_Theta[*] %pl(&LinkVar, g1T_);
array g0_Theta[*] %pl(&LinkVar, g0T_);
*Calculate M and U Probability estimates for this iteration;
do i = 1 to dim(MProb);
MProb[i] = g1_Theta[i]/g1;
UProb[i] = g0_Theta[i]/g0;
end;
*Calculate match rate;
P_hat = g1/(g0+g1);
run;
data work._djm_estimates /PGM=work._djm_estimates;
set work._djm_estimates work._djm_maximisation;
array AllProb {*} %pl(&LinkVar, m_) %pl(&LinkVar, u_) p_hat;
*temporary array containing the lag of AllProb;
array  LagAP {*} %pl(&LinkVar, Lm_) %pl(&LinkVar, Lu_) Lp_hat;
do i = 1 to dim(AllProb);
LagAP[i] = lag(AllProb[i]);
end;
if iteration = . then
do;
iteration = _n_ - 1;
Epsilon = 0;
do i = 1 to dim(AllProb);
Epsilon = Epsilon + (AllProb[i] - LagAP[i])**2;
end;
drop i;
Epsilon = sqrt(Epsilon);
call symput('Epsilon',trim(left(put(Epsilon,BEST12.))));
call symput('iteration',trim(left(put(iteration,8.))));
if Epsilon<&EpsConverge and Epsilon^=. then
do;
Converge = 'yes';
call symput('Converge',Converge);
end;
else if Epsilon^=. then
Converge ='no';
else if Epsilon=. then
do;
Converge ='KABOOM';
call symput('Converge',Converge);
end;
end;
drop %pl(&LinkVar, Lm_) %pl(&LinkVar,Lu_) Lp_hat;
run;
%mend maximise_2_compile;
%macro maximise_3_compile(linkVar=,EpsConverge=);
data _djm_maximisation (keep =  %pl(&LinkVar, m_)
%pl(&LinkVar, u_)
%pl(&LinkVar, mm_) 
%pl(&LinkVar, mu_)
P_hat) /pgm=work._djm_maximisation;
set work._djm_maximisation;
*Parameter arrays;
array MProb {*}  %pl(&LinkVar, m_);
array UProb {*} %pl(&LinkVar, u_);
array MissingMProb {*} %pl(&LinkVar, mm_);
array MissingUProb {*} %pl(&LinkVar, mu_);
array g1_Theta[*] %pl(&LinkVar, g1T_);
array g0_Theta[*]%pl(&LinkVar, g0T_);
array g1miss_Theta{*} %pl(&LinkVar, g1mT_);
array g0miss_Theta{*} %pl(&LinkVar, g0mT_);
*Calculate M and U Probability estimates for this iteration;
do i = 1 to dim(MProb);
MProb[i] = g1_Theta[i]/g1;
UProb[i] = g0_Theta[i]/g0;
MissingMProb[i] = g1miss_Theta[i]/g1;
MissingUProb[i] = g0miss_Theta[i]/g0;
end;
*Calculate match rate;
P_hat = g1/(g0+g1);
run;
data work._djm_estimates /pgm=work._djm_estimates;
set work._djm_estimates work._djm_maximisation;
array AllProb {*} %pl(&LinkVar, m_) %pl(&LinkVar, u_) %pl(&LinkVar, mm_) %pl(&LinkVar, mu_) p_hat;
*temporary array containing the lag of AllProb;
array  LagAP {*} %pl(&LinkVar, Lm_) %pl(&LinkVar, Lu_) %pl(&LinkVar, Lmm_) %pl(&LinkVar, Lmu_) Lp_hat;
do i = 1 to dim(AllProb);
LagAP[i] = lag(AllProb[i]);
end;
if missing(iteration) then
do;
iteration = _n_ - 1;
Epsilon = 0;
do i = 1 to dim(AllProb);
Epsilon = Epsilon + (AllProb[i] - LagAP[i])**2;
end;
drop i;
Epsilon = sqrt(Epsilon);
call symput('Epsilon',trim(left(put(Epsilon,BEST12.))));
call symput('iteration',trim(left(put(iteration,8.))));
if Epsilon<&EpsConverge and Epsilon^=. then
do;
Converge = 'yes';
call symput('Converge',Converge);
end;
else if Epsilon^=. then
Converge ='no';
else if Epsilon=. then
do;
Converge ='KABOOM';
call symput('Converge',Converge);
end;
end;
drop %pl(&LinkVar, Lm_) %pl(&LinkVar, Lu_) %pl(&LinkVar, Lmm_) %pl(&LinkVar, Lmu_) Lp_hat;
run;
%mend maximise_3_compile;
%macro run_expectation;
data pgm=work._djm_expectation;
run;
%mend run_expectation;
%macro run_maximisation(linkvar=,model=3,countvar=);
proc summary data=work._djm_expectation;
var g1 g0 %pl(&LinkVar, g1T_) %pl(&linkvar, g0T_)
%IF &model=3 %THEN
%DO;
%pl(&linkvar, g1mT_) %pl(&linkvar, g0mT_)
%END;
;
weight &countvar;
output out = work._djm_maximisation (drop = _type_ _freq_) sum =;
run;
data pgm=work._djm_maximisation;
run;
data pgm=work._djm_estimates;
run;
%mend run_maximisation;
%macro djm_algo1(indata=,
outdata=,
ida=,
idb=,
weightvar=,
exp=12);
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
%macro djm_avgnoise(indata=,
outdata=,
ida=,
idb=,
weightvar=,
locfamvar=,
avgnoisevar=,
exp=12);
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
else
do;
_djm_hash1.find();
_djm_hash2.find();
&avgnoisevar = ((_djm_sum_a/_djm_num_a)+(_djm_sum_b/_djm_num_b));
output;
end;
run;
%mend djm_avgnoise;
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
%macro djmassignment(dset=_DJM_NONE,
			outdata=work.FINAL_ASSIGNMENT,
			qualstatsout=work.QUALITYSTATS,
			ida=_DJM_NONE,
			idb=_DJM_NONE,
			weightvar=_DJM_NONE,
			stopafter=C,
			addgrade=N,
			gradevar=grade,
			qualstats=Y,
			exp=12,
			sasfileoption=N);
	%let stopafter=%UPCASE(%SUBSTR(&stopafter,1,1));
	%let qualstats=%UPCASE(%SUBSTR(&qualstats,1,1));
	%let addgrade=%UPCASE(%SUBSTR(&addgrade,1,1));
	%let sasfileoption=%UPCASE(%SUBSTR(&sasfileoption,1,1));

	/***************************
	ERROR CHECKING
	***************************/
	%IF (&stopafter^=A AND &stopafter ^= B AND &stopafter ^= C) %THEN
		%DO;
			%PUT ERROR: The stopafter parameter must be set to either;
			%PUT ERROR: A, B, or C;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Has indata been supplied? */
	%IF &dset=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: The data set needs to be specified via the indata argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &ida=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the first ID variable via the ida argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &idb=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the second ID variable via the idb argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF &weightvar=_DJM_NONE %THEN
		%DO;
			%PUT ERROR: You must supply the weight variable via the weightvar argument;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Does indata exist? */
	%IF %dsetvalidate(&dset)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* Are variables in data set */
	%IF %varsindset(&dset,&ida)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF %varsindset(&dset,&idb)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	%IF %varsindset(&dset,&weightvar)=0 %THEN
		%DO;
			%PUT ERROR: Data Set &dset does not exist;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/**************************
	ALGORITHM PART
	**************************/
	%local run_category workfile_size1 workfile_size2;
	%local records_linked records_remain roundnumber;
	%local totala totalb totalc grandtotal;
	%let totala = 0;
	%let totalb = 0;
	%let totalc = 0;
	%let grandtotal = 0;

	/*************************************************************/
	/* Step 1: Run algorithm one: Output results to _djm_group_A */
	/*************************************************************/

	/* Define _djm_temp_workfile as those records not eliminated
	by the application of algo 1.  This is achieved via the application
	of _djm_recorddeleter */
	%djm_algo1(	indata=&dset,
		outdata=work._djm_group_a,
		ida=&ida,
		idb=&idb,
		weightvar=&weightvar,
		exp=&exp);

	%djm_rdeleter(	deleter_dset=work._djm_group_a,
		deletee_dset=&dset,
		outdata=work._djm_temp_workfile,
		ida=&ida,
		idb=&idb,
		keepvars=&weightvar,
		exp=&exp);

	%let workfile_size1=0;
	%IF %dsetvalidate(work._djm_temp_workfile) %then %let workfile_size2=%numofobs(work._djm_temp_workfile);
	%else %let workfile_size2=0;
	%IF %dsetvalidate(work._djm_group_a) %then %let records_linked=%numofobs(work._djm_group_a);
	%else %let records_linked=0;
	%let totala=&records_linked;
	%let records_remain=&workfile_size2;
	%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

	/*****************************************************************/
	/* Step 2: Continue running algorithm one until no change in size*/
	/*****************************************************************/
	%DO %WHILE ((&stopafter^=A) AND (&workfile_size1^=&workfile_size2));
		%djm_algo1(	indata=work._djm_temp_workfile,
			outdata=work._djm_group_b_hold,
			ida=&ida,
			idb=&idb,
			weightvar=&weightvar,
			exp=&exp);

		PROC APPEND base=work._djm_group_b data=work._djm_group_b_hold;
		run;

		%djm_rdeleter(deleter_dset=work._djm_group_b_hold,
			deletee_dset=work._djm_temp_workfile,
			outdata=work._djm_temp_workfile,
			ida=&ida,
			idb=&idb,
			keepvars=&weightvar,
			exp=&exp);

		%deletedsets(work._djm_group_b_hold);
		%let workfile_size1 = %numofobs(work._djm_temp_workfile);
		%let records_linked=%EVAL(&totala+%numofobs(work._djm_group_b));
		%let records_remain=&workfile_size1;
		%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

		%IF &workfile_size1 ^= &workfile_size2 %THEN
			%DO;
				%let workfile_size2 = &workfile_size1;
				%let workfile_size1 = 0;
			%END;
	%END;

	%IF &stopafter^=A %THEN
		%IF %dsetvalidate(work._djm_group_b) %then %let totalb=%numofobs(work._djm_group_b);
		%else %let totalb=0;

	/*****************************************************************
	Step 3: Loop algorithms 2, deleter and looping 1 + deleter until no change,
	until records left = 0
	******************************************************************/
	%DO %WHILE ((&stopafter^=B AND &stopafter^=A) AND (&workfile_size2^=0));

		/* Algo 2 and deletion */
		%djm_algo2(indata=work._djm_temp_workfile,
			outdata=work._djm_group_c_hold,
			ida=&ida,
			idb=&idb,
			weightvar=&weightvar,
			avgnoisevar=_djm_avgnoise,
			locfamvar=_djm_locfam,
			exp=&exp,
			sasfileoption=&sasfileoption);

		PROC APPEND base=work._djm_group_c data=work._djm_group_c_hold;
		run;

		%djm_rdeleter(	deleter_dset=work._djm_group_c_hold,
			deletee_dset=work._djm_temp_workfile,
			outdata=work._djm_temp_workfile,
			ida=&ida,
			idb=&idb,
			keepvars=&weightvar,
			exp=&exp);

		%deletedsets(work._djm_group_c_hold);

		%let workfile_size2=%numofobs(work._djm_temp_workfile);
		%if %dsetvalidate(work._djm_group_c) %then
		%let records_linked=%EVAL(&totala+&totalb+%numofobs(work._djm_group_c));
		%else %let records_linked=%EVAL(&totala+&totalb+0);
		%let records_remain=&workfile_size2;
		%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

		/* Algo 1 loop */
		%DO %WHILE ((&workfile_size1^=&workfile_size2) AND (&workfile_size2^=0));
			%djm_algo1(	indata=work._djm_temp_workfile,
				outdata=work._djm_group_c_hold,
				ida=&ida,
				idb=&idb,
				weightvar=&weightvar,
				exp=&exp);

			PROC APPEND base=work._djm_group_c data=work._djm_group_c_hold;
			run;

			%djm_rdeleter(	deleter_dset=work._djm_group_c_hold,
				deletee_dset=work._djm_temp_workfile,
				outdata=work._djm_temp_workfile,
				ida=&ida,
				idb=&idb,
				keepvars=&weightvar,
				exp=&exp);

			%deletedsets(work._djm_group_c_hold);

			%let workfile_size1 = %numofobs(work._djm_temp_workfile);
			%let records_linked=%EVAL(&totala+&totalb+%numofobs(work._djm_group_c));
			%let records_remain=&workfile_size1;
			%PUT NOTE: &records_linked pairs linked. &records_remain potential pairs remaining;

			%IF &workfile_size1 ^= &workfile_size2 %THEN
				%DO;
					%let workfile_size2 = &workfile_size1;
					%let workfile_size1 = 0;
				%END;
		%END;
	%END;

	/* populating macro totals */
	%IF &stopafter^=B AND &stopafter^=A %THEN %DO;
		%if %dsetvalidate(work._djm_group_c) %then %let totalc=%numofobs(work._djm_group_c);
		%else %let totalc=0;
	%END;
	%IF &stopafter=A %THEN
		%let grandtotal = &totala;
	%ELSE %IF &stopafter=B %THEN
		%let grandtotal = %EVAL(&totala + &totalb);
	%ELSE %IF &stopafter=C %THEN
		%let grandtotal = %EVAL(&totala + &totalb + &totalc);

	/*************************************************************
	Part 4: FINAL MERGING AND TIDY UP
	*************************************************************/
	%deletedsets(work._djm_temp_workfile);

	%IF &addgrade = Y %THEN
		%DO;
			%IF %dsetvalidate(work._djm_group_a) %THEN
				%DO;

					data work._djm_group_a;
						set work._djm_group_a;
						length &gradevar $ 1;
						&gradevar = 'A';
					run;

				%END;

			%IF %dsetvalidate(work._djm_group_b) %THEN
				%DO;

					data work._djm_group_b;
						set work._djm_group_b;
						length &gradevar $ 1;
						&gradevar = 'B';
					run;

				%END;

			%IF %dsetvalidate(work._djm_group_c) %THEN
				%DO;

					data work._djm_group_c;
						set work._djm_group_c;
						length &gradevar $ 1;
						&gradevar = 'C';
					run;

				%END;
		%END;

	%IF %dsetvalidate(&outdata) %THEN %DO;
		%deletedsets(&outdata);
	%END;

	%IF %dsetvalidate(work._djm_group_a) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_a;
			run;

			%deletedsets(work._djm_group_a);
		%END;

	%IF %dsetvalidate(work._djm_group_b) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_b;
			run;

			%deletedsets(work._djm_group_b);
		%END;

	%IF %dsetvalidate(work._djm_group_c) %THEN
		%DO;

			proc append base=&outdata data=work._djm_group_c;
			run;

			%deletedsets(work._djm_group_c);
		%END;

	/*************************************************************
	Part 5: QUALITY STATS
	*************************************************************/
	%IF &QUALSTATS=Y %THEN
		%DO;

			Data &qualstatsout;
				length Info $ 22 Number 8;
				Info = "A Grade";
				Number = &totala;
				output;
				Info = "B Grade";
				Number = &totalb;
				output;
				Info = "C Grade";
				Number = &totalc;
				output;
				Info = "A Grade Percent";
				Number = %SYSEVALF((&totala/&grandtotal)*100);
				output;
				Info = "B Grade Percent";
				Number = %SYSEVALF((&totalb/&grandtotal)*100);
				output;
				Info = "C Grade Percent";
				Number = %SYSEVALF((&totalc/&grandtotal)*100);
					output;
				Info = "Total Records Assigned";
				Number = &grandtotal;
				output;
			run;

		%END;

	%exit:
%mend djmassignment;
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
if _N_<=&num then
do;
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
%macro apderive(DataSet=_DJM_NONE,
LinkVarsA=_DJM_NONE,
LinkVarsB=_DJM_NONE,
OutVars=_DJM_NONE,
Outdata=work.AgreementPattern,
AdditionalKeepVars=_DJM_NONE,
DorV=V,
Case=3,
Comptypes=_DJM_NONE,
Compvals=_DJM_NONE);
%local I J a_Var b_var comparison comp1 comp2;
%local numcheck1 numcheck2 numcheck3 numcheck4 numcheck5;
%local outty_var tempcheck;
%let Comptypes=%UPCASE(&Comptypes);
%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
%IF &Case^=2 AND &Case^=3 %THEN
%DO;
%PUT ERROR: Case must be set equal to 2 or 3;
%PUT ERROR: Case is current set to &Case;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSet)=0 %THEN
%DO;
%PUT ERROR: &DataSet does not exist;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%IF &LinkVarsA=_DJM_NONE OR &LinkVarsB=_DJM_NONE OR &OutVars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply valid values for LinkVarsA, LinkVarsB;
%PUT ERROR: and OutVars...;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%IF %varsindset(&DataSet,&LinkVarsA)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables listed;
%PUT ERROR: in LinkVarsA does not exist in &DataSet;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%IF %varsindset(&DataSet,&LinkVarsB)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables listed;
%PUT ERROR: in LinkVarsB does not exist in &DataSet;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%IF &AdditionalKeepVars^=_DJM_NONE %THEN
%DO;
%IF %varsindset(&DataSet,&AdditionalKeepVars)=0 %THEN
%DO;
%PUT ERROR: At least one of the Additional Keep Variables listed;
%PUT ERROR: in AdditionalKeepVars does not exist in &DataSet;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%END;
%ELSE %let additionalkeepvars =;
%LET numcheck1=%countwords(&LinkVarsA,%STR( ));
%LET numcheck2=%countwords(&LinkVarsB,%STR( ));
%LET numcheck3=%countwords(&Comptypes,%STR( ));
%LET numcheck4=%countwords(&Compvals,%STR( ));
%LET numcheck5=%countwords(&Outvars,%STR( ));
%IF &numcheck1^=&numcheck2 OR &numcheck2^=&numcheck3 OR &numcheck3^=&numcheck4 or &numcheck4^=&numcheck5 %THEN
%DO;
%PUT ERROR: CONFLICTING NUMBER OF PARAMETERS ENTERED.;
%PUT ERROR: There were &numcheck1 LinkVarA members;
%PUT ERROR: There were &numcheck2 LinkVarB members;
%PUT ERROR: There were &numcheck3 Comptypes members;
%PUT ERROR: There were &numcheck4 Compvals members;
%PUT ERROR: There were &numcheck5 Outvars members;
%PUT ERROR: Above parameters must all have the same number of members;
%PUT ERROR: Aborting derivation of agreement patterns...;
%GOTO exit;
%END;
%let I=1;
%do %while(&I<=&numcheck4);
%let tempcheck = %SCAN(&Comptypes,&I,%STR( ));
%IF &tempcheck ^= E AND &tempcheck ^= WI AND &tempcheck ^= JA AND &tempcheck ^= HF 
AND &tempcheck ^= GF AND &tempcheck ^= LF AND &tempcheck ^= CL %THEN
%DO;
%PUT &tempcheck;
%PUT ERROR: Compvals can only include the following:;
%PUT ERROR: E,WI,JA,HF,GF,LF,CL;
%PUT ERROR: Aborting apderive...;
%GOTO exit;
%END;
%LET I = %EVAL(&I + 1);
%END;
Data &outdata(keep=&Outvars &AdditionalKeepVars) %IF &DorV=V %THEN /view=&outdata;;
set &DataSet(keep=&LinkVarsA &LinkVarsB &AdditionalKeepVars);
%IF &Case=2 %THEN
%DO;
%let I=1;
%do %while(&I<=&numcheck1);
%let a_Var = %scan(&LinkVarsA,&I,%str( ));
%let b_Var = %scan(&LinkVarsB,&I,%str( ));
%let comparison = %scan(&Comptypes,&I,%str( ));
%let comp1 = %scan(&Compvals,&I,%str( ));
%let outty_Var = %scan(&OutVars,&I,%STR( ));
%Put &comparison 2;
%IF &comparison = E %THEN
%DO;
IF &a_Var^=&b_var THEN
&outty_Var=0;
ELSE IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=0;
ELSE &outty_Var=1;
%END;
%ELSE %IF &comparison=WI %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=0;
ELSE IF winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
&outty_Var=0;
ELSE &outty_Var=1;
%END;
%ELSE %IF &comparison=JA %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=0;
ELSE IF jaro(&a_Var,&b_Var)<&comp1 THEN
&outty_Var=0;
ELSE &outty_Var=1;
%END;
%ELSE %IF &comparison=HF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=0;
ELSE &outty_var = Highfuzz(&a_Var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=GF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=0;
ELSE &outty_var = Genfuzz(&a_Var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=LF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=0;
ELSE &outty_var = Lowfuzz(&a_Var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=CL %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=0;
ELSE IF complev(&a_var,&b_var)<&comp1 THEN
&outty_var=1;
ELSE &outty_var=0;
%END;
%let I = %eval(&I+1);
%end;
%END;
%ELSE %IF &Case=3 %THEN
%DO;
%let I=1;
%do %while(&I<=&numcheck1);
%let a_Var = %scan(&LinkVarsA,&I,%str( ));
%let b_Var = %scan(&LinkVarsB,&I,%str( ));
%let comparison = %scan(&Comptypes,&I,%str( ));
%let comp1 = %scan(&Compvals,&I,%str( ));
%let outty_Var = %scan(&OutVars,&I,%STR( ));
%IF &comparison=E %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_var);
ELSE IF &a_Var ^= &b_Var THEN
&outty_Var = 0;
ELSE &outty_Var=1;
%END;
%ELSE %IF &comparison=WI %THEN
%DO;
IF missing(&a_Var) or missing(&b_Var) then
call missing(&outty_var);
ELSE IF &a_Var=&b_Var then
&outty_Var=1;
ELSE IF Winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
&outty_Var=0;
ELSE &outty_var=1;
%END;
%ELSE %IF &comparison=JA %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_var);
ELSE IF &a_Var=&b_Var THEN
&outty_Var=1;
ELSE IF Jaro(&a_Var,&b_Var)<&comp1 THEN
&outty_Var=0;
ELSE &outty_var=1;
%END;
%ELSE %IF &comparison=HF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_var);
ELSE IF &a_Var=&b_Var THEN
&outty_var=1;
ELSE &outty_var=highfuzz(&a_var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=GF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_var);
ELSE IF &a_Var=&b_Var THEN
&outty_var=1;
ELSE &outty_var=Genfuzz(&a_var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=LF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_var);
ELSE IF &a_Var=&b_Var THEN
&outty_var=1;
ELSE &outty_var=Lowfuzz(&a_var,&b_Var,&comp1);
%END;
%ELSE %IF &comparison=CL %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
call missing(&outty_Var);
ELSE IF &a_Var=&b_Var THEN
&outty_Var=1;
ELSE IF Complev(&a_Var,&b_Var)<&Comp1 THEN
&outty_Var=1;
ELSE &outty_Var=0;
%END;
%let I = %eval(&I+1);
%END;
%END;
run;
%exit:
%mend apderive;
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
%macro apsummary(dataset=_DJM_NONE,
outdata=work.apsummary,
dropvars=_DJM_NONE,
countvar=count,
DorV=D,
exp=12);
%local vars i dropnum;
%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
%IF &DataSet = _DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply the dataset parameter;
%PUT ERROR: Aborting apsummary...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSet) = 0 %THEN
%DO;
%PUT ERROR: &dataset does not exist;
%PUT ERROR: Aborting apsummary...;
%GOTO exit;
%END;
%IF &dropvars ^= _DJM_NONE %THEN
%DO;
%IF %varsindset(&dropvars) = 0 %THEN
%DO;
%PUT ERROR: All of the dropvars are not found in &dataset;
%PUT ERROR: Aborting apsummary...;
%GOTO exit;
%END;
%END;
%let vars = %UPCASE(%varlistfromdset(&dataset));
%IF &dropvars^=_DJM_NONE %THEN
%DO;
%let I = 1;
%let dropvars=%UPCASE(&dropvars);
%DO %WHILE (%scan(&dropvars,&i,%STR( )) ^= %STR( ));
%let vars = %removewordfromlist(&dropvars,&vars,%str( ));
%EVAL(&I + 1);
%END;
%END;
%HashCount(DataSet=&dataset,
VARS=&vars,
CountVar=&countvar,
DorV=&DorV,
Outdata=&outdata,
exp=&exp);
%exit:
%mend apsummary;
%macro genprob(
Dataset=_DJM_NONE,
ProbVars=_DJM_NONE,
Outdata=work.Probability,
ProbMax=0.99999999,
ProbMin=0.00000001,
positivevalue=1,
WeightVar=_DJM_AP_weight,
exp=12);
%local i varnum a_Var b_Var;
%IF &DataSet=_DJM_NONE %THEN %DO;
%PUT ERROR: You must supply an Agreement Pattern data set or view via the Dataset parameter;
%PUT ERROR: Aborting GenProb Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSet)=0 %THEN %DO;
%PUT ERROR: The Data set &DataSet does not exist;
%PUT ERROR: Aborting GenProb...;
%GOTO exit;
%END;
%IF &ProbVars=_DJM_NONE %THEN %DO;
%LET ProbVars=%varlistfromdset(&DataSet);
%END;
%ELSE %DO;
%IF %varsindset(&DataSet,&ProbVars)=0 %THEN %DO;
%PUT ERROR: The variables you have listed in ProbVars are not all in the data set;
%PUT ERROR: Aborting GenProb...;
%GOTO exit;
%END;
%END;
%IF %varsindset(&DataSet,&WeightVar)=0 %THEN %DO;
%PUT ERROR: The variable you have listed in weightvar: &weightvar, is not in the data set;
%PUT ERROR: Aborting GenProb...;
%GOTO exit;
%END;
%LET ProbVars = %removewordfromlist(&weightvar,&ProbVars);
%LET varnum=%countwords(&ProbVars,%STR( ));
%local plprobvars plweightvar plallvars allvars;
%let plprobvars = %PL(&probvars,_ic_);
%let plweightvar = %PL(&weightvar,_ic_);
%let plallvars = &plprobvars &plweightvar;
%let allvars = &probvars &weightvar;
Data &outdata(keep=&ProbVars);
set &dataset(rename = ( %tvtdl(&allvars,&plallvars,%STR(=),%STR( )))) end=_djm_eof;
length _djm_total 8 
%let I=1;
%do %while(&I<=&varnum);
%scan(&probvars,&i,%STR( )) 8 
_djm_var&i.count 8 
%LET I=%EVAL(&I+1);
%END;
;
retain _djm_total
%let I=1;
%do %while(&I<=&varnum);
_djm_var&i.count 
%LET I=%EVAL(&I+1);
%END;
;
IF _N_=1 then do;
_djm_total=0;
%let I=1;
%do %while(&I<=&varnum);
_djm_var&i.count=0;
%LET I=%EVAL(&I+1);
%END;
end;
_djm_total=_djm_total+_ic_&weightvar;
%let I=1;
%do %while(&I<=&varnum);
%let a_Var = %scan(&PlProbVars,&I,%str( ));
IF &a_Var=&positivevalue THEN _djm_var&i.count=_djm_var&i.count+_ic_&weightvar;
%LET I=%EVAL(&I+1);
%END;
if _djm_eof then do;
%let I=1;
%do %while(&I<=&varnum);
%let a_Var = %scan(&ProbVars,&I,%str( ));
&a_Var=_djm_var&i.count/_djm_total;
if &a_Var>&ProbMax then &a_Var=&ProbMax;
else if &a_Var<&ProbMin then &a_Var=&ProbMin;
%LET I=%EVAL(&I+1);
%END;
output;
stop;
end;
run;
%exit:
%mend genprob;
%macro genweight(MData=_DJM_NONE,
UData=_DJM_NONE,
MissMData=_DJM_NONE,
MissUData=_DJM_NONE,
outdata=work.Weightfile,
Weighttype=1);
%local i MProbVars UProbVars MissMProbVars MissUProbVars varnum Mvar Uvar MissMVar MissUVar outVar;
%local RNProbVars1 RNProbVars2 RNProbVars3 RNProbVars4 NProbVars1 NProbVars2 NProbVars3 NProbVars4;
%IF &Weighttype^=1 AND &Weighttype^=2 AND &Weighttype^=3 AND &Weighttype^=4 %THEN
%DO;
%PUT ERROR: The Weighttype parameter must be equal to either 1, 2 or 3;
%PUT ERROR: Aborting Weight Generation...;
%GOTO exit;
%END;
%IF &weighttype^=4 %THEN
%DO;
%IF %DSETVALIDATE(&MData)=0 %THEN
%DO;
%PUT ERROR: M Probability Data Set &MData does not exist;
%PUT ERROR: Aborting Weight Generation...;
%GOTO exit;
%END;
%END;
%IF %DSETVALIDATE(&UData)=0 %THEN
%DO;
%PUT ERROR: U Probability Data Set &UData does not exist;
%PUT ERROR: Aborting Weight Generation...;
%GOTO exit;
%END;
%IF &weighttype^=4 %THEN
%DO;
%let MProbVars=%varlistfromdset(&MData);
%END;
%let UProbVars=%varlistfromdset(&UData);
%IF &MProbVars^=&UProbVars AND &weighttype^=4 %THEN
%DO;
%PUT ERROR: M Probability data set and U Probability data set contain different variables;
%PUT ERROR: Aborting Weight Generation...;
%GOTO exit;
%END;
%IF &weighttype^=4 %THEN
%let varnum=%countwords(&MProbVars,%STR( ));
%ELSE %let varnum=%countwords(&UProbVars,%STR( ));
%IF &Weighttype=3 %THEN
%DO;
%IF (&MissMData^=_DJM_NONE AND &MissUData=_DJM_NONE) OR (&MissMData=_DJM_NONE AND &MissUData^=_DJM_NONE) %THEN
%DO;
%PUT ERROR: You cannot supply only one of MissMData and MissUData;
%PUT ERROR: Either supply both, or none at all;
%PUT ERROR: Aborting Weight Generator...;
%GOTO exit;
%END;
%let MissMProbVars=%varlistfromdset(&MissMData);
%let MissUProbVars=%varlistfromdset(&MissUData);
%IF &MissMProbVars^=&MissUProbVars AND &MissMProbVars^=&MProbVars %THEN
%DO;
%PUT ERROR: Probability data sets contain different variables/different number of variables;
%PUT ERROR: Aborting Weight Generation...;
%GOTO exit;
%END;
%END;
%IF &Weighttype=1 %THEN
%DO;
%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
Data &outdata(keep=&MProbVars);
_djm_point=1;
set &MData(rename=(&RNProbVars1)) point=_djm_point;
set &UData(rename=(&RNProbVars2)) point=_djm_point;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&MProbVars,&I,%STR( ));
&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=0;
%LET I=%EVAL(&I+1);
%END;
output;
stop;
run;
%END;
%ELSE %IF &Weighttype=2 %THEN
%DO;
%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
Data &outdata(keep=&MProbVars);
_djm_point=1;
set &MData(rename=(&RNProbVars1)) point=_djm_point;
set &UData(rename=(&RNProbVars2)) point=_djm_point;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&MProbVars,&I,%STR( ));
&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&MProbVars,&I,%STR( ));
&outvar=log((1-_djm_MVar&I)/(1-_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
stop;
run;
%END;
%ELSE %IF &Weighttype=3 %THEN
%DO;
%let MProbVars=%varlistfromdset(&MData);
%let UProbVars=%varlistfromdset(&UData);	
%let MissMProbVars=%varlistfromdset(&MissMData);
%let MissUProbVars=%varlistfromdset(&MissUData);
%let NProbVars1=%repeaterandnum(_djm_MVar,&varnum,%STR( ));
%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
%let NProbVars3=%repeaterandnum(_djm_MissM_Var,&varnum,%STR( ));
%let NProbVars4=%repeaterandnum(_djm_MissU_Var,&varnum,%STR( ));
%let RNProbVars1=%tvtdl(&MProbVars,&NProbVars1,%STR(=),%STR( ));
%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
%let RNProbVars3=%tvtdl(&MissMProbVars,&NProbVars3,%STR(=),%STR( ));
%let RNProbVars4=%tvtdl(&MissUProbVars,&NProbVars4,%STR(=),%STR( ));
Data &outdata(keep=&MProbVars);
_djm_point=1;
set &MData(rename=(&RNProbVars1)) point=_djm_point;
set &UData(rename=(&RNProbVars2)) point=_djm_point;
set &MissMData(rename=(&RNProbVars3)) point=_djm_point;
set &MissUData(rename=(&RNProbVars4)) point=_djm_point;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&MProbVars,&I,%STR( ));
&outvar=log((1-_djm_MVar&I-_djm_MissM_Var&I)/(1-_djm_UVar&I-_djm_MissU_Var&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=log((_djm_MVar&I)/(_djm_UVar&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&MProbVars,&I,%STR( ));
&outvar=log((_djm_MissM_Var&I)/(_djm_MissU_Var&I))/log(2);
%LET I=%EVAL(&I+1);
%END;
output;
stop;
run;
%END;
%ELSE %IF &Weighttype=4 %THEN
%DO;
%let NProbVars2=%repeaterandnum(_djm_UVar,&varnum,%STR( ));
%PUT &NProbVars2;
%let RNProbVars2=%tvtdl(&UProbVars,&NProbVars2,%STR(=),%STR( ));
%PUT &RNProbVars2;
Data &outdata(keep=&UProbVars);
_djm_point=1;
set &UData(rename=(&RNProbVars2)) point=_djm_point;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=0;
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=log(1/_djm_UVar&I);
%LET I=%EVAL(&I+1);
%END;
output;
%let I=1;
%DO %WHILE (&I<=&varnum);
%let outvar=%scan(&UProbVars,&I,%STR( ));
&outvar=0;
%LET I=%EVAL(&I+1);
%END;
output;
stop;
run;
%END;
%exit:
%mend genweight;
%macro hashmapper(IDA=_DJM_NONE,IDB=_DJM_NONE,
DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
outdataA=work.HashMappedA,outdataB=work.HashMappedB,
chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,
VarRearrange=Y,exp=12,Hashprefix=_DJM_NONE);
%local i j var numchars libA libB dataA dataB numvarsA numvarsB autoid numobs varlistA varlistB sortvarlistA sortvarlistB vartypeA vartypeB templen lenarray arraylength;
%let libA=%UPCASE(%libnameparse(&DataSetA));
%let libB=%UPCASE(%libnameparse(&DataSetB));
%let dataA=%UPCASE(%dsetparse(&DatasetA));
%let dataB=%UPCASE(%dsetparse(&DataSetB));
%let numchars=%length(&chars);
%let VarRearrange=%UPCASE(%SUBSTR(&VarRearrange,1,1));
%let varlistA=%varlistfromdset(&DataSetA);
%let varlistB=%varlistfromdset(&DataSetB);
%IF &IDA^=_DJM_NONE AND &IDB^=_DJM_NONE %THEN
%DO;
%IF %varsindset(&DatasetA,&IDA) %THEN
%LET varlistA=%removewordfromlist(&IDA,&varlistA);
%IF %varsindset(&DataSetB,&IDB) %THEN
%LET varlistB=%removewordfromlist(&IDB,&varlistB);
%IF %varsindset(&DatasetA,&IDA) OR %varsindset(&DataSetB,&IDB) %THEN
%LET autoid=N;
%ELSE %LET autoid=Y;
%END;
%ELSE %DO;
%PUT ERROR: You must have an ID variable on both data sets;
%PUT ERROR: Then you need to supply it via IDA and IDB;
%PUT ERROR: Aborting hashmapper...;
%GOTO exit;
%END;
%IF &Varrearrange=Y %THEN
%DO;
proc sql noprint;
select name                         
into :sortvarlistA separated by ' '              
from dictionary.columns                      
where libname="&libA" and memname="&DataA"
order by name;
select name                         
into :sortvarlistB separated by ' '              
from dictionary.columns                      
where libname="&libB" and memname="&DataB"
order by name;
quit;
%let VarlistA=&sortvarlistA;
%let VarlistB=&sortvarlistB;
%LET varlistA=%removewordfromlist(%UPCASE(&IDA),&varlistA);
%LET varlistB=%removewordfromlist(%UPCASE(&IDB),&varlistB);
%END;
%LET numvarsA=%countwords(&VarlistA,%STR( ));
%LET numvarsB=%countwords(&VarlistB,%STR( ));
data work._djm_hashmaptemp_1_0;
set &datasetA(keep=&IDA);
run;
data work._djm_hashmaptemp_2_0;
set &datasetB(keep=&IDB);
run;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
%LET var=%SCAN(&VarlistA,&I,%STR( ));
Data work._djm_tvview_&i /view=work._djm_tvview_&i;
set &datasetA(keep=&Var) &DatasetB(keep=&Var);
run;
%HashDistinct(DataSet=work._djm_tvview_&i,
Vars=&Var,
DorV=D,
Outdata=work._djm_hmtdata_&i);
%deletedsets(work._djm_tvview_&i);
%LET I=%EVAL(&I+1);
%END;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
%let numobs=%numofobs(work._djm_hmtdata_&i);
%let templen=1;
%DO %WHILE (%EVAL(&numchars**&templen)<&numobs);
%IF %EVAL(&numchars**&templen)<&numobs %THEN
%LET templen=%EVAL(&templen+1);
%END;
%let lenarray=&lenarray &templen;
%LET I=%EVAL(&I+1);
%END;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
%LET var=%SCAN(&VarlistA,&I,%STR( ));
%let arraylength=%SCAN(&lenarray,&I,%STR( ));
Data work._djm_hmtdata_&i;
length _djm_code $ %scan(&lenarray,&I,%STR( ));
array _djm_chars {&numchars} $ 1 _temporary_  (
%let j=1;
%do %while (&j<=&numchars);
"%substr(&chars,&j,1)"%str( )
%let j=%eval(&J+1);
%END;
) ;
array _djm_charspos {&arraylength}_temporary_ (%repeater(1,&arraylength,%STR( )));
do until (_djm_end);
set work._djm_hmtdata_&i end=_djm_end;
_djm_code=
%let j=1;
%do %while (&j<=&arraylength);
_djm_chars[_djm_charspos[&j]]
%IF &j^=&arraylength %THEN ||;
%let j=%eval(&J+1);
%END;
;
if missing(&var) then
call missing(_djm_code);
else
do;
%let j=1;
%do %while (&j<=&arraylength);
%IF &J=1 %THEN
%DO;
_djm_charspos[&j]=_djm_charspos[&j]+1;
%END;
%ELSE %IF &J<=&arraylength %THEN
%DO;
IF _djm_charspos[%EVAL(&j-1)]>&numchars then
do;
_djm_charspos[%EVAL(&j-1)]=1;
_djm_charspos[&j]=_djm_charspos[&j]+1;
end;
%END;
%let j=%eval(&J+1);
%END;
end;
output;
end;
stop;
run;
%LET I=%EVAL(&I+1);
%END;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
%LET var=%SCAN(&VarlistA,&I,%STR( ));
Data work._djm_tvview_1_&i /view=work._djm_tvview_1_&i;
set &datasetA(keep=&Var);
run;
Data work._djm_tvview_2_&i /view=work._djm_tvview_2_&i;
set &datasetB(keep=&Var);
run;
%HashJoin(DataSetA=work._djm_tvview_1_&i,DataSetB=work._djm_hmtdata_&i,JoinVars=&Var,DatavarsB=_djm_code,Jointype=IJ,DorV=V,Outdata=work._DJM_TEMP1,exp=&exp,ForceB=Y,ExcludeMissings=N);
%HashJoin(DataSetA=work._djm_tvview_2_&i,DataSetB=work._djm_hmtdata_&i,JoinVars=&Var,DatavarsB=_djm_code,Jointype=IJ,DorV=V,Outdata=work._DJM_TEMP2,exp=&exp,ForceB=Y,ExcludeMissings=N);
Data work._DJM_HASHMAPTEMP_1_&I;
set _DJM_TEMP1(keep=_djm_code rename=(_djm_code=&Var));
run;
Data work._DJM_HASHMAPTEMP_2_&I;
set _DJM_TEMP2(keep=_djm_code rename=(_djm_code=&Var));
run;
%LET I=%EVAL(&I+1);
%END;
Data &outdataA;
set _djm_Hashmaptemp_1_0;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
set _djm_Hashmaptemp_1_&i;
%LET I=%EVAL(&I+1);
%END;
;
run;
Data &outdataB;
set _djm_Hashmaptemp_2_0;
%let I=1;
%DO %WHILE (&I<=&numvarsA);
set _djm_Hashmaptemp_2_&i;
%LET I=%EVAL(&I+1);
%END;
;
run;
%deletedsets(work._djm_Hashmaptemp_1_0 work._djm_Hashmaptemp_2_0 work._djm_temp1 work._djm_temp2 
%let I=1;
%DO %WHILE (&I<=&numvarsA);
%LET var=%SCAN(&VarlistA,&I,%STR( ));
work._djm_Hashmaptemp_1_&i%STR( )work._djm_Hashmaptemp_2_&i%STR( )work._djm_tvview_1_&i%STR( )work._djm_tvview_2_&i%STR( )work._djm_hmtdata_&i%STR( )
%LET I=%EVAL(&I+1);
%END;
);
%IF &Hashprefix^=_DJM_NONE %THEN
%DO;
%local tempvarlistA tempvarlistB wordy;
%let tempvarlistA=%varlistfromdset(&OutdataA);
%let tempvarlistB=%varlistfromdset(&OutdataB);
PROC DATASETS lib=%libnameparse(&OutdataA) nolist;
modify %dsetparse(&OutdataA);
rename
%DO I=1 %TO %countwords(&tempvarlistA,%STR( )) %BY 1;
%LET wordy=%SCAN(&tempvarlistA,&I,%STR( ));
&Wordy=&Hashprefix.&Wordy%STR( )
%END;
;
QUIT;
RUN;
PROC DATASETS lib=%libnameparse(&OutdataB) nolist;
modify %dsetparse(&OutdataB);
rename
%DO I=1 %TO %countwords(&tempvarlistB,%STR( )) %BY 1;
%LET wordy=%SCAN(&tempvarlistB,&I,%STR( ));
&Wordy=&Hashprefix.&Wordy%STR( )
%END;
;
QUIT;
RUN;
%END;
%exit:
%mend hashmapper;
%macro hashwriter(Hashname=,	
DataSet=,
DataVars=,
KeyVars=,
addprefix=_DJM_NONE,
removeprefix=_DJM_NONE,
ExcludeMissings=Y,
exp=16,
MultiData=Y);
%local p_KeyVars pq_KeyVars pqc_KeyVars p_DataVars pq_DataVars nmiss_KeyVars nmiss_DataSet uniqueVars Var1 Var2 Var3 Var4;
%LET MultiData=%UPCASE(%SUBSTR(&MultiData,1,1));
%LET ExcludeMissings=%UPCASE(%SUBSTR(&ExcludeMissings,1,1));
%IF &addprefix=_DJM_NONE AND &removeprefix=_DJM_NONE %THEN
%DO;
%LET p_KeyVars=&KeyVars;
%LET pq_KeyVars=%QUOTElist(&p_KeyVars);
%LET pqc_KeyVars=%QClist(&p_KeyVars);
%LET pqc_DataVars=%QCList(&DataVars);
%let Var1=%UniqueWords(&DataVars &Keyvars);
%let Var3=%termlistpattern(&KeyVars,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
%END;
%ELSE %IF &removeprefix^=_DJM_NONE AND &addprefix=_DJM_NONE %THEN
%DO;
%LET pqc_KeyVars=%QCList(&KeyVars);
%LET pqc_DataVars=%QCList(&DataVars);
%let Var1=%UniqueWords(%PL(&DataVars &Keyvars,&removeprefix));
%let Var2=%tvtdl(&Var1,%RPL(&Var1,&removeprefix),%STR(=),%STR( ));
%let Var3=%termlistpattern(&KeyVars,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
%END;
%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
%DO;
%LET pqc_KeyVars=%QCList(%PL(&Keyvars,&addprefix));
%LET pqc_DataVars=%QCList(%PL(&DataVars,&addprefix));
%let Var1=%UniqueWords(&DataVars &Keyvars);
%let Var2=%tvtdl(&Var1,%PL(&Var1,&addprefix),%STR(=),%STR( ));
%let Var3=%termlistpattern(%PL(&KeyVars,&addprefix),%STR(IS NOT MISSING),%STR( ),%STR( AND ));
%END;
%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
%DO;
%LET pqc_KeyVars=%QCList(%PL(&Keyvars,&addprefix));
%LET pqc_DataVars=%QCList(%PL(&Datavars,&addprefix));
%let Var1=%UniqueWords(%PL(&DataVars &Keyvars,&removeprefix));
%let Var2=%tvtdl(&Var1,%PL(%RPL(&Var1,&removeprefix),&addprefix),%STR(=),%STR( ));
%let Var3=%termlistpattern(%PL(&KeyVars,&addprefix),%STR(IS NOT MISSING),%STR( ),%STR( AND ));
%END;
%IF &ExcludeMissings=N %THEN
%DO;
%IF &removeprefix=_DJM_NONE and &addprefix=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1)", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2))", hashexp:&exp, multidata:"&MultiData");
%END;
%ELSE
%DO;
%IF &removeprefix=_DJM_NONE and &addprefix=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
%ELSE %IF &removeprefix^=_DJM_NONE and &addprefix^=_DJM_NONE %THEN
dcl hash &hashname (dataset:"&DataSet(keep=&Var1 rename=(&Var2) where=(&Var3))", hashexp:&exp, multidata:"&MultiData");
%END;
;
&hashname..definekey(&pqc_KeyVars);
%IF &DataVars^=%STR() %THEN %DO;
&hashname..definedata(&pqc_DataVars);
%END;
&hashname..definedone();
%mend HashWriter;
%macro pointy(PointData=_DJM_NONE,PointVarA=_DJM_NONE,PointVarB=_DJM_NONE,
DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
VarsA=_DJM_NONE,VarsB=_DJM_NONE,
prefixa=,prefixb=,
outdata=work.pointed,DorV=V);
%local PointVars PLVarsA PLVarsB RNVarsA RNVarsB;
%IF &pointdata=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply a valid pointdata parameter for the Pointy Macro to function properly;
%PUT ERROR: You have not done so.;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&pointdata)=0 %THEN
%DO;
%PUT ERROR: &pointdata does not appear to exist;
%PUT ERROR: Aborting Pointy Macro...;
%END;
%IF &DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply a valid DataSetA and DataSetB option for the Pointy Macro to function properly;
%PUT ERROR: You have not done so.;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%ELSE
%DO;
%IF %dsetvalidate(&DataSetA)=0 %THEN
%DO;
%PUT ERROR: &DataSetA does not exist;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSetB)=0 %THEN
%DO;
%PUT ERROR: &DataSetB does not exist;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%END;
%IF &pointVarA=_DJM_NONE OR &pointVarB=_DJM_NONE %THEN
%DO;
%PUT NOTE: PointVarA and PointVarB were not supplied.  Attempting to use first two variables of &PointData;
%let PointVars=%varlistfromdset(&pointdata);
%IF %countwords(&Vars,%STR( ))>=2 %THEN
%DO;
%LET PointVarA=%SCAN(&Vars,1,%str( ));
%LET PointVarB=%SCAN(&Vars,2,%str( ));
%END;
%ELSE
%DO;
%PUT ERROR: There are not two variables on &pointdata;
%PUT ERROR: So we cannot automatically assign two variables as PointVarA and PointVarB;
%PUT ERROR: Aborting Pointy Macro...;
%END;
%END;
%ELSE
%DO;
%IF %varsindset(&pointdata,&PointVarA)=0 %THEN
%DO;
%PUT ERROR: &PointVarA was not found in &pointdata;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%IF %varsindset(&pointdata,&PointVarB)=0 %THEN
%DO;
%PUT ERROR: &PointVarB was not found in &pointdata;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%END;
%IF &VarsA=_DJM_NONE %THEN
%DO;
%LET VarsA=%varlistfromdset(&DatasetA);
%END;
%ELSE %IF %varsindset(&DataSetA,&VarsA)=0 %THEN
%DO;
%PUT ERROR: All variables were not found in &DataSetA;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%IF &VarsB=_DJM_NONE %THEN
%DO;
%LET VarsB=%varlistfromdset(&DatasetB);
%END;
%ELSE %IF %varsindset(&DataSetB,&VarsB)=0 %THEN
%DO;
%PUT ERROR: All variables were not found in &DataSetB;
%PUT ERROR: Aborting Pointy Macro...;
%GOTO exit;
%END;
%LET PLVarsA=%PL(&VarsA,&prefixa);
%LET PLVarsB=%PL(&VarsB,&prefixb);
%LET RNVarsA=%tvtdl(&VarsA,&PLVarsA,%STR(=),%STR( ));
%LET RNVarsB=%tvtdl(&VarsB,&PLVarsB,%STR(=),%STR( ));
Data &outdata %IF &DorV=V %THEN /view=&outdata;;
do until(_djm_eof);
set &pointdata(keep=&PointVarA &PointVarB rename=(&PointVarA=_djm_pointerA &PointVarB=_djm_pointerB)) end=_djm_eof;
set &DataSetA(keep=&VarsA rename=(&RNVarsA)) point=_djm_pointerA;
set &DataSetB(keep=&VarsB rename=(&RNVarsB)) point=_djm_pointerB;
output;
end;
stop;
run;
%exit:
%mend pointy;
%macro royalsampler(DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
VarsA=_DJM_NONE,VarsB=_DJM_NONE,
prefixa=,prefixb=,
outdata=work.RoyalSampled,DorV=V,
NumRecords=1000000);
%local DsetAcount DsetBcount PointVars PLVarsA PLVarsB RNVarsA RNVarsB;
%IF &DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply a valid DataSetA and DataSetB option for the Royal Sampler Macro to function properly;
%PUT ERROR: You have not done so.;
%PUT ERROR: Aborting Royal Sampler Macro...;
%GOTO exit;
%END;
%ELSE %DO;
%IF %dsetvalidate(&DataSetA)=0 %THEN
%DO;
%PUT ERROR: &DataSetA does not exist;
%PUT ERROR: Aborting Royal Sampler Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSetB)=0 %THEN
%DO;
%PUT ERROR: &DataSetB does not exist;
%PUT ERROR: Aborting Royal Sampler Macro...;
%GOTO exit;
%END;
%END;
%IF  &VarsA=_DJM_NONE %THEN %DO;
%LET VarsA=%varlistfromdset(&DatasetA);
%END;
%IF  &VarsB=_DJM_NONE %THEN %DO;
%LET VarsB=%varlistfromdset(&DatasetB);
%END;
%IF %varsindset(&DataSetA,&VarsA)=0 %THEN
%DO;
%PUT ERROR: All variables were not found in &DataSetA;
%PUT ERROR: Aborting Royal Sampler Macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSetB,&VarsB)=0 %THEN
%DO;
%PUT ERROR: All variables were not found in &DataSetB;
%PUT ERROR: Aborting Royal Sampler Macro...;
%GOTO exit;
%END;
%LET PLVarsA=%PL(&VarsA,&prefixa); 
%LET PLVarsB=%PL(&VarsB,&prefixb); 
%LET RNVarsA=%tvtdl(&VarsA,&PLVarsA,%STR(=),%STR( ));
%LET RNVarsB=%tvtdl(&VarsB,&PLVarsB,%STR(=),%STR( ));
%LET DsetACount=%numofobs(&DataSetA);
%LET DsetBCount=%numofobs(&DataSetB);
Data &outdata(drop=_djm_counter) %IF &DorV=V %THEN /view=&outdata;;
do _djm_counter = 1 to &NumRecords;
_djm_pointerA=FLOOR(RAND("UNIFORM")*&DsetACount)+1;
_djm_pointerB=FLOOR(RAND("UNIFORM")*&DsetBCount)+1;
set &DataSetA(keep=&VarsA rename=(&RNVarsA)) point=_djm_pointerA;
set &DataSetB(keep=&VarsB rename=(&RNVarsB)) point=_djm_pointerB;
output;
end;
stop;
run;
%exit:
%mend royalsampler;
%macro simpleencrypt(DataSet=,Outdata=work.encrypted,EncryptVars=_DJM_NONE,Hashfunction=MD5,sd=12);
%local i numvars charred allvars var;
%IF %DSETVALIDATE(&Dataset)=0 %THEN
%DO;
%PUT ERROR: Data set &dataset does not exist;
%PUT ERROR: Aborting Simple Encrypt...;
%GOTO exit;
%END;
%IF &EncryptVars=_DJM_NONE %THEN %DO;
%let EncryptVars=%varlistfromdset(&DataSet);
%END;
%ELSE %IF %varsindset(&DataSet,&EncryptVars)=0 %THEN %DO;
%PUT ERROR: Variables listed in EncryptVars are not found in the data set &Dataset;
%PUT ERROR: Aborting Simple Encrypt...;
%END;
%LET Numvars=%countwords(&EncryptVars,%STR( ));
%LET charred=%numstochars(&DataSet,&EncryptVars,&sd);
Data &outdata(drop=&EncryptVars rename=(
%LET I=1;
%DO %WHILE (&I<=&numvars);
%LET var=%scan(&EncryptVars,&I,%STR( ));
_djm_&I%STR(=)&var%STR( )
%LET I=%EVAL(&I+1);
%END;
));
length 
%LET I=1;
%DO %WHILE (&I<=&numvars);
_djm_&i $ 32
%LET I=%EVAL(&I+1);
%END;
;
set &Dataset;
%LET I=1;
%DO %WHILE (&I<=&numvars);
%LET var=%scan(&charred,&I,%STR( ));
%IF &hashfunction=MD5 %THEN _djm_&i=put(MD5(&var),hex32.);;
%LET I=%EVAL(&I+1);
%END;
run;
%exit:
%mend simpleencrypt;
%macro simpleevidence(DataSet=_DJM_NONE,
IDA=_DJM_NONE,
IDB=_DJM_NONE,
WeightData=_DJM_NONE,
Outdata=work.evidenced,
DorV=V,
Prefixa=,
Prefixb=,
Comptypes=_DJM_NONE,
Compvals=_DJM_NONE,
SumVar=TotalWeight,
KeepNonSumVars=N);
%local I J a_Var b_var comparison comp1 comp2;
%local linkvars rnalinkvars rnblinkvars iclinkvars;
%local icrnalinkvars icrnalinkvars;
%local weightagree weightdisagree weightmissing;
%local weighta weightd weightm;
%local numcheck1 numcheck2 numcheck3;
%local outty_var tempcheck;
%local Case;
%let Comptypes=%UPCASE(&Comptypes);
%let DorV=%UPCASE(%SUBSTR(&DorV,1,1));
%let KeepNonSumVars=%UPCASE(%SUBSTR(&KeepNonSumVars,1,1));
%IF %dsetvalidate(&DataSet)=0 %THEN
%DO;
%PUT ERROR: DataSet does not exist or was not supplied;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&WeightData)=0 %THEN
%DO;
%PUT ERROR: Weightdata does not exist or was not supplied;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSet,&IDA)=0 %THEN
%DO;
%PUT ERROR: ID Variable &IDA was not found on &DataSet;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSet,&IDB)=0 %THEN
%DO;
%PUT ERROR: ID Variable &IDB was not found on &DataSet;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%let linkvars=%varlistfromdset(&WeightData);
%let rnalinkvars=%PL(&linkvars,&prefixa);
%let rnblinkvars=%PL(&linkvars,&prefixb);
%let icrnalinkvars=%tvtdl(&rnalinkvars,%PL(&rnalinkvars,_ic_),%STR(=),%STR( ));
%let icrnblinkvars=%tvtdl(&rnblinkvars,%PL(&rnblinkvars,_ic_),%STR(=),%STR( ));
%IF %varsindset(&DataSet, &rnalinkvars)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables listed;
%PUT ERROR: &rnalinkvars;
%PUT ERROR: Does not exist on &DataSet;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSet, &rnblinkvars)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables listed;
%PUT ERROR: &rnblinkvars;
%PUT ERROR: Does not exist on &DataSet;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%LET weightdisagree=%obtomacro(&WeightData,&linkvars,1);
%LET weightagree=%obtomacro(&WeightData,&linkvars,2);
%LET weightmissing=%obtomacro(&WeightData,&linkvars,3);
%IF &comptypes=_DJM_NONE %THEN
%DO;
%LET comptypes = %repeater(E,%countwords(&Linkvars,%STR( )),%STR( ));
%END;
%IF &compvals=_DJM_NONE %THEN
%DO;
%LET compvals = %repeater(0,%countwords(&Linkvars,%STR( )),%STR( ));
%END;
%LET numcheck1=%countwords(&LinkVars,%STR( ));
%LET numcheck2=%countwords(&Comptypes,%STR( ));
%LET numcheck3=%countwords(&Compvals,%STR( ));
%IF &numcheck1^=&numcheck2 OR &numcheck2^=&numcheck3 %THEN
%DO;
%PUT ERROR: CONFLICTING NUMBER OF PARAMETERS ENTERED.;
%PUT ERROR: There were &numcheck1 LinkVars members;
%PUT ERROR: There were &numcheck2 Comptypes members;
%PUT ERROR: There were &numcheck3 Compvals members;
%PUT ERROR: Above parameters must all have the same number of members;
%PUT ERROR: Aborting simple evidence macro...;
%GOTO exit;
%END;
%let I=1;
%do %while(&I<=&numcheck2);
%let tempcheck = %SCAN(&Comptypes,&I,%STR( ));
%IF &tempcheck ^= E AND &tempcheck ^= WI AND &tempcheck ^= JA AND &tempcheck ^= HF 
AND &tempcheck ^= GF AND &tempcheck ^= LF AND &tempcheck ^= CL %THEN
%DO;
%PUT &tempcheck;
%PUT ERROR: Compvals can only include the following:;
%PUT ERROR: E,WI,JA,HF,GF,LF,CL;
%PUT ERROR: Aborting apderive...;
%GOTO exit;
%END;
%LET I = %EVAL(&I + 1);
%END;
%let I=1;
%let tempcheck=0;
%do %while(&I<=&numcheck2);
%IF %QUOTE(%scan(&weightdisagree,&I,%STR( )))^=%QUOTE(%scan(&weightmissing,&I,%STR( ))) %THEN %DO;
%LET tempcheck=1;
%LET I=&numcheck2;
%END;
%LET I = %EVAL(&I + 1);
%END;
%IF &tempcheck=1 %THEN
%LET Case=3;
%ELSE %LET Case=2;
Data &outdata(keep=&IDA &IDB &SumVar %IF &KeepNonSumVars=Y %THEN &Linkvars;) %IF &DorV=V %THEN /view=&outdata;;
set &DataSet(keep=&IDA &IDB &rnalinkvars &rnblinkvars rename=(&icrnalinkvars &icrnblinkvars));
%IF &Case=2 %THEN
%DO;
%let I=1;
%do %while(&I<=&numcheck1);
%let a_Var = %scan(%PL(&rnalinkvars,_ic_),&I,%str( ));
%let b_Var = %scan(%PL(&rnblinkvars,_ic_),&I,%str( ));
%let comparison = %scan(&Comptypes,&I,%str( ));
%let comp1 = %scan(&Compvals,&I,%str( ));
%let outty_Var = %scan(&LinkVars,&I,%STR( ));
%let weighta = %scan(&weightagree,&I,%STR( ));
%let weightd = %scan(&weightdisagree,&I,%STR( ));
%let weightm = %scan(&weightmissing,&I,%STR( ));
%IF &comparison = E %THEN
%DO;
IF &a_Var^=&b_var THEN
&outty_Var=&weightd;
ELSE IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=&weightm;
ELSE &outty_Var=&weighta;
%END;
%ELSE %IF &comparison=WI %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=&weightm;
ELSE IF winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
&outty_Var=&weightd;
ELSE &outty_Var=&weighta;
%END;
%ELSE %IF &comparison=JA %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=&weightm;
ELSE IF jaro(&a_Var,&b_Var)<&comp1 THEN
&outty_Var=&weightd;
ELSE &outty_Var=&weighta;
%END;
%ELSE %IF &comparison=HF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF Highfuzz(&a_Var,&b_Var,&comp1) = 0 then
&outty_Var = &weightd;
ELSE &outty_Var = &weighta;
%END;
%ELSE %IF &comparison=GF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF Genfuzz(&a_Var,&b_Var,&comp1) = 0 then
&outty_Var = &weightd;
ELSE &outty_Var = &weighta;
%END;
%ELSE %IF &comparison=LF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF Lowfuzz(&a_Var,&b_Var,&comp1) = 0 then
&outty_Var = &weightd;
ELSE &outty_Var = &weighta;
%END;
%ELSE %IF &comparison=CL %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF complev(&a_var,&b_var)>=&comp1 THEN
&outty_var=&weightd;
ELSE &outty_var=&weighta;
%END;
%let I = %eval(&I+1);
%end;
&SumVar = 
%LET I = 1;
%do %while(&I<=&numcheck1);
%scan(&LinkVars,&I,%STR( ))
%IF &I ^= &numcheck1 %THEN
%STR(+);
%LET I = %EVAL(&I+1);
%END;
;
%END;
%ELSE %IF &Case=3 %THEN
%DO;
%let I=1;
%do %while(&I<=&numcheck1);
%let a_Var = %scan(%PL(&rnalinkvars,_ic_),&I,%str( ));
%let b_Var = %scan(%PL(&rnblinkvars,_ic_),&I,%str( ));
%let comparison = %scan(&Comptypes,&I,%str( ));
%let comp1 = %scan(&Compvals,&I,%str( ));
%let outty_Var = %scan(&LinkVars,&I,%STR( ));
%let weighta = %scan(&weightagree,&I,%STR( ));
%let weightd = %scan(&weightdisagree,&I,%STR( ));
%let weightm = %scan(&weightmissing,&I,%STR( ));
%IF &comparison=E %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF &a_Var ^= &b_Var THEN
&outty_Var = &weightd;
ELSE &outty_Var=&weighta;
%END;
%ELSE %IF &comparison=WI %THEN
%DO;
IF missing(&a_Var) or missing(&b_Var) then
&outty_var=&weightm;
ELSE IF &a_Var=&b_Var then
&outty_Var=&weighta;
ELSE IF Winkler(&a_Var,&b_Var,0.1)<&comp1 THEN
&outty_Var=&weightd;
ELSE &outty_var=&weighta;
%END;
%ELSE %IF &comparison=JA %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF &a_Var=&b_Var THEN
&outty_Var=&weighta;
ELSE IF Jaro(&a_Var,&b_Var)<&comp1 THEN
&outty_Var=&weightd;
ELSE &outty_var=&weighta;
%END;
%ELSE %IF &comparison=HF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF &a_Var=&b_Var THEN
&outty_var=&weighta;
ELSE IF highfuzz(&a_var,&b_Var,&comp1)=0 then
&outty_var=&weightd;
ELSE &outty_var=&weighta;
%END;
%ELSE %IF &comparison=GF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF &a_Var=&b_Var THEN
&outty_var=&weighta;
ELSE IF genfuzz(&a_var,&b_Var,&comp1)=0 then
&outty_var=&weightd;
ELSE &outty_var=&weighta;
%END;
%ELSE %IF &comparison=LF %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_var=&weightm;
ELSE IF &a_Var=&b_Var THEN
&outty_var=&weighta;
ELSE IF lowfuzz(&a_var,&b_Var,&comp1)=0 then
&outty_var=&weightd;
ELSE &outty_var=&weighta;
%END;
%ELSE %IF &comparison=CL %THEN
%DO;
IF missing(&a_Var) OR missing(&b_Var) THEN
&outty_Var=&weightm;
ELSE IF &a_Var=&b_Var THEN
&outty_Var=&weighta;
ELSE IF Complev(&a_Var,&b_Var)>=&Comp1 THEN
&outty_Var=&weightd;
ELSE &outty_Var=&weighta;
%END;
%let I = %eval(&I+1);
%END;
&SumVar = 
%LET I = 1;
%do %while(&I<=&numcheck1);
%scan(&LinkVars,&I,%STR( ))
%IF &I ^= &numcheck1 %THEN
%STR(+);
%LET I = %EVAL(&I+1);
%END;
;
%END;
run;
%exit:
%mend simpleevidence;
%Macro topn(DataSet=,Outdata=,IDVar=,WeightVar=,N=,WeightorID=ID,Performance=1);
%local i;
%LET WeightorID=%UPCASE(%SUBSTR(&WeightorID,1,1));
PROC SORT data=&DataSet Out=&Outdata %IF &Performance=1 OR &Performance=3 %THEN NOEQUALS; %IF &Performance=3 OR &Performance=4 %THEN Tagsort;;
BY &IDVar descending &WeightVar;
run;
Data &outdata(drop=_djm_topncounter %IF &WeightorID=W %THEN _djm_weight;);
set &outdata end=_djm_eof;
by &IDVar descending &WeightVar;
length _djm_topncounter 8 %IF &WeightorID=W %THEN _djm_weight 8;;
retain _djm_topncounter %IF &WeightorID=W %THEN _djm_weight;;
%IF &WeightorID=I %THEN %DO;
if first.&IDVAR then _djm_topncounter=1;
else _djm_topncounter=_djm_topncounter+1;
IF _djm_topncounter<=&N then output;
%END;
%ELSE %IF &WeightorID=W %THEN %DO;
if first.&IDVAR then do;
call missing(_djm_weight);
_djm_topncounter=1;
end;
IF missing(_djm_weight)^=1 then do;
IF &weightvar^=_djm_weight then _djm_topncounter=_djm_topncounter+1;
end;
IF _djm_topncounter<=&N then output;
_djm_weight=&WeightVar;
%END;
if _djm_eof then stop;
run;
%mend topn;
%macro applyid(DataSet,IDVar);
data &DataSet;
set &DataSet;
&IDVar=_n_;
run;
%mend applyid;
%macro commalist(list);
%local I result word;
%let I=1;
%do %while(%SCAN(&list,&i,%STR( ))^=%STR( ));
%let word=%SCAN(&list,&i,%STR( ));
%IF &I=1 %THEN %LET result=&word;
%ELSE %let result=&result,&word;
%LET I=%EVAL(&I+1);
%END;
&result
%mend commalist;
%macro countwords(varlist,delimiter);
%local I result;
%let I=1;
%do %while( %scan(&varlist,&I,%str(&delimiter)) ne %str( ));
%let I = %eval(&I+1);
%end;
%LET result=%EVAL(&I-1);
&result
%mend countwords;
%macro createsimpledset(dsetname,variables,delimiter1,values,delimiter2);
%local N I Specific_Var Specific_Value;
%let N=%countwords(&variables,&delimiter1);
%let I=1;
data &dsetname;
%do %while (&I<=&N);
%let Specific_Var=%scan(&variables,&I,&delimiter1);
%let Specific_Value=%scan(&values,&I,&delimiter2);
&Specific_Var=&Specific_Value;
%let I=%EVAL(&I+1);
%end;
run;
%mend createsimpledset;
%macro deletedsets(dsetlist);
%local I Var1 vthing dthing J K L jlist klist llist;
%let I=1;
%let J=0;
%let K=0;
%let L=0;
%do %while(%scan(&dsetlist,&I,%str( )) ne %str( ));
%let Var1=%scan(&dsetlist,&I,%str( ));
%IF %SYSFUNC(exist(&Var1,DATA)) %THEN
%LET dthing=1;
%ELSE %LET dthing=0;
%IF %SYSFUNC(exist(&Var1,VIEW)) %THEN
%LET vthing=1;
%ELSE %LET vthing=0;
%IF &dthing=1 %THEN %DO;
%LET J=%EVAL(&J+1);
%let jlist=&jlist &Var1;
%END;
%ELSE %IF &vthing=1 %THEN %DO;
%LET K=%EVAL(&K+1);
%let klist=&klist &Var1;
%END;
%ELSE %DO;
%LET L=%EVAL(&L+1);
%LET llist=&llist &Var1;
%END;
%let I = %eval(&I+1);
%end;
%IF &J>=1 %THEN %DO;
%LET Jlist=%findreplace(&Jlist,%STR( ),%STR(,));
PROC SQL;
DROP TABLE &Jlist;
QUIT;
%END;
%IF &K>=1 %THEN %DO;
%let Klist=%findreplace(&Klist,%STR( ),%STR(,));
PROC SQL;
DROP VIEW &Klist;
QUIT;
%END;
%IF &L>=1 %THEN %DO;
%PUT NOTE: THE FOLLOWING ITEMS WERE NOT FOUND, AND HENCE NOT DELETED;
%PUT NOTE: %UPCASE(&LList);
%END;
%mend deletedsets;
%macro deleteprograms(programs);
%local I Var1 result RegexID found rn_lib rn_data;
%let I=1;
%let RegexID=%sysfunc(prxparse(/((\w+)\.)?(\w+)/));
%do %while(%scan(&programs,&I,%str( )) ne %str( ));
%let Var1=%scan(&programs,&I,%str( ));
%let found=%sysfunc(prxmatch(&RegexID, &Var1));
%IF &found>=1 %THEN
%DO;
%let rn_lib=%UPCASE(%sysfunc(prxposn(&RegexID,2,&Var1)));
%let rn_data=%UPCASE(%sysfunc(prxposn(&RegexID,3,&Var1)));
%IF %length(&rn_lib)=0 %THEN
%LET rn_lib=WORK;
%END;
%IF %progvalidate(&Var1)=1 %THEN %DO;
PROC DATASETS lib=&rn_lib. memtype=PROGRAM nolist;
DELETE &rn_data;
QUIT;
RUN;
%END;
%ELSE %DO;
%PUT NOTE: &rn_lib..&rn_data was not deleted as such a program did not exist.;
%END;
%let I = %eval(&I+1);
%end;
%syscall PRXFREE(RegexID);
%mend deleteprograms;
%macro dsetparse(indata);
%local rn_data;
%LET rn_data=%scan(&indata,-1,.);
&rn_data
%mend dsetparse;
%macro dsetvalidate(indata);
%local dthing vthing thingexist;
%IF %SYSFUNC(exist(&indata)) %THEN
%LET dthing=1;
%ELSE %LET dthing=0;
%IF %SYSFUNC(exist(&indata,VIEW)) %THEN
%LET vthing=1;
%ELSE %LET vthing=0;
%LET thingexist=0;
%IF &dthing=1 %THEN
%LET thingexist=1;
%IF &vthing=1 %THEN
%LET thingexist=1;
&thingexist
%mend dsetvalidate;
%macro dsetvrename(Dataset,oldvarlist,newvarlist);
%local k old new;
%let k=1;
%let old = %scan(&oldvarlist,&k);
%let new = %scan(&newvarlist,&k);
PROC DATASETS library=%libnameparse(&Dataset) nolist;
modify %dsetparse(&Dataset);
rename%STR( )
%do %while((&old NE %STR()) OR (&new NE %STR()));
&old=&new%STR( )
%let k=%eval(&k+1);
%let old=%scan(&oldvarlist, &k);
%let new = %scan(&newvarlist, &k);
%end;
;
quit;
run;
%mend dsetvrename;
%macro EstimateSize(Dataset,Variables);
%local I reclength observations size;
%let reclength=%findreplace(%Varlengths(&Dataset,&Variables),%STR( ),%STR(+));
%let observations=%numofobs(&DataSet);
%let size=%EVAL((&reclength)*&observations);
&size
%mend EstimateSize;
%macro filesindir(dir=,ext=Y,extension=sas7bdat,datasetflag=N,dataset=work.files,pathvar=Path,filevar=File,extvar=Extension,delimiter=%STR( ));
%local rc did filrf memcnt i name ext result v1 v2 v3;
%let ext=%UPCASE(%SUBSTR(&ext,1,1));
%let datasetflag=%UPCASE(%SUBSTR(&Datasetflag,1,1));
%let filrf=mydir;
%let rc=%sysfunc(filename(filrf,&dir));
%let did=%sysfunc(dopen(&filrf));
%let memcnt=%sysfunc(dnum(&did));
%IF &Datasetflag=N %THEN
%DO;
%do i = 1 %to &memcnt;
%IF &ext=Y %THEN
%DO;
%let name=%qscan(%qsysfunc(dread(&did,&i)),-1,.);
%if %qupcase(%qsysfunc(dread(&did,&i))) ne %qupcase(&name) %then
%do;
%if (%superq(extension) ne %STR() and %qupcase(&name) = %qupcase(&extension)) or                                                                       
(%superq(extension) = %STR() and %superq(name) ne %STR()) %then
%do;
%IF &result=%STR() %THEN
%let result=%qsysfunc(dread(&did,&i));
%ELSE %LET result=&result.&delimiter.%qsysfunc(dread(&did,&i));
%end;
%END;
%end;
%ELSE
%DO;
%IF &i=1 %THEN
%let result=%qsysfunc(dread(&did,&i));
%ELSE %LET result=&result.&delimiter.%qsysfunc(dread(&did,&i));
%END;
%end;
&result
%END;
%ELSE
%DO;
Data &Dataset;
%let v1=;
%let v2=0;
%let v3=0;
%DO i=1 %to &memcnt;
%let v1=%length(%qscan(%qsysfunc(dread(&did,&i)),1,.));
%IF %superq(v1)>&v2 %THEN
%LET v2=%superq(v1);
%let v1=%length(%SYSFUNC(STRIP(%qscan(%qsysfunc(dread(&did,&i)),-1,.))));
%IF %superq(v1)>&v3 %THEN
%LET v3=%superq(v1);
%END;
length &pathvar $ %length(&dir) &fileVar $ &v2 &extVar $ &v3;
%do i = 1 %to &memcnt;
%IF &ext=Y %THEN
%DO;
%let name=%qscan(%qsysfunc(dread(&did,&i)),-1,.);
%if %qupcase(%qsysfunc(dread(&did,&i))) ne %qupcase(&name) %then
%do;
%if (%superq(extension) ne %STR() and %qupcase(&name) = %qupcase(&extension)) or                                                                       
(%superq(extension) = %STR() and %superq(name) ne %STR ()) %then
%do;
&pathVar="&dir";
&fileVar="%qscan(%qsysfunc(dread(&did,&i)),1,.)";
&extVar="%superq(name)";
output;
%end;
%end;
%END;
%ELSE %do i = 1 %to &memcnt;
&pathVar="&dir";
&fileVar="%qscan(%qsysfunc(dread(&did,&i)),1,.)";
&extVar="%qscan(%qsysfunc(dread(&did,&i)),-1,.)";
%IF %qscan(%qsysfunc(dread(&did,&i)),1,.)=%qscan(%qsysfunc(dread(&did,&i)),-1,.) %THEN
if &fileVar=&extVar then
call missing (&extvar);;
output;
%END;
%end;
stop;
run;
%END;
%let rc=%sysfunc(dclose(&did));
%mend filesindir;
%macro findreplace(string,find,replace);
%local result;
%let result=%sysfunc(prxchange(s/&find./&replace./,-1,&string.));
&result
%mend findreplace;
%macro findwordinlist(word,list);
%local result;
%let result=%sysfunc(prxmatch(/\b&word\b/,&list));
%if &result^=0 %THEN %let result=1;
&result
%mend findwordinlist;
%macro getoption(_djm_option);
%local value;
%let value = %sysfunc(getoption(&_djm_option));
&value
%mend getoption;
%macro interleave(list1,list2);
%local I result;
%let I=1;
%do %while(%scan(&list1,&I,%str( )) ne %STR( ));
%let result=&result %scan(&list1,&I,%str( )) %scan(&list2,&I,%str( ));
%let I = %eval(&I+1);
%end;
&result
%mend interleave;
%macro keepwordpattern(indata,regex);
%local RegexID found;
%let RegexID=%sysfunc(prxparse(&regex));
%let found=%sysfunc(prxmatch(&RegexID, &indata));
%local I result count word ;
%let count=%countwords(&indata,%STR( ));
%let I=1;
%do %while(&I<=&count);
%let word=%scan(&indata,&I,%STR( ));
%let found=%sysfunc(prxmatch(&RegexID,&word));
%IF &found^=0 %THEN %Let result=&result &word;
%let I = %eval(&I+1);
%end;
%syscall PRXFREE(RegexID);
&result
%mend keepwordpattern;
%macro lengthfixer(DataSet=,Align=N);
%local count varlist I var typelist type finallengths length;
%let varlist=%varlistfromdset(&DataSet);
%let count=%countwords(&varlist,%STR( ));
%let typelist=%vartype(&DataSet,&varlist);
Data &DataSet;
Set &DataSet;
%let I=1;
%do %while(&I<=&count);
%let var=%scan(&varlist,&I,%STR( ));
%let type=%scan(&typelist,&I,%STR( ));
%IF &type=C %THEN
%DO;
&var=strip(&var);
%end;
%let I=%EVAL(&I+1);
%end;
run;
Data _lengthfixer_temp(keep=%PL(&varlist,l_)) /view=_lengthfixer_temp;
set &dataset;
%let I=1;
%do %while(&I<=&count);
%let var=%scan(&varlist,&I,%STR( ));
%let type=%scan(&typelist,&I,%STR( ));
%IF &type=C %THEN
%DO;
l_&var=length(&var);
%end;
%IF &type=N %THEN
%DO;
l_&var=8;
%end;
%let I=%EVAL(&I+1);
%end;
run;
proc means data=_lengthfixer_temp MAX noprint;
var %PL(&varlist,l_);
output out=work._lengthfixer_lengths(drop=_type_ _freq_) MAX(%PL(&varlist,l_))=%PL(&varlist,l_);
run;
%let finallengths=%obtomacro(work._lengthfixer_lengths,%PL(&varlist,l_),1);
options varlenchk=NOWARN;
Data &Dataset;
length 
%let I=1;
%do %while(&I<=&count);
%let var=%scan(&varlist,&I,%STR( ));
%let type=%scan(&typelist,&I,%STR( ));
%let length=%scan(&finallengths,&I,%STR( ));
%IF &Align^=N %THEN
%DO;
%IF &type=C %THEN
%DO;
%let length=%EVAL(%SYSEVALF(%SYSFUNC(CEIL(&length/8)))*8);
&var $ &length
%end;
%IF &type=N %THEN
&var 8;
%END;
%ELSE
%DO;
%IF &type=C %THEN
%DO;
&var $ &length
%end;
%IF &type=N %THEN
&var 8;
%END;
%let I=%EVAL(&I+1);
%end;
;
set &dataset;
run;
options varlenchk=WARN;
%deletedsets(work._lengthfixer_temp work._lengthfixer_lengths);
%mend lengthfixer;
%macro libnameparse(indata);
%local rn_lib;
%LET rn_lib=%scan(&indata,1,.);
%IF &rn_lib=%scan(&indata,-1,.) %THEN %LET rn_lib=WORK;
&rn_lib
%mend libnameparse;
%macro libvalidate(indata);
%local length return RegexID firstchar;
%let length=%length(&indata);
%let RegexID=%sysfunc(prxparse(/[A-Za-z_]/));
%IF &length>=1 %THEN
%LET firstchar=%SUBSTR(&indata,1,1);
%IF &length>8 %THEN
%DO;
%LET return=0;
%END;
%ELSE %IF %SYSFUNC(prxmatch(&RegexID,&firstchar))=0 %THEN
%DO;
%LET return=0;
%END;
%ELSE %IF %SYSFUNC(LIBREF(&indata))=0 %THEN
%LET return=1;
%ELSE %LET return=0;
%SYSCALL PRXFREE(RegexID);
&return
%mend libvalidate;
%macro memsize;
%local memorysize;
%let memorysize=%SYSFUNC(getoption(MemSize));
&memorysize
%mend memsize;
%macro numofobs(data);
%local dsid anobs whstmt counted rc;
%IF %dsetvalidate(&data)=0 %THEN %DO;
%PUT ERROR: &Data does not exist...;
%PUT ERROR: Aborting numofobs macro...;
%let counted = ERROR;
%GOTO exit;
%END;
%let DSID = %sysfunc(open(&DATA., IS));
%let anobs = %sysfunc(attrn(&DSID, ANOBS));
%let whstmt = %sysfunc(attrn(&DSID, WHSTMT));
%if &anobs = 1 AND &whstmt = 0 %then
%let counted = %sysfunc(attrn(&DSID, NLOBS));
%else
%do;
%if %sysfunc(getoption(msglevel)) = I %then
%let counted = 0;
%do %while (%sysfunc(fetch(&DSID)) = 0);
%let counted = %eval(&counted + 1);
%end;
%end;
%let rc = %sysfunc(close(&DSID));
%exit:
&counted
%mend numofobs;
%macro Numordset(indata);
%local RegexID found result;
%let RegexID=%sysfunc(prxparse(/[0-9]/));
%let found=%sysfunc(prxmatch(&RegexID,%SUBSTR(&indata,1,1)));
%IF &found=1 %THEN
%LET result=N;
%ELSE %LET result=D;
%syscall PRXFREE(RegexID);
&result
%mend NumorDset;
%macro NumstoChars(Indata,vars,sd);
%local rc dsid result tempy I varnum;
%let dsid=%sysfunc(open(&indata));
%let I=1;
%do %while(%scan(&vars,&I,%str( )) ne %str( ));
%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
%let tempy=%SYSFUNC(vartype(&dsid,&varnum));
%IF &tempy=N %THEN
%LET result=&result put(%scan(&vars,&I,%str( )),best&sd..);
%ELSE %LET result=&result %scan(&vars,&I,%str( ));
%let I = %eval(&I+1);
%end;
%let rc=%SYSFUNC(close(&dsid));
&result
%mend NumstoChars;
%macro obtomacro(_DJM_rare_dset,_DJM_rare_varlist,_DJM_rare_startnum);
%local _DJM_rare_id _DJM_rare_i _DJM_rare_rc _DJM_rare_close _DJM_rare_result _DJM_rare_tempy %varlistfromdset(&_DJM_rare_dset);
%let _DJM_rare_id=%sysfunc(open(&_DJM_rare_dset));
%syscall set(_DJM_rare_id);
%let _DJM_rare_rc=%sysfunc(fetchobs(&_DJM_rare_id,&_DJM_rare_startnum));
%let _DJM_rare_close=%sysfunc(close(&_DJM_rare_id));
%let _DJM_rare_I=1;
%do %while(%scan(&_DJM_rare_varlist,&_DJM_rare_I,%str( )) ne %str( ));
%let _DJM_rare_tempy=%scan(&_DJM_rare_varlist,&_DJM_rare_I,%str( ));
%let _DJM_rare_result=&_DJM_rare_result &&&_DJM_rare_tempy;
%let _DJM_rare_I = %eval(&_DJM_rare_I+1);
%end;
&_DJM_rare_result
%mend obtomacro;
%macro PL(List,Prefix);
%local I Var Final;
%let Final = %str();
%let I = 1;
%do %while(%scan(&List,&I,%str( )) ne %str( ));
%let Var = %scan(&List,&I,%str( ));
%let Final = &Final &Prefix.&Var;
%let I = %eval(&I+1);
%end;
&Final
%mend;
%macro progvalidate(indata);
%local pthing;
%IF %SYSFUNC(exist(&indata,PROGRAM)) %THEN %LET pthing=1;
%ELSE %LET pthing=0;
&pthing
%mend progvalidate;
%macro QClist(list);
%local I result word;
%let I=1;
%do %while(%SCAN(&list,&i,%STR( ))^=%STR( ));
%let word=%SCAN(&list,&i,%STR( ));
%IF &I=1 %THEN %LET result="&word";
%ELSE %let result=&result,"&word";
%LET I=%EVAL(&I+1);
%END;
&result
%mend QClist;
%macro quotelist(list);
%local I result word;
%let I=1;
%do %while(%SCAN(&list,&i,%STR( ))^=%STR( ));
%let word=%SCAN(&list,&i,%STR( ));
%if &I=1 %THEN %LET result="&word";
%else %let result=&result "&word";
%LET I=%EVAL(&I+1);
%END;
&result
%mend quotelist;
%macro realmem;
%local realmemory;
%let realmemory=%SYSFUNC(getoption(xmrlmem));
&realmemory
%mend realmem;
%macro removelibraries(input);
%local I count lib;
%let count=%countwords(&input,%STR( ));
%let I=1;
%do %while(&I<=&count);
%let lib=%scan(&input,&I,%STR( ));
%IF %libvalidate(&lib)=1 %THEN %DO;
libname &lib CLEAR;
%END;
%ELSE %PUT NOTE: LIBRARY %UPCASE(&LIB) IS NOT ASSIGNED AND WAS THEREFORE NOT CLEARED;
%let I = %eval(&I+1);
%end;
%mend removelibraries;
%macro removewordfromlist(word,list);
%local i num result secondword;
%let num=%countwords(&list,%STR( ));
%let i=1;
%let result=;
%do %while(&i<=&num);
%let secondword=%scan(&list,&i,%STR( ));
%if &word^=&secondword %then %let result=&result &secondword;
%let i=%eval(&i+1);
%end;
&result
%mend removewordfromlist;
%macro repeater(string,N,delimiter);
%local I Final;
%LET Final=&string;
%let I = 2;
%do %while(&I <= &N);
%let Final = &final.&Delimiter.&string;
%let I = %eval(&I+1);
%end;
&Final
%mend repeater;
%macro repeaterandnum(string,N,delimiter);
%local I Final;
%LET Final=&string.1;
%let I = 2;
%do %while(&I <= &N);
%let Final = &final.&Delimiter.&string.&i;
%let I = %eval(&I+1);
%end;
&Final
%mend repeaterandnum;
%macro report_date;
%sysfunc(date(),EURDFWKX.);
%mend report_date;
%macro report_datetime;
%sysfunc(date(),EURDFWKX.), %sysfunc(time(), time.);
%mend report_datetime;
%macro report_time;
%sysfunc(time(), time.);
%mend report_time;
%macro RPL(List,Prefix);
%local I Var Final Length calc Prelength;
%let Final=%str();
%let I=1;
%do %while( %scan(&List,&I,%str( )) ne %str( ));
%let Var = %scan(&List,&I,%str( ));
%let Length =%LENGTH(&Var);
%let Prelength=%LENGTH(&Prefix);
%let Var=%SUBSTR(&Var,%EVAL(&PreLength+1),%EVAL(&Length-&Prelength));
%let Final = &Final &Var;
%let I = %eval(&I+1);
%end;
&final
%MEND RPL;
%macro RSL(List,Suffix);
%local I Var Final Length calc Prelength;
%let Final=%str();
%let I=1;
%do %while( %scan(&List,&I,%str( )) ne %str( ));
%let Var = %scan(&List,&I,%str( ));
%let Length =%LENGTH(&Var);
%let Prelength=%LENGTH(&Suffix);
%let Var=%SUBSTR(&Var,1,%EVAL(&Length-&Prelength));
%let Final = &Final &Var;
%let I = %eval(&I+1);
%end;
&final
%MEND RSL;
%macro SL(List,Suffix);
%local I Var Final;
%let Final=%str();
%let I=1;
%do %while(%scan(&List,&I,%str( )) ne %str( ));
%let Var = %scan(&List,&I,%str( ));
%let Final=&Final &Var.&Suffix;
%let I = %eval(&I+1);
%end;
&final
%mend;
%macro termlistpattern(string1,string2,delimiter1,delimiter2);
%local string1_num string2_repeated result;
%let string1_num=%countwords(&string1,%STR( ));
%let string2_repeated=%repeater(_DJM_MS_,&string1_num,%str( ));
%let result=%tvtdl(&string1,&string2_repeated,&delimiter1,&delimiter2);
%let result=%findreplace(&result,_DJM_MS_,&string2);
&result
%mend termlistpattern;
%macro tvtdl(varlist1,varlist2,delim1,delim2);
%local I Var1 Var2 count1 count2 Final;
%LET count1=%countwords(&varlist1,%STR( ));
%LET count2=%countwords(&varlist2,%STR( ));
%IF &count1^=&count2 %THEN
%DO;
%PUT ERROR: DIFFERING NUMBER OF VARIABLES/WORDS IN THE LISTS FED TO THE TVTDL FUNCTION.;
%PUT ERROR: HIGH LIKELIHOOD OF EVERYTHING EXPLODING HORRIBLY.;
%PUT ERROR: THE WORD LISTS INVOLVED WERE AS FOLLOWS:;
%PUT ERROR: &varlist1;
%PUT ERROR: &varlist2;
%END;
%let Final=%str();
%let I=1;
%do %while(%scan(&varlist1,&I,%str( )) ne %str( ));
%let Var1=%scan(&varlist1,&I,%str( ));
%let Var2=%scan(&varlist2,&I,%str( ));
%IF &I=&count1 %THEN %LET Final=&Final.&Var1.&delim1.&Var2;
%ELSE %LET Final=&Final.&Var1.&delim1.&Var2.&delim2;
%let I = %eval(&I+1);
%end;
&Final
%mend tvtdl;
%macro Uniquewords(list);
%local I result count word found1 found2;
%let count=%countwords(&list,%str( ));
%let I=1;
%do %while(&I<=&count);
%let word=%SCAN(&list,&i,%STR( ));
%let found1=%findwordinlist(&word,&list);
%let found2=%findwordinlist(&word,&result);
%IF &I=1 %THEN %LET result=&word;
%ELSE %IF &found1=1 and &found2=0 %THEN %let result=&result &word;
%LET I=%EVAL(&I+1);
%END;
&result
%mend Uniquewords;
%macro varkeeplist(Varlist,Key);
%local i num var result;
%let num=%countwords(&Varlist,%STR( ));
%let i = 1;
%do %while (&I<=&num);
%if %scan(&Key,&I,%STR( ))=1 %THEN %DO;
%LET Var=%scan(&Varlist,&I,%STR( ));
%LET result=&result &Var;
%END;
%let I=%EVAL(&I+1);
%end;
&result
%mend varkeeplist;
%macro VarKeepListDset(DataSet,Obnumber);
%local i num var Varlist ob result;
%let Varlist=%varlistfromDset(&Dataset);
%let num=%countwords(&Varlist,%STR( ));
%let Key=%obtomacro(&DataSet,&Varlist,&Obnumber);
%LET I=1;
%do %while (&I<=&num);
%if %scan(&Key,&I,%STR( ))=1 %THEN %DO;
%LET Var=%scan(&Varlist,&I,%STR( ));
%LET result=&result &Var;
%END;
%let I=%EVAL(&I+1);
%end;
&result
%mend VarKeepListDset;
%macro VarLengths(indata,vars);
%local rc dsid result I varnum;
%let dsid=%sysfunc(open(&indata));
%let I=1;
%do %while(%scan(&vars,&I,%str( )) ne %str( ));
%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
%let result=&result %SYSFUNC(varlen(&dsid,&varnum));
%let I = %eval(&I+1);
%end;
%let rc=%SYSFUNC(close(&dsid));
&result
%mend VarLengths;
%macro varlistfromdset(indata);
%local rc dsid cnt result I;
%let dsid=%sysfunc(open(&indata));
%let cnt=%sysfunc(attrn(&dsid,nvars));
%do i = 1 %to &cnt;
%let result=&result %sysfunc(varname(&dsid,&i));
%end;
%let rc=%sysfunc(close(&dsid));
&result
%mend varlistfromdset;
%macro VarPos(indata,vars);
%local rc dsid result I varnum;
%let dsid=%sysfunc(open(&indata));
%let I=1;
%do %while(%scan(&vars,&I,%str( )) ne %str( ));
%let result=&result %SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
%let I = %eval(&I+1);
%end;
%let rc=%SYSFUNC(close(&dsid));
&result
%mend VarPos;
%macro varsindset(indata,vars);
%local rc dsid result I;
%let result=1;
%let dsid=%sysfunc(open(&indata));
%let I=1;
%do %while( %scan(&vars,&I,%str( )) ne %str( ));
%IF %SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))))=0 %THEN
%LET result=0;
%let I = %eval(&I+1);
%end;
%let rc=%SYSFUNC(close(&dsid));
&result
%mend varsindset;
%macro vartype(indata,vars);
%local rc dsid result I varnum;
%let dsid=%sysfunc(open(&indata));
%let I=1;
%do %while(%scan(&vars,&I,%str( )) ne %str( ));
%let varnum=%SYSFUNC(varnum(&dsid,%scan(&vars,&I,%str( ))));
%let result=&result %SYSFUNC(vartype(&dsid,&varnum));
%let I = %eval(&I+1);
%end;
%let rc=%SYSFUNC(close(&dsid));
&result
%mend vartype;
%macro VorDset(indata);
%local dthing vthing thing;
%IF %SYSFUNC(exist(&indata)) %THEN
%LET dthing=1;
%ELSE %LET dthing=0;
%IF %SYSFUNC(exist(&indata,VIEW)) %THEN
%LET vthing=1;
%ELSE %LET vthing=0;
%LET thing=0;
%IF &dthing=1 %THEN
%LET thing=D;
%IF &vthing=1 %THEN
%LET thing=V;
&thing
%mend VorDSet;
%macro wordinlist(Word,List);
%local result wordcount i;
%let wordcount=%countwords(&List,%STR( ));
%let result=0;
%DO i= 1 %TO &wordcount %BY 1;
%IF %SCAN(&list,&I,%STR( ))=&word %THEN %LET result=1;
%END;
&result
%mend wordinlist;
%macro hashcount(   DataSet=_DJM_NONE,
Vars=_DJM_NONE,
CountVar=_DJM_count,
DorV=D,
Outdata=work.counted,exp=12);
%local QCVars;
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%IF &Vars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the SortVar parameter;
%PUT ERROR: This lets the Hash Sort program know which variables to sort on;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: All Sortvars are not present in &DataSet;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%let QCVars=%QClist(&Vars);
Data &Outdata(keep=&Vars &CountVar) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
dcl hash djmhash (hashexp: &exp,suminc:'_djm_counter');
djmhash.definekey (&QCVars);
djmhash.definedone();
_djm_counter=1;
do while(not eof);
set &dataset(keep=&Vars) end=eof;
djmhash.ref();
end;
declare hiter hi('djmhash');
_iorc_ = hi.first();
do while (_iorc_ = 0);
djmhash.sum(sum: &CountVar);
output;
_iorc_ = hi.next();
end;
stop;
run;
%exit:
%mend hashcount;
%macro hashdistinct	(		DataSet=_DJM_NONE,
Vars=_DJM_NONE,
DorV=D,
Outdata=work.distinct,exp=12
);
%local QCVars;
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF &Vars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the Vars parameter;
%PUT ERROR: This lets the Hash Distinct program know which variables you are interested in;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: The Variables: &Vars are not present in &DataSet;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%let QCVars=%QClist(&Vars);
Data &Outdata(keep=&Vars) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
dcl hash djmhash (dataset:"&DataSet",hashexp: &exp);
djmhash.definekey (&QCVars);
djmhash.definedone();
declare hiter hi('djmhash');
_iorc_ = hi.first();
do while (_iorc_ = 0);
output;
_iorc_ = hi.next();
end;
stop;
run;
%exit:
%mend hashdistinct;
%macro hashisin	(		DataSet=_DJM_NONE,
Vars=_DJM_NONE,
InDataSet=_DJM_NONE,
InVars=_DJM_NONE,
DorV=D,
Outdata=work.IsIn,exp=12
);
%local CLVars QCInVars;
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);
%IF &InVars=_DJM_NONE %THEN %LET InVars=&Vars;
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF &Vars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the Vars parameter;
%PUT ERROR: This lets the Hash Distinct program know which variables you are interested in;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: The Variables: &Vars are not present in &DataSet;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF %Varsindset(&InDataSet,&InVars)=0 %THEN
%DO;
%PUT ERROR: The Variables: &Vars are not present in &DataSet;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%let CLVars=%Commalist(&Vars);
%let QCInVars=%QClist(&InVars);
Data &Outdata(keep=&Vars) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &InDataSet(keep=&InVars);
dcl hash djmhash (dataset:"&InDataSet",hashexp: &exp);
djmhash.definekey (&QCInVars);
djmhash.definedone();
do until (_djm_eof);
set &DataSet end=_djm_eof;
_iorc_=djmhash.find(key: &CLVars);
if _iorc_=0 then do;
output;
djmhash.remove(key:&CLVars);
end;
end;
stop;
run;
%exit:
%mend hashisin;
%macro hashisnotin	(		DataSet=_DJM_NONE,
Vars=_DJM_NONE,
NotInDataSet=_DJM_NONE,
NotInVars=_DJM_NONE,
DorV=D,
Outdata=work.IsNotIn,exp=12
);
%local QCVars CLNotInVars;
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Vars=%UPCASE(&Vars);
%IF &NotInVars=_DJM_NONE %THEN %LET NotInVars=&Vars;
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Distinct...;
%GOTO exit;
%END;
%IF &Vars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the Vars parameter;
%PUT ERROR: This lets the Hash Distinct program know which variables you are interested in;
%PUT ERROR: Aborting Hash NotIn...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: The Variables: &Vars are not present in &DataSet;
%PUT ERROR: Aborting Hash NotIn...;
%GOTO exit;
%END;
%let QCVars=%QClist(&Vars);
%let CLNotInVars=%Commalist(&NotInVars);
Data &Outdata(keep=&Vars) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
dcl hash djmhash (dataset:"&DataSet",hashexp: &exp);
djmhash.definekey (&QCVars);
djmhash.definedone();
do until (_djm_eof);
set &NotinDataSet end=_djm_eof;
_iorc_=djmhash.remove(key: &CLNotInVars);
end;
declare hiter hi('djmhash');
_iorc_ = hi.first();
do while (_iorc_ = 0);
output;
_iorc_ = hi.next();
end;
stop;
run;
%exit:
%mend hashisnotin;
%macro hashjoin(DataSetA=,DataSetB=,
JoinVars=_DJM_NONE,JoinVarsA=_DJM_NONE,JoinVarsB=_DJM_NONE,
Datavars=_DJM_NONE,DataVarsA=_DJM_NONE,DataVarsB=_DJM_NONE,
PrefixA=,PrefixB=,Jointype=IJ,DorV=D,Outdata=work.joined,exp=16,
ForceA=N,ForceAKey=N,ForceB=N,ForceBKey=N,ExcludeMissings=N);
%local Force DataSetAHold DataSetBHold DSADV DSBDV DSADataSize DSBDataSize DSAKeySize DSBKeySize 
DSASize DSBSize DSAKeyOptSize DSBKeyOptSize RealMem HashOrder AHash BHash Hash AKey BKey Key Smaller;
%local BothVarsA PLBothVarsA PLDataVarsA PLJoinVarsA RNBothVarsA RNDataVarsA RNJoinVarsA QCDataVarsA 
QCJoinVarsA KKJoinVarsA BothVarsB PLBothVarsB PLDataVarsB PLJoinVarsB RNBothVarsB RNDataVarsB RNJoinVarsB 
QCDataVarsB QCJoinVarsB KKJoinVarsB WJoinVarsA WJoinVarsB;
options NOQUOTELENMAX;
%let jointype=%UPCASE(&jointype);
%let ForceA=%SUBSTR(%UPCASE(&FORCEA),1,1);
%let ForceAKey=%SUBSTR(%UPCASE(&FORCEAKey),1,1);
%let ForceB=%SUBSTR(%UPCASE(&FORCEB),1,1);
%let ForceBKey=%SUBSTR(%UPCASE(&FORCEBKey),1,1);
%let ExcludeMissings=%SUBSTR(%UPCASE(&Excludemissings),1,1);
%IF &ForceA=Y OR &ForceB=Y OR &ForceAKey=Y OR &ForceBKey=Y %THEN
%let FORCE=Y;
%if &DataVars=_DJM_NONE AND &DataVarsA=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
%do;
%let DataVarsA=%varlistfromdset(&DataSetA);
%let DataVarsB=%varlistfromdset(&DataSetB);
%end;
%ELSE
%DO;
%if &DataVars=_DJM_NONE AND &DataVarsA=_DJM_NONE %then
%let DataVarsA=%varlistfromdset(&DataSetA);
%if &DataVars=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
%let DataVarsB=%varlistfromdset(&DataSetB);
%if &DataVars^=_DJM_NONE AND &DataVarsA=_DJM_NONE %then
%let DataVarsA=&DataVars;
%if &DataVars^=_DJM_NONE AND &DataVarsB=_DJM_NONE %then
%let DataVarsB=&DataVars;
%END;
%IF %DSETVALIDATE(&DataSetA)=0 %THEN
%DO;
%PUT ERROR: Data Set A does not exist;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF %DSETVALIDATE(&DataSetB)=0 %THEN
%DO;
%PUT ERROR: Data Set B does not exist;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF (&JoinVars=_DJM_NONE AND &JoinVarsA=_DJM_NONE AND &JoinVarsB=_DJM_NONE) %THEN
%DO;
%PUT ERROR: Either JoinVars, JoinVarsA or JoinVarsB must be supplied to the hash macros;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF (&JoinVars=_DJM_NONE AND (&JoinVarsA=_DJM_NONE OR &JoinVarsB=_DJM_NONE)) %THEN
%DO;
%PUT ERROR: If JoinVars is not supplied, then JoinVarsA or JoinVarsB must both be supplied to the hash macros;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF &joinvars^=_DJM_NONE %THEN
%DO;
%IF %Varsindset(&DataSetA,&joinvars)=0 %THEN
%DO;
%PUT ERROR: All joinvars are not present in Data Set A;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSetB,&joinvars)=0 %THEN
%DO;
%PUT ERROR: All joinVars are not present in Data Set B;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%END;
%ELSE
%DO;
%IF %Varsindset(&DataSetA,&joinvarsA)=0 %THEN
%DO;
%PUT ERROR: All joinVarsA are not present in Data Set A;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSetB,&joinvarsB)=0 %THEN
%DO;
%PUT ERROR: All joinVarsB are not present in Data Set B;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%END;
%IF &JoinVars^=_DJM_NONE AND &JoinVarsA=_DJM_NONE AND &JoinVarsB=_DJM_NONE %THEN
%DO;
%let JoinVarsA=&JoinVars;
%let JoinVarsB=&JoinVars;
%END;
%IF %vartype(&DataSetA,&JoinVarsA)^=%vartype(&DataSetB,&JoinVarsB) %THEN
%DO;
%PUT ERROR: The joinvars are not of the same type on both of the data sets;
%PUT ERROR: These algorithms require join variables to be of the same data type;
%GOTO exit;
%END;
%IF %Varsindset(&DataSetA,&DataVarsA)=0 %THEN
%DO;
%PUT ERROR: All DataVarsA are not present in Data Set A;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSetB,&DataVarsB)=0 %THEN
%DO;
%PUT ERROR: All DataVarsB are not present in Data Set B;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%IF &Jointype = LO %THEN %DO;
%LET prefixb = _djm_;
%END;
%ELSE %IF &Jointype = RO %THEN %DO;
%LET prefixa = _djm_;
%END;
%let HashOrder=A;
%let AHash=N;
%let BHash=N;
%let Hash=N;
%let AKey=N;
%let BKey=N;
%let Key=N;
%let DSADV=%VORDSET(&DataSetA);
%let DSBDV=%VORDSET(&DataSetB);
%IF &DSADV=D AND &FORCE^=Y %THEN
%DO;
%LET DSADataSize=%EstimateSize(&DataSetA,&DataVarsA);
%LET DSAKeySize=%EstimateSize(&DataSetA,&JoinVarsA);
%lET DSASize=%EVAL(&DSAKeySize+&DSADataSize);
%LET DSAKeyOptSize=%EVAL(&DSAKeySize+(%numofobs(&DataSetA)*8));
%IF &DSASize < %RealMem %THEN
%DO;
%LET AHash=Y;
%LET AKey=Y;
%END;
%ELSE %IF &DSAKeyOptSize < %RealMem %THEN
%DO;
%LET AHash=NP;
%LET AKey=Y;
%END;
%ELSE
%DO;
%LET BHash=NP;
%LET BKey=NP;
%END;
%END;
%IF &DSBDV=D AND &FORCE^=Y %THEN
%DO;
%LET DSBDataSize=%EstimateSize(&DataSetB,&DataVarsB);
%LET DSBKeySize=%EstimateSize(&DataSetB,&JoinVarsB);
%LET DSBSize=%EVAL(&DSBKeySize+&DSBDataSize);
%LET DSBKeyOptSize=%EVAL(&DSBKeySize+(%numofobs(&DataSetB)*8));
%IF &DSBSize < %RealMem %THEN
%DO;
%LET BHash=Y;
%LET BKey=Y;
%END;
%ELSE %IF &DSBKeyOptSize < %RealMem %THEN
%DO;
%LET BHash=NP;
%LET BKey=Y;
%END;
%ELSE
%DO;
%LET BHash=NP;
%LET BKey=NP;
%END;
%END;
%IF &AHash=Y AND &BHash=Y AND &FORCE^=Y %THEN
%DO;
%IF &DSBSize<&DSASize %THEN
%LET HashOrder=B;
%END;
%ELSE %IF &AKey=Y AND &BKey=Y AND &FORCE^=Y %THEN
%DO;
%IF &DSBKeyOptSize<&DSAKeyOptSize %THEN
%LET HashOrder=B;
%END;
%ELSE %IF (&AHash=NP OR &AHash=N) AND &BHash=Y AND &FORCE^=Y %THEN
%DO;
%LET HashOrder=B;
%END;
%ELSE %IF (&AKey=NP OR &AKey=N) AND &BKey=Y AND &FORCE^=Y %THEN
%DO;
%LET HashOrder=B;
%END;
%IF &AHash=Y OR &BHash=Y %THEN
%LET Key=N;
%ELSE %IF &AKey=Y OR &BKey=Y %THEN
%LET Key=Y;
%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y AND &DSADV=V %THEN
%DO;
%LET DSASize=%EstimateSize(&DataSetA,&JoinVarsA &DataVarsA);
%IF &DSASize<%RealMem %THEN
%LET AHash=Y;
%END;
%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y AND &DSBDV=V %THEN
%DO;
%LET DSBSize=%EstimateSize(&DataSetB,&JoinVarsB &DataVarsB);
%IF &DSBSize<%RealMem %THEN
%LET BHash=Y;
%END;
%IF (&AHash=N and &AKey=N and &BHash=N and &BKey=N) AND &FORCE^=Y %THEN
%DO;
%PUT ERROR: Cannot find an acceptable hash strategy given the size and qualities of the tables/variables involved;
%PUT ERROR: Aborting Hash Join...;
%GOTO exit;
%END;
%LET JoinVarsA=%UPCASE(&JoinVarsA);
%LET JoinVarsB=%UPCASE(&JoinVarsB);
%LET DataVarsA=%UPCASE(&DataVarsA);
%LET DataVarsB=%UPCASE(&DataVarsB);
%LET BothVarsA=%UniqueWords(&JoinVarsA &DataVarsA);
%LET PLBothVarsA=%PL(&BothVarsA,&prefixA);
%LET PLDataVarsA=%PL(&DataVarsA,&prefixA);
%LET PLJoinVarsA=%PL(&JoinVarsA,&prefixA);
%LET RNBothVarsA=%tvtdl(&BothVarsA,&PLBothVarsA,%STR(=),%STR( ));
%LET RNDataVarsA=%tvtdl(&DataVarsA,&PLDataVarsA,%STR(=),%STR( ));
%LET RNJoinVarsA=%tvtdl(&JoinVarsA,&PLJoinVarsA,%STR(=),%STR( ));
%LET WJoinVarsA=%termlistpattern(&PLJoinVarsA,%STR(IS NOT MISSING),%STR( ),%STR( AND ));
%LET QCDataVarsA=%QCList(&PLDataVarsA);
%LET QCJoinVarsA=%QCList(&PLJoinVarsA);
%LET KKJoinVarsA=%tvtdl(%repeater(%STR(Key:),%countwords(&PLJoinVarsA,%STR( )),%STR( )),&PLJoinVarsA,%STR( ),%STR(,));
%LET BothVarsB=%UniqueWords(&JoinVarsB &DataVarsB);
%LET PLBothVarsB=%PL(&BothVarsB,&prefixB);
%LET PLDataVarsB=%PL(&DataVarsB,&prefixB);
%LET PLJoinVarsB=%PL(&JoinVarsB,&prefixB);
%LET RNBothVarsB=%tvtdl(&BothVarsB,&PLBothVarsB,%STR(=),%STR( ));
%LET RNDataVarsB=%tvtdl(&DataVarsB,&PLDataVarsB,%STR(=),%STR( ));
%LET RNJoinVarsB=%tvtdl(&JoinVarsB,&PLJoinVarsB,%STR(=),%STR( ));
%LET QCDataVarsB=%QCList(&PLDataVarsB);
%LET QCJoinVarsB=%QCList(&PLJoinVarsB);
%LET KKJoinVarsB=%tvtdl(%repeater(%STR(Key:),%countwords(&PLJoinVarsB,%STR( )),%STR( )),&PLJoinVarsB,%STR( ),%STR(,));
%LET WJoinVarsB=%termlistpattern(&PLJoinVarsB,%STR(IS NOT MISSING),%STR( ),%STR( AND ));;
%IF &jointype=IJ %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_=0 then
do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
do until (_djm_b_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_b_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_=0 then
do while (_iorc_=0);
set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_=0 then
do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_=0 then
do while (_iorc_=0);
set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=LI %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_=0 then
do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
do until (_djm_b_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_b_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_=0 then
do while (_iorc_=0);
set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;
else do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;											
else do while (_iorc_=0);
set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=RI %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;
else do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;											
else do while (_iorc_=0);
set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_=0 then
do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_=0 then
do while (_iorc_=0);
set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=FI %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;
else do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;											
else do while (_iorc_=0);
set &DataSetA(keep=&DataVarsA %IF &prefixA^=%STR() %THEN rename=(&RNDataVarsA);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;
else do while (_iorc_=0);
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;											
else do while (_iorc_=0);
set &DataSetB(keep=&DataVarsB %IF &prefixB^=%STR() %THEN rename=(&RNDataVarsB);) point=_DJM_ID;
output;
_iorc_=djmhash.find_next();
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=LO %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
output;
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
output;
end;											
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=RO %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
output;
end;											
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
output;
end;
end;
stop;
run;
%END;
%END;
%END;
%ELSE %IF &jointype=FO %THEN
%DO;
%IF (&HashOrder=A OR &ForceA=Y OR &ForceAKey=Y) AND (&ForceB^=Y AND &ForceBKey^=Y) %THEN
%DO;
%IF &AHash=Y OR &ForceA=Y AND (&ForceB^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixA=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA) where=(&WJoinVarsA))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixA^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetA(keep=&BothVarsA rename=(&RNBothVarsA))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata (&QCDataVarsA);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &AKey=Y OR &ForceAKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceBKey^=Y) %THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsA);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSetA(keep=&JoinVarsA %IF &prefixA^=%STR() %THEN rename=(&RNJoinVarsA);) end=_djm_a_eof;
djmhash.add();
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsB);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsA));
output;
end;											
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then djmhash.remove(&KKJoinVarsB);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsB));
output;
end;
end;
stop;
run;
%END;
%END;
%ELSE
%DO;
%IF &BHash=Y OR &ForceB=Y AND (&ForceA^=Y AND &ForceAKey^=Y AND &ForceBKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
%IF &prefixB=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB)",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB) where=(&WJoinVarsB))",hashexp: &exp,multidata: "Y");
%ELSE %IF &prefixB^=%STR() AND &ExcludeMissings^=Y %THEN dcl hash djmhash (dataset:"&DataSetB(keep=&BothVarsB rename=(&RNBothVarsB))",hashexp: &exp,multidata: "Y");
;
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata (&QCDataVarsB);
djmhash.definedone();
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%ELSE %IF &BKey=Y OR &ForceBKey=Y AND (&ForceB^=Y AND &ForceA^=Y AND &ForceAKey^=Y)%THEN
%DO;
Data &Outdata(keep=%UniqueWords(&PLDataVarsA &PLDataVarsB)) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB););
if _N_=0 then set &DataSetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA););
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y");
djmhash.definekey (&QCJoinVarsB);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_b_eof);
set &DataSetB(keep=&JoinVarsB %IF &prefixB^=%STR() %THEN rename=(&RNJoinVarsB);) end=_djm_b_eof;
djmhash.add();
end;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.find(&KKJoinVarsA);
if _iorc_^=0 then do;
call missing (%Commalist(&PLDataVarsB));
output;
end;											
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetA(keep=&BothVarsA %IF &prefixA^=%STR() %THEN rename=(&RNBothVarsA); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsA);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsA);
if _iorc_=0 then djmhash.remove(&KKJoinVarsA);		
end;
_djm_a_eof=0;
do until (_djm_a_eof);
set &DatasetB(keep=&BothVarsB %IF &prefixB^=%STR() %THEN rename=(&RNBothVarsB); %IF &ExcludeMissings=Y %THEN where=(&WJoinVarsB);) end=_djm_a_eof;
_iorc_=djmhash.check(&KKJoinVarsB);
if _iorc_=0 then do;
call missing(%Commalist(&PLDataVarsA));
output;
end;
end;
stop;
run;
%END;
%END;
%END;
%exit:
%mend hashjoin;
%macro hashsort(DataSet=_DJM_NONE,
SortVars=_DJM_NONE,
DorV=D,
AorD=A,
Outdata=work.sorted,exp=12,
TagSort=N);
%local DataVars QCDataVars QCVars;
%let TagSort=%SUBSTR(%UPCASE(&Tagsort),1,1);
%let AorD=%SUBSTR(%UPCASE(&AorD),1,1);
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let Sortvars=%UPCASE(&Sortvars);
%let DataVars=%varlistfromdset(&DataSet);
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%IF &Sortvars=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the SortVar parameter;
%PUT ERROR: This lets the Hash Sort program know which variables to sort on;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Sortvars)=0 %THEN
%DO;
%PUT ERROR: All Sortvars are not present in &DataSet;
%PUT ERROR: Aborting Hash Sort...;
%GOTO exit;
%END;
%let DataVars=%varlistfromdset(&DataSet);
%let QCDataVars=%QClist(&DataVars);
%let QCVars=%QClist(&Sortvars);
%IF &TAGSORT=N %THEN %DO;
Data &Outdata (drop= _djm_n _djm_i)%IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
dcl hash djmhash (dataset:"&DataSet",hashexp: &exp,multidata:"Y",ordered:"&AorD");
djmhash.definekey (&QCVars);
djmhash.definedata (&QCDataVars);
djmhash.definedone();
declare hiter hi('djmhash');
_djm_n=djmhash.num_items-1;
hi.first();
do _djm_i=1 to _djm_n;
output;
hi.next();
end;
output;
stop;
run;
%END;
%ELSE %IF &TAGSORT=Y %THEN %DO;
Data &Outdata (drop= _djm_n _djm_i)%IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
length _DJM_ID 8;
dcl hash djmhash (hashexp: &exp,multidata: "Y",ordered:"&AorD");
djmhash.definekey (&QCVars);
djmhash.definedata ('_DJM_ID');
djmhash.definedone();
do _DJM_ID = 1 by 1 until (_djm_a_eof);
set &DataSet(keep=&Sortvars) end=_djm_a_eof;
djmhash.add();
end;
declare hiter hi('djmhash');
_djm_n=djmhash.num_items-1;
hi.first();
do _djm_i=1 to _djm_n;
set &Dataset point=_DJM_id;
output;
hi.next();
end;
set &Dataset point=_DJM_id;
output;
stop;
run;
%END;
%exit:
%mend hashsort;
%macro hashsum(		DataSet=_DJM_NONE,
SumVar=_DJM_NONE,
ClassVar=_DJM_NONE,
OutSumVar=_djm_sum,
DorV=D,
Outdata=work.summed,exp=12
);
%local QCClassVar;
%let DorV=%SUBSTR(%UPCASE(&DorV),1,1);
%let SumVar=%UPCASE(&SumVar);
%let ClassVar=%UPCASE(&ClassVar);
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set &Dataset does not exist;
%PUT ERROR: Aborting Hash Sum...;
%GOTO exit;
%END;
%IF &SumVar=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the SumVars parameter;
%PUT ERROR: This lets the Hash Sum program know which variables to sum;
%PUT ERROR: Aborting Hash Sum...;
%GOTO exit;
%END;
%IF &ClassVar=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply some variables to the ClassVar parameter;
%PUT ERROR: This lets the Hash Sum program know which categories to sum for;
%PUT ERROR: Aborting Hash Sum...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Sumvar)=0 %THEN
%DO;
%PUT ERROR: The SumVar &Sumvar is not present in &DataSet;
%PUT ERROR: Aborting Hash Sum...;
%GOTO exit;
%END;
%IF %countwords(&Sumvar,%STR( ))>1 %THEN %DO;
%PUT ERROR: You must only enter one SumVar;
%PUT ERROR: Aborting Hash Sum...;
%END;
%IF %Varsindset(&DataSet,&ClassVar)=0 %THEN
%DO;
%PUT ERROR: All ClassVar are not present in &DataSet;
%PUT ERROR: Aborting Hash Sum...;
%GOTO exit;
%END;
%let QCClassVar=%QClist(&ClassVar);
Data &Outdata(keep=&ClassVar &outsumvar) %IF &DorV=V %THEN/view=&outdata;;
if _N_=0 then set &DataSet;
dcl hash djmhash (hashexp: &exp,suminc:"&SumVar");
djmhash.definekey (&QCClassVar);
djmhash.definedone();
do while(not eof);
set &dataset(keep=&ClassVar &SumVar) end=eof;
djmhash.ref();
end;
declare hiter hi('djmhash');
_iorc_ = hi.first();
do while (_iorc_ = 0);
djmhash.sum(sum: &outsumvar);
output;
_iorc_ = hi.next();
end;
stop;
run;
%exit:
%mend hashsum;
%macro dsetslicer(Dataset=_DJM_NONE,
N=_DJM_NONE,
Sequential=N,
Partitions=_DJM_NONE,
DataSetRoot=work.Slice,
DorV=D,
Report=N,
ReportDSet=work.Datasets,
deloriginal=N);
%local I branch num num2 rounds first last dsetcount len;
%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
%LET Report=%UPCASE(%SUBSTR(&Report,1,1));
%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));
%IF &DataSet=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must enter a valid data set to slice.;
%PUT ERROR: Aborting DSetSlicer...;
%GOTO exit;
%END;
%IF %DsetValidate(&Dataset)=0 %THEN
%DO;
%PUT ERROR: &Dataset does not exist.;
%PUT Aborting DSetSlicer...;
%END;
%IF &N^=_DJM_NONE %THEN
%DO;
%LET Partitions=_DJM_NONE;
%LET PartitionDset=_DJM_NONE;
%LET PartitionVar=_DJM_NONE;
%LET branch=N;
%END;
%ELSE %IF &Partitions^=_DJM_NONE %THEN
%DO;
%LET N=_DJM_NONE;
%LET PartitionDset=_DJM_NONE;
%LET PartitionVar=_DJM_NONE;
%LET branch=Partitions;
%END;
%IF &Sequential=Y %THEN
%DO;
%IF &DorV=V %THEN
%DO;
%PUT ERROR: Data type cannot be a view when splitting records sequentially;
%PUT ERROR: into many data sets;
%PUT ERROR: Set DorV parameter to D.;
%PUT ERROR: Aborting...;
%GOTO exit;
%END;
%END;
%IF &Branch=N %THEN
%DO;
%IF &Sequential=N %THEN
%DO;
%LET num=%numofobs(&DataSet);
%IF &N>&num %THEN
%DO;
%PUT ERROR: N IS GREATER THAN THE NUMBER OF OBSERVATIONS IN THE DATASET;
%PUT ERROR: ABORTING;
%GOTO exit;
%END;
%LET num2=%SYSFUNC(FLOOR(%SYSEVALF((&num/&N))));
PROC SQL;
%LET first=1;
%LET last=&num2;
%LET dsetcount=&N;
%IF &DorV=D %THEN
%DO;
%DO i=1 %TO &N %BY 1;
CREATE TABLE &DataSetRoot.&i AS
SELECT *
FROM &DataSet.(firstobs=&first obs=&last);
%LET first=%EVAL(&last+1);
%IF &i=%EVAL(&n-1) %THEN
%LET last=&num;
%ELSE %LET last=%EVAL(&num2*(&I+1));
%END;
%END;
%ELSE
%DO;
%DO i=1 %TO &N %BY 1;
CREATE VIEW &DataSetRoot.&i AS
SELECT *
FROM &DataSet.(firstobs=&first obs=&last);
%LET first=%EVAL(&last+1);
%IF &i=%EVAL(&n-1) %THEN
%LET last=&num;
%ELSE %LET last=%EVAL(&num2*(&I+1));
%END;
%END;
QUIT;
%END;
%ELSE %IF &Sequential=Y %THEN
%DO;
Data 
%DO i=1 %TO &N %BY 1;
&DataSetRoot.&i(drop=_djm_counter)%STR( )
%END;
;
_djm_counter=1;
do until (_djm_eof);
set &Dataset end=_djm_eof;
IF _djm_counter=1 then
output &DataSetRoot.1;
%DO i=2 %TO &N %BY 1;
ELSE IF _djm_counter=&i THEN
output &DataSetRoot.&i%STR( );
%END;
_djm_counter=_djm_counter+1;
if _djm_counter=%EVAL(&N+1) then
_djm_counter=1;
end;
stop;
run;
%END;
%END;
%ELSE %IF &Branch=Partitions %THEN
%DO;
%LET Partitions = &Partitions %numofobs(&dataset);
PROC SQL;
%IF &DorV=D %THEN
%DO;
%LET I=1;
%LET num=%countwords(&Partitions,%STR( ));
%LET num2=%numofobs(&DataSet);
%LET first=1;
%LET last=%SCAN(&Partitions,1,%STR( ));
%LET dsetcount=&num;
%DO %WHILE(%SCAN(&Partitions,&I,%STR( ))^=%STR());
CREATE TABLE &DataSetRoot.&i AS
SELECT *
FROM &DataSet.(firstobs=&first obs=&last);
%let first=%EVAL(&last+1);
%IF last^=%SCAN(&Partitions,&num,%STR( )) %THEN
%LET last=%SCAN(&Partitions,%EVAL(&I+1),%STR( ));
%ELSE %LET last=&num2;
%LET I=%EVAL(&I+1);
%END;
%END;
%ELSE
%DO;
%LET I=1;
%LET num=%countwords(&Partitions,%STR( ));
%LET num2=%numofobs(&DataSet);
%LET first=1;
%LET last=%SCAN(&Partitions,1,%STR( ));
%LET dsetcount=&num;
%DO %WHILE(%SCAN(&Partitions,&I,%STR( ))^=%STR());
CREATE VIEW &DataSetRoot.&i AS
SELECT *
FROM &DataSet.(firstobs=&first obs=&last);
%let first=%EVAL(&last+1);
%IF last^=%SCAN(&Partitions,&num,%STR( )) %THEN
%LET last=%SCAN(&Partitions,%EVAL(&I+1),%STR( ));
%ELSE %LET last=&num2;
%LET I=%EVAL(&I+1);
%END;
%END;
QUIT;
%END;
%IF &Report=Y %THEN
%DO;
%let len=%length(&DataSetRoot.&dsetcount);
Data &reportDset(drop=i);
length DataSets $ &len;
do i=1 to &Dsetcount by 1;
DataSets="&DataSetRoot"||STRIP(PUT(i,BEST12.));
output;
end;
stop;
run;
%END;
%IF &deloriginal=Y %THEN
%DO;
%IF &DorV=V %THEN
%DO;
%PUT WARNING: You really shouldnt delete the data set if youre;
%PUT WARNING: splitting it up using views.;
%PUT WARNING: But since Im a nice guy Ill let you do it anyway.;
%PUT WARNING: Because I assume you know what youre doing...;
%END;
%deletedsets(&Dataset);
%END;
%exit:
%mend dsetslicer;
%Macro dsetsmoosh(Outdata=_DJM_NONE,
N=_DJM_AUTO,
DataSetRoot=work.Slice,
deloriginal=N);
%local I;
%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));
%LET DataSetRoot=%UPCASE(&DataSetRoot);
%IF &N=_DJM_AUTO %THEN
%LET Branch=N;
%ELSE %LET Branch=Y;
%IF &Branch=N %THEN
%DO;
%IF &N=_DJM_AUTO %THEN
%DO;
%local names lib dset;
%let lib=%UPCASE(%libnameparse(&Datasetroot));
%let dset=%UPCASE(%dsetparse(&Datasetroot));
PROC SQL noprint;
SELECT memname
INTO :names SEPARATED BY " "
FROM DICTIONARY.TABLES
WHERE (memtype='DATA' OR memtype='VIEW') AND libname="&lib" AND length(strip(memname))>=%length(&dset) AND substr(memname,1,%length(&dset))="&dset";
QUIT;
%IF %dsetvalidate(&OutData)=1 %THEN
%DO;
%deletedsets(&Outdata);
%END;
PROC DATASETS nolist;
%LET I=1;
%DO %WHILE (%scan(&names,&I,%STR( ))^=%STR());
append base=&Outdata data=&lib..%sysfunc(strip(%scan(&names,&I,%STR( )))) force;
run;
%LET I=%EVAL(&I+1);
%END;
QUIT;
%IF &deloriginal=Y %THEN
%DO;
%LET I=1;
%deletedsets(
%DO %WHILE (%scan(&names,&I,%STR( ))^=%STR( ));
&lib..%sysfunc(strip(%scan(&names,&I,%STR( ))))
%LET I=%EVAL(&I+1);
%END;
);
%END;
%END;
%END;
%ELSE
%DO;
%IF %dsetvalidate(&OutData)=1 %THEN
%DO;
%deletedsets(&Outdata);
%END;
PROC DATASETS nolist;
%DO I = 1 %TO &N %BY 1;
append base=&Outdata data=&Datasetroot.&i force;
run;
%END;
QUIT;
%IF &deloriginal=Y %THEN
%DO;
%deletedsets(
%DO I = 1 %TO &N %BY 1;
&Datasetroot.&i%STR( )
%END;
);
%END;
%END;
%exit:
%mend dsetsmoosh;
options nomlogic nomprint;
%macro icarus_addnode(
ControlDataSet = _DJM_NONE,
Alias = .,
RWork = .,
IcarusGerminate = .,
AuthDomain = .,
CMacVar= .,
ConnectRemote = .,
ConnectStatus = .,
ConnectWait = .,
CScript = .,
CSysRPutSync = .,
InheritLib =.,
Log = .,
Output = ., 
NOCScript = .,
Notify = .,
Password = .,
Sascmd = .,
Server = .,
Serverv = .,
SignonWait = .,
Subject = .,
TBufSize = . 
);
%local oplist myoplist myvarlist countvars i;
%local loopvar loopvalue;
%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
%let oplist = &oplist CSysRPutSync InheritLib Log Output NOCScript Notify;
%let oplist = &oplist Password Sascmd Server Serverv SignonWait Subject TBufSize;
%let myvarlist = Alias RWork IcarusGerminate &oplist;
%let myoplist = ControlDataSet Alias RWork IcarusGerminate;
%let countvars = %countwords(&myvarlist,%STR( ));
%LET IcarusGerminate = %UPCASE(%SUBSTR(&IcarusGerminate,1,1));
%LET myoplist = %UPCASE(&myoplist);
%LET myvarlist = %UPCASE(&myvarlist);
%LET oplist = %UPCASE(&oplist);
%IF &ControlDataSet = _DJM_NONE %THEN
%DO;
%PUT ERROR: You must supply a reference for the Control Data Set;
%PUT ERROR: Aborting icarus_addnode macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&ControlDataSet) = 0 %THEN
%DO;
%IF &CMacVar ^= . %THEN %LET CMacVar = &CMacVar.1_status;
%IF &Alias ^= . %THEN %LET Alias = &Alias.1;
%IF RWork ^= . %THEN %let RWork = &RWork.1;
Data &ControlDataSet;
%LET I = 1;
%DO %WHILE (&I<=&countvars);
%LET loopvar = %scan(&myvarlist,&i,%STR( ));
%LET loopvalue = "&&&loopvar";
&loopvar = &loopvalue;
%LET I = %EVAL(&I + 1);
%END;
output;
stop;
run;
%END;
%ELSE
%DO;
%IF %UPCASE(%varlistfromdset(&ControlDataSet))^=&myvarlist %THEN
%DO;
%PUT ERROR: &ControlDataSet does not appear to be a valid;
%PUT ERROR: Icarus distributed computing control data set;
%PUT ERROR: Aborting icarus_addnode macro...;
%GOTO exit;
%END;
%local num;
%let num=%EVAL(%numofobs(&ControlDataSet) + 1);
%IF &CMacVar ^= . %THEN %LET CMacVar = &CMacVar.&num._status;
%IF &Alias ^= . %THEN %LET Alias = &Alias.&num;
%IF RWork ^= . %THEN %let RWork = &RWork.&num;
%local newvarlengths oldvarlengths varlengths;
%let oldvarlengths = %varlengths(&ControlDataSet, &myvarlist);
%let newvarlengths =;
%LET I = 1;
%DO %WHILE (&I<=&countvars);
%LET varlengths=%scan(&myvarlist,&i,%STR( ));
%LET varlengths=&&&varlengths;
%LET varlengths=%length(&varlengths);
%IF &varlengths > %scan(&oldvarlengths,&I,%STR( )) %THEN
%LET newvarlengths =&newvarlengths &varlengths;
%ELSE %LET newvarlengths =&newvarlengths %scan(&oldvarlengths,&I,%STR( ));
%LET I = %EVAL(&I + 1);
%END;
Data &ControlDataSet;
length 
%LET I = 1;
%DO %WHILE (&I<=&countvars);
%scan(&myvarlist,&i,%STR( )) $ %scan(&newvarlengths,&i,%STR( )) 
%LET I = %EVAL(&I + 1);
%END;
;
set &ControlDataSet end=_djm_eof;
output;
if _djm_eof then
do;
%LET I = 1;
%DO %WHILE (&I<=&countvars);
%LET loopvar = %scan(&myvarlist,&i,%STR( ));
%LET loopvalue = "&&&loopvar";
&loopvar = &loopvalue;
%LET I = %EVAL(&I + 1);
%END;
output;
stop;
end;
run;
%END;
%exit:
%mend icarus_addnode;
%macro icarus_connect(ControlDataSet=);
%local numi i;
%let numi=%numofobs(&ControlDataSet);
%local myoplist oplist myoplistval oplistval totallist;
%let myoplist = Alias RWork IcarusGerminate;
%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
%let totallist = &myoplist &oplist;
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
%do i = 1 %to &numi;
%let myoplistval = %obtomacro(&ControlDataSet,&myoplist,&i);
%let oplistval = %obtomacro(&ControlDataSet,&oplist,&i);
%IF %scan(&myoplistval,1,%STR( ))^= . %THEN
%DO;
%let blah=%scan(&myoplistval,1,%STR( ));
%local &blah;
%let &blah = %scan(&oplistval,3,%STR( ));
%END;
signon 
%IF %scan(&oplistval,1,%STR( ))^=. %THEN
%scan(&oplist,1,%STR( ))=%scan(&oplistval,1,%STR( ));
%IF %scan(&oplistval,2,%STR( ))^=. %THEN %DO;
%scan(&oplist,2,%STR( ))=%scan(&oplistval,2,%STR( ))
%END;
%IF %scan(&myoplistval,1,%STR( ))^=. AND %scan(&oplistval,3,%STR( ))^=. %THEN
%DO;
%scan(&oplist,3,%STR( ))=%scan(&myoplistval,1,%STR( ))
%END;
%ELSE %IF %scan(&oplistval,3,%STR( ))^=. %THEN
%scan(&oplist,3,%STR( ))=%scan(&oplistval,3,%STR( ));
%IF %scan(&oplistval,4,%STR( ))^=. %THEN
%scan(&oplist,4,%STR( ))=%scan(&oplistval,4,%STR( ));
%IF %scan(&oplistval,5,%STR( ))^=. %THEN
%scan(&oplist,5,%STR( ))=%scan(&oplistval,5,%STR( ));
%IF %scan(&oplistval,6,%STR( ))^=. %THEN
%scan(&oplist,6,%STR( ))=%scan(&oplistval,6,%STR( ));
%IF %scan(&oplistval,7,%STR( ))^=. %THEN
%scan(&oplist,7,%STR( ))=%scan(&oplistval,7,%STR( ));
%IF %scan(&oplistval,8,%STR( ))^=. %THEN
%scan(&oplist,8,%STR( ))=%scan(&oplistval,8,%STR( ));
%IF %scan(&oplistval,9,%STR( ))^=. %THEN
%scan(&oplist,9,%STR( ))=%scan(&oplistval,9,%STR( ));
%IF %scan(&oplistval,10,%STR( ))^=. %THEN
%scan(&oplist,10,%STR( ))=%scan(&oplistval,10,%STR( ));
%IF %scan(&oplistval,11,%STR( ))^=. %THEN
%scan(&oplist,11,%STR( ))=%scan(&oplistval,11,%STR( ));
%IF %scan(&oplistval,12,%STR( ))^=. %THEN
%scan(&oplist,12,%STR( ))=%scan(&oplistval,12,%STR( ));
%IF %scan(&oplistval,13,%STR( ))^=. %THEN
%scan(&oplist,13,%STR( ))=%scan(&oplistval,13,%STR( ));
%IF %scan(&oplistval,14,%STR( ))^=. %THEN
%scan(&oplist,14,%STR( ))=%scan(&oplistval,14,%STR( ));
%IF %scan(&oplistval,15,%STR( ))^=. %THEN
%scan(&oplist,15,%STR( ))=%scan(&oplistval,15,%STR( ));
%IF %scan(&oplistval,16,%STR( ))^=. %THEN
%scan(&oplist,16,%STR( ))=%scan(&oplistval,16,%STR( ));
%IF %scan(&oplistval,17,%STR( ))^=. %THEN
%scan(&oplist,17,%STR( ))=%scan(&oplistval,17,%STR( ));
%IF %scan(&oplistval,18,%STR( ))^=. %THEN
%scan(&oplist,18,%STR( ))=%scan(&oplistval,18,%STR( ));
%IF %scan(&oplistval,19,%STR( ))^=. %THEN
%scan(&oplist,19,%STR( ))=%scan(&oplistval,19,%STR( ));
;
%IF %scan(&myoplistval,2,%STR( )) ^= . %THEN %DO;
libname %scan(&myoplistval,2,%STR( )) server=%scan(&myoplistval,1,%STR( )) slibref=work;
%END;
%IF %UPCASE(%SUBSTR(%scan(&myoplistval,3,%STR( )),1,1)) = Y %THEN %DO;
%icarus_germinate(NodeAlias=%scan(&myoplistval,1,%STR( )),
Icaruslocation=&_Icarus_installation);
%END;
%end;
%exit:
%mend icarus_connect;
%macro icarus_distcode(ControlDataset=,
Codedir=,
Codename=,
Wait=Y,
timeout=30);
%local myoplist oplist totallist;
%let myoplist = Alias RWork IcarusGerminate;
%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
%let totallist = &myoplist &oplist;
%IF %dsetvalidate(&ControlDataSet)=0 %THEN %DO;
%PUT ERROR: &ControlDataSet does not exist.;
%PUT ERROR: Aborting icarus_distcode macro...;
%GOTO exit;
%END;
%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN %DO;
%PUT ERROR: &ControlDataSet does not meet the requirements of an;
%PUT ERROR: icarus_connect control data set;
%PUT ERROR: Aborting icarus_distcode macro...;
%GOTO exit;
%END;
%local num Nodealias i;
%let Wait = %UPCASE(%SUBSTR(&Wait,1,1));
%LET num = %numofobs(&ControlDataset);
%DO i = 1 %TO &num %BY 1;
%let Nodealias = %obtomacro(&ControlDataset, Alias, &i);
%SYSLPUT _Icarus_temphold1=%BQUOTE(&Codedir) /remote=&NodeAlias;
%SYSLPUT _Icarus_temphold2=%BQUOTE(&Codename) /remote=&NodeAlias;
rsubmit &NodeAlias;
proc upload infile="&_Icarus_temphold1.&_Icarus_temphold2" outfile="%sysfunc(pathname(work))/&_Icarus_temphold2";
run;
%include "%sysfunc(pathname(work))/&_Icarus_temphold2" /lrecl=500;
%nrstr(%symdel _Icarus_temphold1);
%nrstr(%symdel _Icarus_temphold2);
endrsubmit;
%END;
%IF &Wait=Y %THEN
%DO;
waitfor _ALL_
%DO i = 1 %TO &num %BY 1;
%obtomacro (&ControlDataSet,Alias,&i)
&NodeAlias%STR( )
%END;
timeout=&timeout;
%END;
%exit:
%mend icarus_distcode;
%macro icarus_distslice(ControlDataSet=_DJM_NONE, 
DataSet=_DJM_NONE, 	
DataSetNames=_ic_slice, 
deloriginal=N, 
Includelocal=N);
%local num i rworkref tempdata;
%let tempdata=_djm_ic_temp;
%let num=%numofobs(&ControlDataSet);
%let Includelocal=%UPCASE(%SUBSTR(&Includelocal,1,1));
%IF &Includelocal=Y %THEN
%DO;
%LET num=%EVAL(&num+1);
%END;
%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));
%IF &DataSet=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must enter a valid data set to slice.;
%PUT ERROR: Aborting icarus_distslicer...;
%GOTO exit;
%END;
%IF %DsetValidate(&Dataset)=0 %THEN
%DO;
%PUT ERROR: &Dataset does not exist.;
%PUT ERROR: Aborting icarus_distslicer;
%GOTO exit;
%END;
%IF &ControlDataSet=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must enter a valid data set to slice.;
%PUT ERROR: Aborting icarus_distslicer...;
%GOTO exit;
%END;
%IF %DsetValidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: &ControlDataSet does not exist.;
%PUT ERROR: Aborting icarus_distslicer;
%GOTO exit;
%END;
%dsetslicer(Dataset=&DataSet,
N=&num,
Sequential=N,
Partitions=_DJM_NONE,
DataSetRoot=work._ic_t,
DorV=V,
Report=N,
ReportDSet=work.Datasets,
deloriginal=N);
%IF &includelocal=Y %THEN
%DO;
PROC SQL;
%DO i = 1 %TO %EVAL(&num-1) %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
CREATE TABLE &rworkref..&DataSetNames.&i AS
SELECT *
FROM work._ic_t&i;
%END;
CREATE TABLE work.&DataSetNames.&num AS
SELECT *
FROM work._ic_t&i;
QUIT;
%deletedsets(
%DO i = 1 %TO &num %BY 1;
work._ic_t&i%STR( )
%END;
);
%END;
%ELSE
%DO;
PROC SQL;
%DO i = 1 %TO &num %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
CREATE TABLE &rworkref..&DataSetNames.&i AS
SELECT *
FROM work._ic_t&i;
%END;
QUIT;
%deletedsets(
%DO i = 1 %TO &num %BY 1;
work._ic_t&i%STR( )
%END;
);
%END;
%IF &deloriginal=Y %THEN %DO;
%deletedsets(&Dataset);
%END;
%exit:
%mend icarus_distslice;
%macro icarus_distsmoosh(ControlDataSet=_DJM_NONE, 
OutData=_DJM_NONE, 	
DataSetNames=_ic_slice,
deloriginal=N, 
Includelocal=N);
%local num i rworkref tempdata;
%let tempdata=_djm_ic_temp;
%let num=%numofobs(&ControlDataSet);
%let Includelocal=%UPCASE(%SUBSTR(&Includelocal,1,1));
%IF &Includelocal=Y %THEN
%DO;
%LET num=%EVAL(&num+1);
%END;
%LET deloriginal=%UPCASE(%SUBSTR(&deloriginal,1,1));
%IF &ControlDataSet=_DJM_NONE %THEN
%DO;
%PUT ERROR: You must enter a valid data set to slice.;
%PUT ERROR: Aborting icarus_distsmoosh...;
%GOTO exit;
%END;
%IF %DsetValidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: &ControlDataSet does not exist.;
%PUT ERROR: Aborting icarus_distsmoosh;
%GOTO exit;
%END;
%IF &includelocal=Y %THEN
%DO;
PROC SQL;
%DO i = 1 %TO %EVAL(&num-1) %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
CREATE TABLE work.&DataSetNames.&i AS
SELECT *
FROM &rworkref..&DataSetNames.&i;
%END;
QUIT;
%END;
%ELSE
%DO;
PROC SQL;
%DO i = 1 %TO %EVAL(&num) %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
CREATE TABLE work.&DataSetNames.&i AS
SELECT *
FROM &rworkref..&DataSetNames.&i;
%END;
QUIT;
%END;
%dsetsmoosh(Outdata=&OutData,
N=_DJM_AUTO,
DataSetRoot=work.&DataSetNames,
deloriginal=Y);
%IF &deloriginal=Y %THEN
%DO;
%IF &includelocal=Y %THEN
%DO;
%deletedsets(
%DO i = 1 %TO %EVAL(&num-1) %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
&rworkref..&DataSetNames.&i%STR( )
%END;
);
%END;
%ELSE
%DO;
%deletedsets(
%DO i = 1 %TO %EVAL(&num) %BY 1;
%let rworkref=%obtomacro(&ControlDataSet, RWork, &i);
&rworkref..&DataSetNames.&i%STR( )
%END;
);
%END;
%END;
%exit:
%mend icarus_distsmoosh;
%macro icarus_distvar(ControlDataSet=_DJM_NONE, DistVar= , DistVarValue = _DJM_NONE, LocalSessionVar = N);
%local myoplist oplist totallist;
%let myoplist = Alias RWork IcarusGerminate;
%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
%let totallist = &myoplist &oplist;
%LET LocalSessionVar = %UPCASE(%SUBSTR(&LocalSessionVar,1,1));
%IF %dsetvalidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: &ControlDataSet does not exist.;
%PUT ERROR: Aborting icarus_distvar macro...;
%GOTO exit;
%END;
%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN
%DO;
%PUT ERROR: &ControlDataSet does not meet the requirements of an;
%PUT ERROR: icarus_connect control data set;
%PUT ERROR: Aborting icarus_distvar macro...;
%GOTO exit;
%END;
%local num Nodealias i;
%LET num = %numofobs(&ControlDataSet);
%DO i = 1 %TO &num %BY 1;
%let Nodealias = %obtomacro(&ControlDataSet, Alias, &i);
%IF &DistVarValue = _DJM_NONE %THEN
%SYSLPUT &DistVar = &i /remote=&NodeAlias;
%ELSE %SYSLPUT &DistVar = &DistVarValue /remote=&NodeAlias;
%END;
%IF &LocalSessionVar = Y %THEN
%DO;
%GLOBAL &DistVar;
%IF &DistVarValue = _DJM_NONE %THEN %DO;
&DistVar = %EVAL(%numofobs(&ControlDataSet)+1);
%END;
%ELSE %DO;
&DistVar = &DistVarValue;
%END;
%END;
%exit:
%mend icarus_distvar;
%macro icarus_distvardel(ControlDataSet = _DJM_NONE, DistVar = , LocalSessionVar = N);
%local myoplist oplist totallist;
%let myoplist = Alias RWork IcarusGerminate;
%let oplist = AuthDomain CMacVar ConnectRemote ConnectStatus ConnectWait CScript;
%let oplist = &oplist CSysRPutSync InheritLib Log Output NoCScript Notify Password;
%let oplist = &oplist Sascmd Server Serverv SignonWait Subject TBufSize;
%let totallist = &myoplist &oplist;
%IF %dsetvalidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: &ControlDataSet does not exist.;
%PUT ERROR: Aborting icarus_distvardel macro...;
%GOTO exit;
%END;
%IF %UPCASE(%varlistfromdset(&ControlDataSet))^= %UPCASE(&totallist) %THEN
%DO;
%PUT ERROR: &ControlDataSet does not meet the requirements of an;
%PUT ERROR: icarus_connect control data set;
%PUT ERROR: Aborting icarus_distvardel macro...;
%GOTO exit;
%END;
%local num Nodealias i;
%LET num = %numofobs(&ControlDataSet);
%DO i = 1 %TO &num %BY 1;
%let Nodealias = %obtomacro(&ControlDataSet, Alias, &i);
%SYSLPUT _Icarus_temphold1=%BQUOTE(&DistVar) /remote=&NodeAlias;
rsubmit &NodeAlias;
%nrstr(%symdel &_Icarus_temphold1);
%nrstr(%symdel _Icarus_temphold1);
endrsubmit;
%END;
waitfor _ALL_
%DO i = 1 %TO &num %BY 1;
%obtomacro (&ControlDataSet,Alias,&i)
&NodeAlias%STR( )
%END;
timeout=30;
%IF &LocalSessionVar = Y %THEN
%DO;
%IF %symexist(&DistVar)=1 %THEN %DO;
%symdel &DistVar;
%END;
%END;
%exit:
%mend icarus_distvardel;
%macro icarus_germinate(NodeAlias=_DJM_NONE,
Icaruslocation=&_Icarus_installation);
%local temphold localcode ;
%global _IC_germstatus;
%let _IC_germstatus=0;
%SYSLPUT _Icarus_temphold1=%BQUOTE(&Icaruslocation.icarus_install.sas) /remote=&NodeAlias;
rsubmit &NodeAlias. connectwait=YES;
proc upload infile="&_Icarus_temphold1" outfile="%sysfunc(pathname(work))/icarus_install.sas"; run;
%include "%sysfunc(pathname(work))/icarus_install.sas";
%icarus_install(Location=%sysfunc(pathname(work)));
%nrstr(%symdel _Icarus_temphold1);
%NRSTR(%SYSRPUT _IC_germstatus = %dsetvalidate(work.icarus_functions));
endrsubmit;
waitfor &NodeAlias timeout=30;
%IF &SYSRC^=0 %THEN %DO;
%PUT ERROR: Timeout while waiting for Icarus to germinate on &NodeAlias;
%PUT ERROR: There is a good chance the germination has failed;
%END;
%ELSE %IF &_IC_germstatus^=1 %THEN %DO;
%PUT ERROR: It appears that the germination has failed on &NodeAlias;
%END;
%ELSE %IF &_IC_germstatus=1 %THEN %DO;
%PUT NOTE: ICARUS GERMINATED ON %UPCASE(&NodeAlias);
%END;
%IF %SYMEXIST(_IC_germstatus) %THEN %SYMDEL _IC_germstatus;
%mend icarus_germinate;
%macro icarus_allfunctions();
%IF %UPCASE(&sysscp) = WIN %THEN %DO;
proc proto package=&Functionlib..icarus;
   /* THE JARO STRING COMPARATOR FUNCTION IN C */
mapmiss double=-1.0;
double cjaro(const char *string1,const char *string2);
   externc cjaro;

double cjaro(const char *string1,const char *string2)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating jaro/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    return ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
}
   externcend;

   /* WINKLER STRING COMPARATOR FUNCTION IN C */

double cwinkler(const char *string1,const char *string2, const double score);
   externc cwinkler;

double cwinkler(const char *string1,const char *string2, const double score)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int sameatstart = 0;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
		if (sameatstart < 4) ++sameatstart;
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating winkler/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    jaroresult = ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
	return (jaroresult+((sameatstart*score)*(1-jaroresult)));
}
   externcend;
 
run;
%END;
%ELSE %DO;
proc proto package=&Functionlib..icarus;
   /* THE JARO STRING COMPARATOR FUNCTION IN C */
mapmiss double=-1.0;
double cjaro(const char *string1,const char *string2);
   externc cjaro;

double cjaro(const char *string1,const char *string2)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating jaro/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    return ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
}
%PUT NOTE: Nonwindows hacknote;
   externcend;

   /* WINKLER STRING COMPARATOR FUNCTION IN C */

double cwinkler(const char *string1,const char *string2, const double score);
   externc cwinkler;

double cwinkler(const char *string1,const char *string2, const double score)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int sameatstart = 0;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
		if (sameatstart < 4) ++sameatstart;
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating winkler/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    jaroresult = ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
	return (jaroresult+((sameatstart*score)*(1-jaroresult)));
}
%PUT Note: Nonwindows hacknote;
   externcend;
 
run;
%END;
proc fcmp outlib=&Functionlib..icarus;
function jaro(s1 $, s2 $);
val = cjaro(strip(s1),strip(s2));
return (val);
endsub;
function winkler(s1 $, s2 $, number);
val = cwinkler(strip(s1), strip(s2), number);
return (val);
endsub;
FUNCTION CAVERPHONE(string_1 $) $ 10;
IF missing(string_1) THEN return('');
workstring=compress(LOWCASE(trim(string_1)),,'kl');
length lengthvar 8;
lengthvar=length(workstring);
if substr(workstring,lengthvar,1)='e' THEN DO;
IF lengthvar=1 THEN workstring='e';
ELSE workstring=substr(workstring,1,lengthvar-1);
end;
lengthvar=length(workstring);
IF find(workstring,'cough',-5)=1 then do;
IF lengthvar=5 then workstring='cou2f';
else workstring='cou2f'||substr(workstring,6);
end;
IF find(workstring,'rough',-5)=1 then do;
IF lengthvar=5 then workstring='rou2f';
else workstring='rou2f'||substr(workstring,6);
end;
IF find(workstring,'tough',-5)=1 then do;
IF lengthvar=5 then workstring='tou2f';
else workstring='tou2f'||substr(workstring,6);
end;
IF find(workstring,'enough',-6)=1 then do;
IF lengthvar=6 then workstring='enou2f';
else workstring='enou2f'||substr(workstring,7);
end;
IF find(workstring,'trough',-6)=1 then do;
IF lengthvar=6 then workstring='trou2f';
else workstring='trou2f'||substr(workstring,7);
end;
IF find(workstring,'gn',-2)=1 then do;
IF lengthvar=2 then workstring='2n';
else workstring='2n'||substr(workstring,3);
end;
IF find(workstring,'mb',-2)=lengthvar-1 then do;
IF lengthvar=2 then workstring='m2';
else workstring=substr(workstring,1,lengthvar-2)||'m2';
end;
workstring=TRANWRD(workstring,'cq','2q');
workstring=TRANWRD(workstring,'ci','si');
workstring=TRANWRD(workstring,'ce','se');
workstring=TRANWRD(workstring,'cy','sy');
workstring=TRANWRD(workstring,'tch','2ch');
workstring=TRANWRD(workstring,'c','k');
workstring=TRANWRD(workstring,'q','k');
workstring=TRANWRD(workstring,'x','k');
workstring=TRANWRD(workstring,'v','f');
workstring=TRANWRD(workstring,'dg','2g');
workstring=TRANWRD(workstring,'tio','sio');
workstring=TRANWRD(workstring,'tia','sia');
workstring=TRANWRD(workstring,'d','t');
workstring=TRANWRD(workstring,'ph','fh');
workstring=TRANWRD(workstring,'b','p');
workstring=TRANWRD(workstring,'sh','s2');
workstring=TRANWRD(workstring,'z','s');
workstring=PRXCHANGE('s/^(a|e|i|o|u)/A/o',-1,workstring);
workstring=PRXCHANGE('s/(a|e|i|o|u)/3/o',-1,workstring);
workstring=TRANSLATE(workstring,'y','j');
workstring=PRXCHANGE('s/^y3/Y3/o',-1,workstring);
workstring=PRXCHANGE('s/^y/A/o',-1,workstring);
workstring=TRANSLATE(workstring,'3','y');
workstring=TRANWRD(workstring,'3gh3','3kh3');
workstring=TRANWRD(workstring,'gh','22');
workstring=TRANSLATE(workstring,'k','g');
workstring=PRXCHANGE('s/s+/S/o',-1,workstring);
workstring=PRXCHANGE('s/t+/T/o',-1,workstring);
workstring=PRXCHANGE('s/p+/P/o',-1,workstring);
workstring=PRXCHANGE('s/k+/K/o',-1,workstring);
workstring=PRXCHANGE('s/f+/F/o',-1,workstring);
workstring=PRXCHANGE('s/m+/M/o',-1,workstring);
workstring=PRXCHANGE('s/n+/N/o',-1,workstring);
workstring=TRANWRD(workstring,'w3','W3');
workstring=TRANWRD(workstring,'wh3','Wh3');
workstring=PRXCHANGE('s/w$/3/o',-1,trim(workstring));
workstring=TRANSLATE(workstring,'2','w');
workstring=PRXCHANGE('s/^h/A/o',-1,workstring);
workstring=TRANSLATE(workstring,'2','h');
workstring=TRANWRD(workstring,'r3','R3');
workstring=PRXCHANGE('s/r$/3/o',-1,trim(workstring));
workstring=TRANSLATE(workstring,'2','r');
workstring=TRANWRD(workstring,'l3','L3');
workstring=PRXCHANGE('s/l$/3/o',-1,trim(workstring));
workstring=TRANSLATE(workstring,'2','l');
workstring=TRANSTRN(workstring,'2',trimn(''));
workstring=PRXCHANGE('s/3$/A/o',-1,trim(workstring));
workstring=TRANSTRN(workstring,'3',trimn(''));
workstring=trim(workstring)||'1111111111';
CAVERPHONEValue=substr(workstring,1,10);
return(CAVERPHONEValue);
endsub;
FUNCTION CHEBYSHEV2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=MAX(ABS(a1-a2),ABS(b1-b2));
return(distance);
endsub;
FUNCTION CHEBYSHEV3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=MAX(ABS(a1-a2),ABS(b1-b2),ABS(c1-c2));
return(distance);
endsub;
FUNCTION CITYBLOCK2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=ABS(a1-a2)+ABS(b1-b2);
return(distance);
endsub;
FUNCTION CITYBLOCK3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=ABS(a1-a2)+ABS(b1-b2)+ABS(c1-c2);
return(distance);
endsub;
FUNCTION DMETAPHONE(string_1 $, dmetaoption) $ 9;
IF missing(string_1) then return ('');
slavogermanic=0;
alternate=0;
length string $ 64 string_pad $ 64 pre_pad $ 64 DMPV1 $ 9 DMPV2 $ 9;
string=TRIM(LEFT(UPCASE(string_1)));
s_length=length(string);
string_pad=TRIM(string)||'     ';
pre_pad='      '||TRIM(string)||'     ';
IF INDEX(string,'W')>0 OR INDEX(string,'K')>0 OR INDEX(string,'CZ')>0 OR INDEX(string,'WITZ')>0 THEN
Slavogermanic=1;
current=1;
IF substr(string_pad,1,2) in ('GN','KN','PN','WR','PS') then
current=current+1;
else if substr(string_pad,1,1)='X' then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
current=current+1;
end;
loopcount=0;
DO WHILE((length(trim(DMPV1))<=4 OR length(trim(DMPV2))<=4 OR current<=s_length) AND loopcount<64);
loopcount=loopcount+1;
letter=substr(string_pad,current,1);
IF letter in ('A','E','I','O','U','Y') AND current=1 THEN
DO;
DMPV1=compress(DMPV1||'A');
DMPV2=compress(DMPV2||'A');
current=current+1;
END;
ELSE IF letter='B' THEN
DO;
DMPV1=compress(DMPV1||'P');
DMPV2=compress(DMPV2||'P');
IF substr(string_pad,current+1,1)='B' then
current=current+2;
ELSE current=current+1;
END;
ELSE IF letter='Ç' THEN
DO;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
current=current+1;
END;
ELSE IF letter='C' THEN
DO;
IF (current>2 AND substr(pre_pad,current+6-2,1) NOT IN ('A','E','I','O','U','Y') 
AND substr(pre_pad,current+6-1,3)='ACH') AND (substr(string_pad,current+2,1) NOT IN ('I','E') 
OR substr(pre_pad,current+6-2,6) in ('BACHER','MACHER')) THEN
DO;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
ELSE IF current=1 and substr(string_pad,current,6)='CAESAR' THEN
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
current=current+2;
end;
ELSE IF substr(string_pad,current,4)='CHIA' THEN
DO;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
ELSE IF substr(string_pad,current,2)='CH' THEN
DO;
IF current>1 and substr(string_pad,current,4)='CHAE' then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'X');
current=current+2;
end;
ELSE IF current=1 and 
(substr(string_pad,current+1,5) in ('HARAC','HARIS') OR substr(string_pad,current+1,3) IN ('HOR','HYM','HIA','HEM'))
and substr(string_pad,1,5)^='CHORE' then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
end;
else IF (SUBSTR(string_pad,1,4) in ('VAN ','VON ') OR SUBSTR(string_pad,1,3)='SCH') 
OR SUBSTR(pre_pad,current+6-2,6) in ('ORCHES', 'ARCHIT', 'ORCHID') 
OR SUBSTR(string_pad,current+2,1) in ('T','S') 
OR (SUBSTR(pre_pad,current+6-1,1) in ('A','O','U','E') OR (current=1) AND   
SUBSTR(string_pad,current+2,1) in ('L','R','N','M','B','H','F','V','W',' '))
Then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
ELSE
do;
IF current>1 then
do;
IF SUBSTR(string_pad,1,2)='MC' then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
ELSE
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'K');
END;
end;
ELSE
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
END;
END;
current=current+2;
END;
Else IF SUBSTR(string_pad,current,2)='CZ' AND SUBSTR(pre_pad,current+6-2,4)^='WICZ' then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'X');
current=current+2;
END;
Else IF SUBSTR(string_pad,current+1,3)='CIA' then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
current=current+3;
END;
Else IF SUBSTR(string_pad,current,2)='CC' AND NOT (current=2 AND SUBSTR(string_pad,1,1)='M') then
do;
IF SUBSTR(string_pad,current+2,1) in ('I','E','H') AND 
SUBSTR(string_pad, current+2,2)^='HU' Then
do;
IF((current=2) AND (SUBSTR(pre_pad,current+6-1,1)='A')) 
OR SUBSTR(pre_pad,current+6-1,5) in ('UCCEE','UCCES') then
do;
DMPV1=compress(DMPV1||'KS');
DMPV2=compress(DMPV2||'KS');
End;
ELSE
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
END;
current=current+3;
end;
ELSE
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
END;
Else IF SUBSTR(string_pad,current,2) in ('CK','CG','CQ') then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
Else IF SUBSTR(string_pad,current,2) in ('CI','CE','CY') then
do;
IF SUBSTR(string_pad, current, 3) in ('CIO', 'CIE', 'CIA') then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'X');
End;
ELSE
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
END;
current=current+2;
END;
Else
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
* name sent in mac caffrey, mac gregor;
IF SUBSTR(string_pad,current+1,2) in (' C',' Q',' G') then
do;
current=current+3;
end;
ELSE
do;
IF SUBSTR(string_pad,current+1,1) in ('C','K','Q') 
AND SUBSTR(string_pad, current+1, 2) not in ('CE', 'CI') THEN
DO;
current=current+2;
END;
ELSE
DO;
current=current+1;
END;
END;
END;
END;
Else If letter='D' then
do;
IF SUBSTR(string_pad,current,2)='DG' then
do;
IF SUBSTR(string_pad,current+2,1) in ('I','E','Y') then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
current=current+3;
end;
ELSE
do;
DMPV1=compress(DMPV1||'TK');
DMPV2=compress(DMPV2||'TK');
current=current+2;
END;
END;
Else IF SUBSTR(string_pad,current,2) in ('DT','DD') then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
Else
do;
DMPV1=compress(DMPV1||'T');
DMPV2=compress(DMPV2||'T');
current=current+1;
end;
end;
Else If letter='F' then
do;
IF SUBSTR(string_pad,current+1,1)='F' then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'F');
DMPV2=compress(DMPV2||'F');
End;
Else If letter='G' then
do;
IF SUBSTR(string_pad,current+1,1)='H' then
do;
IF (current>1) AND 
SUBSTR(pre_pad,current+6-1,1) not in ('A','E','I','O','U','Y') then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
current=current+2;
END;
Else IF current < 4 then
do;
IF current=1 then
do;
IF SUBSTR(string_pad,current+2,1)='I' then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
End;
ELSE
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
current=current+2;
END;
END;
Else IF ((current>2) AND SUBSTR(pre_pad,current+6-2,1) in ('B','H','D')) OR 
((current>3) AND SUBSTR(pre_pad,current+6-3,1) in ('B','H','D')) OR 
((current>4) AND SUBSTR(pre_pad,current+6-4,1) in ('B','H')) then
do;
current=current+2;
end;
ELSE
do;
* e.g., laugh, McLaughlin, cough, gough, rough, tough;
IF (current>3) AND 
SUBSTR(pre_pad,current+6-1,1)='U' AND 
SUBSTR(pre_pad,current+6-3,1) in ('C','G','L','R','T') then
do;
DMPV1=compress(DMPV1||'F');
DMPV2=compress(DMPV2||'F');
End;
ELSE
do;
IF (current>1) AND SUBSTR(pre_pad,current+6-1,1)^='I' then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
END;
END;
current=current+2;
END;
END;
Else IF SUBSTR(string_pad,current+1,1)='N' then
do;
IF (current = 2) AND substr(string_pad,1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') AND 
SlavoGermanic=0 then
do;
DMPV1=compress(DMPV1||'KN');
DMPV2=compress(DMPV2||'N');
End;
ELSE
do;
IF SUBSTR(string_pad, current+2, 2) ^= 'EY' 
AND (SUBSTR(string_pad,current+1,1) ^= 'Y') AND SlavoGermanic=0 then
do;
DMPV1=compress(DMPV1||'N');
DMPV2=compress(DMPV2||'KN');
End;
ELSE
do;
DMPV1=compress(DMPV1||'KN');
DMPV2=compress(DMPV2||'KN');
END;
END;
current=current+2;
END;
Else IF SUBSTR(string_pad,current+1,2)='LI' AND SlavoGermanic=0 then
do;
DMPV1=compress(DMPV1||'KL');
DMPV2=compress(DMPV2||'L');
current=current+2;
END;
Else IF (current=1) and
(SUBSTR(string_pad,current+1,1)='Y' OR 
SUBSTR(string_pad,current+1,2) IN ('ES','EP','EB','EL','EY','IB','IL','IN','IE','EI','ER'))
Then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'J');
current=current+2;
END;
Else IF (SUBSTR(string_pad,current+1,2)='ER' OR SUBSTR(string_pad,current+1,1)='Y')
AND SUBSTR(string_pad,1,6) not in ('DANGER','RANGER','MANGER') 
AND SUBSTR(pre_pad,current+6-1,1) not in ('E','I') 
AND SUBSTR(pre_pad,current+6-1,3) not in ('RGY','OGY') then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'J');
current=current+2;
END;
Else IF SUBSTR(string_pad,current+1,1) in ('E', 'I', 'Y') OR 
SUBSTR(pre_pad,current+6-1,4) in ('AGGI','OGGI') then
do;
IF SUBSTR(string_pad,1,4) in ('VAN ', 'VON ') OR SUBSTR(string_pad,1,3)='SCH' OR 
SUBSTR(string_pad,current+1,2)='ET' then
do;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
ELSE
do;
IF SUBSTR(string_pad,current+1,4)='IER ' then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
End;
ELSE
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'K');
END;
END;
current=current+2;
END;
Else IF SUBSTR(string_pad,current+1,1)='G' then
do;
current=current+2;
end;
ELSE
do;
current=current+1;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
End;
Else If letter='H' then
do;
IF (current=1 OR 
SUBSTR(pre_pad,current+6-1,1) in ('A', 'E', 'I', 'O', 'U', 'Y')) AND 
substr(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') then
do;
DMPV1=compress(DMPV1||'H');
DMPV2=compress(DMPV2||'H');
current=current+2;
end;
ELSE
do;
current=current+1;
END;
End;
Else If letter='J' then
do;
IF SUBSTR(string_pad,current,4)='JOSE' OR SUBSTR(string_pad,1,4)='SAN ' then
do;
IF ((current=1) AND (SUBSTR(string_pad,current+4,1)=' ')) OR 
SUBSTR(string_pad,1,4)='SAN ' Then
do;
DMPV1=compress(DMPV1||'H');
DMPV2=compress(DMPV2||'H');
End;
ELSE
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'H');
END;
current=current+1;
END;
Else IF (current=1) AND SUBSTR(string_pad,current,4)^='JOSE' then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'A');
End;
ELSE
do;
IF SUBSTR(pre_pad,current+6-1,1) IN ('A','E','I','O','U','Y') AND 
SlavoGermanic=0 AND 
((SUBSTR(string_pad,current+1,1)='A') OR (SUBSTR(string_pad,current+1,1)='O')) then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'H');
End;
ELSE
do;
IF current=s_length then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
End;
ELSE
do;
IF SUBSTR(string_pad,current+1,1) not in ('L','T','K','S','N','M','B','Z')           
AND SUBSTR(pre_pad,current+6-1,1) not in ('S','K','L') then
do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
END;
END;
END;
END;
IF SUBSTR(string_pad,current+1,1)='J' then
do;
current=current+2;
end;
ELSE
do;
current=current+1;
END;
End;
Else If letter='K' then
do;
IF SUBSTR(string_pad,current+1,1)='K' then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
End;
Else If letter='L' then
do;
IF SUBSTR(string_pad,current+1,1)='L' then
do;
IF (current=(s_length-2) AND 
SUBSTR(pre_pad,current+6-1,4) in ('ILLO','ILLA','ALLE')) 
OR 
(current>1 AND (SUBSTR(string_pad,s_length-1, 2) in ('AS', 'OS') OR 
SUBSTR(string_pad,s_length,1) in ('A','O')) AND 
SUBSTR(pre_pad,current+6-1,4)='ALLE') Then
do;
DMPV1=compress(DMPV1||'L');
DMPV2=compress(DMPV2||'L');
current=current+2;
end;
else
do;
current=current+2;
end;
end;
ELSE
do;
DMPV1=compress(DMPV1||'L');
DMPV2=compress(DMPV2||'L');
current=current+1;
end;
end;
Else If letter='M' then
do;
* dumb,thumb;
IF SUBSTR(pre_pad,current+6-1,3)='UMB' AND 
(current+1=s_length OR SUBSTR(string_pad,current+2,2)='ER') 
OR SUBSTR(string_pad,current+1,1)='M' then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'M');
DMPV2=compress(DMPV2||'M');
end;
Else If letter='N' then
do;
IF SUBSTR(string_pad,current+1,1)='N' then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'N');
DMPV2=compress(DMPV2||'N');
end;
Else If letter='Ñ' then
do;
current=current+1;
DMPV1=compress(DMPV1||'N');
DMPV2=compress(DMPV2||'N');
end;
Else If letter='P' then
do;
IF SUBSTR(string_pad,current+1,1)='H' then
do;
DMPV1=compress(DMPV1||'F');
DMPV2=compress(DMPV2||'F');
current=current+2;
END;
Else
do;
IF SUBSTR(string_pad, current+1, 1) in ('P', 'B') then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'P');
DMPV2=compress(DMPV2||'P');
END;
End;
Else If letter='Q' then
do;
IF SUBSTR(string_pad,current+1,1)='Q' then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'K');
DMPV2=compress(DMPV2||'K');
end;
Else If letter='R' then
do;
IF (current=s_length) AND SlavoGermanic=0 
AND SUBSTR(pre_pad,current+6-2,2)='IE' 
AND SUBSTR(pre_pad,current+6-4,2) not in ('ME', 'MA') then
do;
DMPV2=compress(DMPV2||'R');
End;
ELSE
do;
DMPV1=compress(DMPV1||'R');
DMPV2=compress(DMPV2||'R');
END;
IF SUBSTR(string_pad,current+1,1)='R' then
current=current+2;
ELSE current=current+1;
End;
Else If letter='S' then
do;
IF SUBSTR(pre_pad,current+6-1,3) in ('ISL','YSL') then
do;
current=current+1;
END;
;
IF (current=1) AND SUBSTR(string_pad,current,5)='SUGAR' then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'S');
current=current+1;
END;
Else IF SUBSTR(string_pad,current,2)='SH' then
do;
IF SUBSTR(string_pad, current+1, 4) in ('HEIM', 'HOEK', 'HOLM', 'HOLZ') then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
End;
ELSE
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
END;
current=current+2;
END;
Else IF SUBSTR(string_pad,current,3) in ('SIO','SIA') OR SUBSTR(string_pad,current,4)='SIAN' Then
do;
IF SlavoGermanic=0 then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'X');
End;
ELSE
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
END;
current=current+3;
END;
Else IF current=1 AND 
(SUBSTR(string_pad,current+1,1) in ('M','N','L','W') 
OR SUBSTR(string_pad,current+1,1)='Z') then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'X');
IF SUBSTR(string_pad,current+1,1)='Z' then
current=current+2;
ELSE current=current+1;
END;
Else IF SUBSTR(string_pad,current,2)='SC' then
do;
IF SUBSTR(string_pad,current+2,1)='H' then
do;
IF SUBSTR(string_pad,current+3,2) in ('OO','ER','EN','UY','ED','EM') then
do;
IF SUBSTR(string_pad, current+3,2) in ('ER','EN') then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'SK');
End;
ELSE
do;
DMPV1=compress(DMPV1||'SK');
DMPV2=compress(DMPV2||'SK');
End;
current=current+3;
end;
ELSE
do;
IF (current=1) AND SUBSTR(string_pad,3,1) not in ('A','E','I','O','U','Y') AND 
SUBSTR(string_pad,3,1)^='W' then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'S');
End;
ELSE
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
END;
current=current+3;
END;
END;
Else IF SUBSTR(string_pad,current+2,1) in ('I', 'E', 'Y') then
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
current=current+3;
END;
Else
do;
DMPV1=compress(DMPV1||'SK');
DMPV2=compress(DMPV2||'SK');
current=current+3;
end;
END;
Else IF (current=s_length) and SUBSTR(pre_pad,current+6-2,2) in ('AI','OI') then
do;
DMPV2=compress(DMPV2||'S');
current=current+1;
end;
ELSE
do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
IF SUBSTR(string_pad,current+1,1) in ('S','Z') then
current=current+2;
ELSE current=current+1;
End;
End;
Else If letter='T' then
do;
IF SUBSTR(string_pad,current,4)='TION' then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
current=current+3;
END;
Else IF SUBSTR(string_pad,current,3) in ('TIA','TCH') then
do;
DMPV1=compress(DMPV1||'X');
DMPV2=compress(DMPV2||'X');
current=current+3;
END;
Else IF SUBSTR(string_pad,current,2)='TH' OR SUBSTR(string_pad,current,3)='TTH' then
do;
IF SUBSTR(string_pad,current+2,2) in ('OM','AM') OR 
SUBSTR(string_pad,1,4) in ('VAN ','VON ') OR 
SUBSTR(string_pad,1,3)='SCH' then
do;
DMPV1=compress(DMPV1||'T');
DMPV2=compress(DMPV2||'T');
End;
ELSE
do;
DMPV1=compress(DMPV1||'0');
DMPV2=compress(DMPV2||'T');
END;
current=current+2;
END;
Else
do;
IF SUBSTR(string_pad,current+1,1) in ('T','D') then
current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'T');
DMPV2=compress(DMPV2||'T');
END;
End;
Else If letter='V' then do;
IF SUBSTR(string_pad,current+1,1)='V' then current=current+2;
ELSE current=current+1;
DMPV1=compress(DMPV1||'F');
DMPV2=compress(DMPV2||'F');
End;
Else If letter='W' then do;
IF SUBSTR(string_pad,current,2)='WR' then do;
DMPV1=compress(DMPV1||'R');
DMPV2=compress(DMPV2||'R');
current=current+2;
END;
Else IF (current=1) AND 
(SUBSTR(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') OR 
SUBSTR(string_pad, current, 2)='WH') then do;
IF SUBSTR(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') then do;
DMPV1=compress(DMPV1||'A');
DMPV2=compress(DMPV2||'F');
End;
ELSE do;
DMPV1=compress(DMPV1||'A');
DMPV2=compress(DMPV2||'A');
End;
current=current+1;
END;
Else IF (current=s_length AND
SUBSTR(pre_pad,current+6-1,1) in ('A', 'E', 'I', 'O', 'U', 'Y')) OR
SUBSTR(pre_pad,current+6-1,5) in ('EWSKI','EWSKY','OWSKI','OWSKY') OR
SUBSTR(string_pad,1,3)='SCH' then do;
DMPV2=compress(DMPV2||'F');
current=current+1;
END;
Else IF SUBSTR(string_pad,current,4)in ('WICZ', 'WITZ') then do;
DMPV1=compress(DMPV1||'TS');
DMPV2=compress(DMPV2||'FX');
current=current+4;
END;
Else do;
current=current+1;
end;
end;
else If letter='X' then do;
* french e.g. breaux;
IF (current^=s_length and 
SUBSTR(pre_pad,current+6-3,3) not in ('IAU', 'EAU') AND
SUBSTR(pre_pad,current+6-2,2) not in ('AU', 'OU')) then do;
DMPV1=compress(DMPV1||'KS');
DMPV2=compress(DMPV2||'KS');
END;
IF SUBSTR(string_pad, current+1, 1) in ('C', 'X') then current=current+2;
ELSE current=current+1;
End;
Else If letter='Z' then do;
* chinese pinyin e.g. zhao;
IF SUBSTR(string_pad,current+1,1)='H' then do;
DMPV1=compress(DMPV1||'J');
DMPV2=compress(DMPV2||'J');
current=current+2;
end;
ELSE do;
IF SUBSTR(string_pad,current+1,2) in ('ZO','ZI','ZA') OR 
(SlavoGermanic=1 AND current>1 AND SUBSTR(pre_pad,current+6-1,1) ne 'T') 
then do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'TS');
end;
ELSE do;
DMPV1=compress(DMPV1||'S');
DMPV2=compress(DMPV2||'S');
end;
IF SUBSTR(string_pad,current+1,1)='Z' then current=current+2;
ELSE current=current+1;
END;
END;
ELSE CURRENT=current+1;
END;
IF length(trim(DMPV1))>4 THEN
DMPV1=substr(DMPV1,1,4);
IF length(trim(DMPV2))>4 THEN
DMPV2=substr(DMPV2,1,4);
if dmetaoption=1 then
return(DMPV1);
else if dmetaoption=2 then
return(DMPV2);
else return(trim(DMPV1)||','||trim(DMPV2));
endsub;
FUNCTION EUCLIDEAN2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=SQRT((a1-a2)**2+(b1-b2)**2);
return(distance);
endsub;
FUNCTION EUCLIDEAN3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=SQRT((a1-a2)**2+(b1-b2)**2+(c1-c2)**2);
return(distance);
endsub;
FUNCTION lowfuzz(num_1,num_2,diff);
IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
else IF num_1-num_2<=diff AND num_1-num_2>=0 THEN RETURN(1);
ELSE RETURN(0);
endsub;
FUNCTION highfuzz(num_1,num_2,diff);
IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
else IF num_1-num_2>=-(diff) AND num_1-num_2<=0 THEN RETURN(1);
ELSE RETURN(0);
endsub;
FUNCTION genfuzz(num_1,num_2,diff);
IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
else IF ABS(num_1-num_2)<=diff THEN RETURN(1);
ELSE RETURN(0);
endsub;
FUNCTION HAMMING(string1 $,string2 $);
if missing(string1) or missing(string2) THEN return(.);
else if string1=string2 THEN return (0);
stringlen1=length(string1);
stringlen2=length(string2);
if stringlen1^=stringlen2 then return (.);
j=0;
do i=1 to stringlen1 by 1;
if substr(string1,i,1)^=substr(string2,i,1) then j=j+1;
end;
return(j);
endsub;
FUNCTION MINKOWSKI2(a1,b1,a2,b2,p);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) or missing(p) then return(.);
distance=((ABS(a1-a2))**p+(ABS(b1-b2))**p)**(1/p);
return(distance);
endsub;
FUNCTION MINKOWSKI3(a1,b1,c1,a2,b2,c2,p);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) or missing(p) then return(.);
distance=((ABS(a1-a2))**p+(ABS(b1-b2))**p+(ABS(c1-c2))**p)**(1/p);
return(distance);
endsub;
FUNCTION NYSIIS(string_1 $) $ 6;
length lengthvar 8 NYSIIS $6 firstchar $1;
workstring = UPCASE(TRIM(LEFT(string_1)));
workstring = PRXCHANGE('s/[^A-Z]//o',-1,workstring);
IF PRXMATCH('/^MAC/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^MAC/MCC/o',-1,workstring);
ELSE 
IF PRXMATCH('/^KN/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^KN/NN/o',-1,workstring);
ELSE 
IF PRXMATCH('/^K/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^K/C/o',-1,workstring);
ELSE
IF PRXMATCH('/^PH/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^PH|^PF/FF/o',-1,workstring);
ELSE
IF PRXMATCH('/^SCH/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^SCH/SSS/o',-1,workstring);
IF PRXMATCH('/EE$|IE$/o',trim(workstring)) THEN
workstring = PRXCHANGE('s/EE$|IE$/Y/o',-1,trim(workstring));
else IF PRXMATCH('/DT$|RT$|RD$|NT$|ND$/o',trim(workstring)) THEN
workstring = PRXCHANGE('s/DT$|RT$|RD$|NT$|ND$/D/o',-1,trim(workstring));
firstChar = substr(workstring,1,1);
IF length(workstring)=1 THEN workstring='';
ELSE workstring=substr(workstring,2);
                                 
workstring = PRXCHANGE('s/EV/AF/o',-1,workstring);
workstring = PRXCHANGE('s/[AEIOU]+/A/o',-1,workstring);
	  	  	  	  	 
workstring = PRXCHANGE('s/Q/G/o',-1,workstring);
	  	  	  	  	 
workstring = PRXCHANGE('s/Z/S/o',-1,workstring);
	  	  	  	  	 
workstring = PRXCHANGE('s/M/N/o',-1,workstring);
 	 
workstring = PRXCHANGE('s/KN/N/o',-1,workstring);
workstring = PRXCHANGE('s/K/C/o',-1,workstring);
 	  	  	  	  	 
workstring = PRXCHANGE('s/SCH/SSS/o',-1,workstring);
  	  	  	  	 
workstring = PRXCHANGE('s/PH/FF/o',-1,workstring);
workstring = PRXCHANGE('s/([^AEIOU])H/$1/o',-1,workstring);
workstring = PRXCHANGE('s/(.)H[^AEIOU]/$1/o',-1,workstring);
workstring = PRXCHANGE('s/[AEIOU]W/A/o',-1,workstring);
workstring = PRXCHANGE('s/S$//o',-1,trim(workstring));
workstring = PRXCHANGE('s/AY$/Y/o',-1,trim(workstring));
workstring = PRXCHANGE('s/A$//o',-1,trim(workstring));
workstring = PRXCHANGE('s/[AEIOU]+/A/o',-1,workstring);
workstring = PRXCHANGE('s/B+/B/o',-1,workstring);
workstring = PRXCHANGE('s/C+/C/o',-1,workstring);
workstring = PRXCHANGE('s/D+/D/o',-1,workstring);
workstring = PRXCHANGE('s/F+/F/o',-1,workstring);
workstring = PRXCHANGE('s/G+/G/o',-1,workstring);
workstring = PRXCHANGE('s/H+/H/o',-1,workstring);
workstring = PRXCHANGE('s/J+/J/o',-1,workstring);
workstring = PRXCHANGE('s/K+/K/o',-1,workstring);
workstring = PRXCHANGE('s/L+/L/o',-1,workstring);
workstring = PRXCHANGE('s/M+/M/o',-1,workstring);
workstring = PRXCHANGE('s/N+/N/o',-1,workstring);
workstring = PRXCHANGE('s/P+/P/o',-1,workstring);
workstring = PRXCHANGE('s/Q+/Q/o',-1,workstring);
workstring = PRXCHANGE('s/R+/R/o',-1,workstring);
workstring = PRXCHANGE('s/S+/S/o',-1,workstring);
workstring = PRXCHANGE('s/T+/T/o',-1,workstring);
workstring = PRXCHANGE('s/V+/V/o',-1,workstring);
workstring = PRXCHANGE('s/W+/W/o',-1,workstring);
workstring = PRXCHANGE('s/X+/X/o',-1,workstring);
workstring = PRXCHANGE('s/Y+/Y/o',-1,workstring);
workstring = PRXCHANGE('s/Z+/Z/o',-1,workstring);
lengthvar=length(workstring);
IF lengthvar>=5 then NYSIIS = firstChar||substr(workstring,1,5);
ELSE NYSIIS=firstchar||trim(workstring);
return(NYSIIS);
endsub;
FUNCTION EXPECTUNIQUE(odds,numofpersons);
if missing(odds) or missing(numofpersons) then
return(.);
expectedunique=numofpersons*(1-1/odds)**(numofpersons-1);
return(expectedunique);
endsub;
quit;
%mend icarus_allfunctions;
%icarus_allfunctions;
%macro icarusindex(		
DataSet=_DJM_NONE,
Vars=DJM_NONE,
Index1=work.Index1_1,
Index2=work.Index2_1,
ExcludeMissings=N,
exp=12);
%Local i tempquote;
%LET ExcludeMissings=%UPCASE(%SUBSTR(&ExcludeMissings,1,1));
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set does not exist;
%PUT ERROR: Aborting IcarusIndex...;
%GOTO exit;
%END;
%IF (&Vars=_DJM_NONE) %THEN
%DO;
%PUT ERROR: Vars must be supplied to the TwoIndexCreation macros;
%PUT ERROR: Aborting IcarusIndex...;
%GOTO exit;
%END;
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: All Vars are not present in Data Set;
%PUT ERROR: Aborting IcarusIndex...;
%GOTO exit;
%END;
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
%macro icarusindexdset(DataSet=_DJM_NONE,
ControlDataset=_DJM_NONE,
Index1Root=work.Icarusindex1_,
Index2Root=work.Icarusindex2_,
ExcludeMissings=N,
exp=12);
%local i vars num;
%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMIssings,1,1));
%IF %DSETVALIDATE(&DataSet)=0 %THEN
%DO;
%PUT ERROR: Data Set A does not exist;
%PUT ERROR: Aborting IcarusIndexDset...;
%GOTO exit;
%END;
%IF %DSETVALIDATE(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: ControlDataSet does not exist;
%PUT ERROR: Aborting IcarusIndexDset...;
%GOTO exit;
%END;
%LET Vars = %varlistfromdset(&ControlDataset);
%IF %Varsindset(&DataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
%PUT ERROR: Aborting IcarusIndexDset...;
%GOTO exit;
%END;
%LET num = %numofobs(&ControlDataSet);
%IF &num = 0 %THEN
%DO;
%PUT ERROR: ControlDataSet contains no observations;
%PUT ERROR: Aborting IcarusIndexDset...;
%GOTO exit;
%END;
%DO I = 1 %TO &num;
%icarusindex(		
DataSet=&DataSet,
Vars=%varkeeplistdset(&ControlDataSet,&I),
Index1=&Index1Root.&I,
Index2=&Index2Root.&I,
ExcludeMissings=&ExcludeMissings,
exp=&exp);
%END;
%exit:
%mend icarusindexdset;
%macro icarusindexjoin(IndexedDataSet=_DJM_NONE, 
IndexedDataSetVars=_DJM_NONE,
PrefixIndexedDataSet=,
OtherDataSet=_DJM_NONE,
OtherDataSetVars=_DJM_NONE,
PrefixOtherDataSet=,
ControlDataSet=_DJM_NONE,
Index1Root=work.Icarusindex1_,
Index2Root=work.Icarusindex2_,
FirstIndexNumber=_DJM_NONE,
LastIndexNumber=_DJM_NONE,
Outdata=work.IcarusIndexJoined,
DorV=V,
ExcludeMissings=N,
exp=12);
%local i Vars;
%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMissings,1,1));
%LET IndexeddataSetVars = %UPCASE(&IndexedDataSetVars);
%LET OtherdataSetVars = %UPCASE(&OtherDataSetVars);
%LET PrefixIndexedDataSet = %UPCASE(&PrefixIndexedDataSet);
%LET PrefixOtherDataSet = %UPCASE(&PrefixOtherDataSet);
%IF %DSETVALIDATE(&IndexedDataSet)=0 %THEN
%DO;
%PUT ERROR: IndexedDataSet does not exist;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%IF %DSETVALIDATE(&OtherDataSet)=0 %THEN
%DO;
%PUT ERROR: Other data set does not exist;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%IF &ControlDataSet^=_DJM_NONE %THEN
%DO;
%IF %DSETVALIDATE(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: Control Data Set does not exist;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%LET FirstIndexNumber = 1;
%LET LastIndexNumber = %numofobs(&ControlDataSet);
%LET Vars = %varlistfromdset(&ControlDataSet);
%IF %Varsindset(&IndexedDataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%IF &LastIndexNumber = 0 %THEN
%DO;
%PUT ERROR: ControlDataSet contains no observations;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%icarusindexdset(DataSet=&IndexedDataSet,
ControlDataset=&ControlDataSet,
Index1Root=&Index1Root,
Index2Root=&Index2Root,
ExcludeMissings=&ExcludeMissings,
exp=&exp);
%END;
%ELSE
%DO;
%IF &FirstIndexNumber = _DJM_NONE OR &LastIndexNumber = _DJM_NONE %THEN
%DO;
%PUT ERROR: If not specifying a control data set;
%PUT ERROR: User must supply FirstIndexNumber and LastIndexNumber;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%IF &FirstIndexNumber > &LastIndexNumber %THEN
%DO;
%PUT ERROR: FirstIndexNumber must be less than LastIndexNumber;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%DO I = &FirstIndexNumber %TO &LastIndexNumber;
%IF %DSETVALIDATE(&Index1Root.&i)=0 %THEN
%DO;
%PUT ERROR: &Index1Root.&i does not exist;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%IF %DSETVALIDATE(&Index2Root.&i)=0 %THEN
%DO;
%PUT ERROR: &Index2Root.&i does not exist;
%PUT ERROR: Aborting IcarusIndexJoin...;
%GOTO exit;
%END;
%END;
%END;
%local keepvarsA renamevarsA keepvarsB renamevarsB OutVarsA OutVarsB;
%IF &OtherDataSetVars = _DJM_NONE %THEN
%LET OtherDataSetVars = %varlistfromdset(&OtherDataSet);
%IF &IndexeddataSetVars = _DJM_NONE %THEN
%LET Indexeddatasetvars = %varlistfromdset(&IndexedDataSet);
%let keepVarsA =;
%let renameVarsA =;
%let keepVarsB =;
%let renameVarsB =;
%DO I = &FirstIndexNumber %TO &LastIndexNumber;
%let keepVarsA = %Uniquewords(&keepVarsA %varlistfromdset(&index1Root.&i));
%END;
%let keepVarsA = %removewordfromlist(_djm_end, %removewordfromlist(_djm_start, &KeepVarsA));
%let KeepVarsB = &keepVarsA;
%let keepVarsA = %Uniquewords(&keepVarsA &IndexedDataSetVars);
%let renamevarsA = %PL(&keepVarsA,&PrefixIndexedDataSet);
%let keepVarsB = %Uniquewords(&keepVarsB &OtherDataSetVars);
%let OutVarsA = %PL(&IndexedDataSetVars,&PrefixIndexedDataSet);
%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);
Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
length _ic__djm_start 8 _ic__djm_end 8 _ic__djm_rc1 8 _ic__djm_rc2 8 _djm_pointer 8 _djm_index1pointer 8;
IF _N_ = 0 then
set &IndexedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,_ic_),%STR(=),%STR( ))));
IF _N_ = 1 then
do;
call missing(_ic__djm_start,_ic__djm_end,_djm_pointer,_djm_index1pointer, _ic__djm_rc1, _ic__djm_rc2);
%DO I = &FirstIndexNumber %TO &LastIndexNumber;
%HashWriter(Hashname=_djm_iij&i,	
DataSet=&Index1Root.&i,
DataVars=_djm_start _djm_end,
KeyVars=%removewordfromlist(_djm_end, %removewordfromlist(_djm_start, %varlistfromdset(&index1Root.&i))),
addprefix=_ic_,
removeprefix=_DJM_NONE,
ExcludeMissings=&ExcludeMissings,
exp=&exp,
MultiData=N);
%END;
declare hash _djm_thash(hashexp:&exp, multidata:"N");
_djm_thash.defineKey("_djm_pointer");
_djm_thash.definedone();
end;
set &OtherDataSet(keep=&KeepVarsB rename=(%tvtdl(&KeepVarsB,%PL(&KeepVarsB,&PrefixOtherDataSet),%STR(=),%STR( ))));
%local releventkey;
%DO I = &FirstIndexNumber %TO &LastIndexNumber;
%LET releventkey = %removewordfromlist(_djm_end, %removewordfromlist(_djm_start, %varlistfromdset(&index1Root.&i)));
%LET releventkey = %PL(&releventkey,&PrefixOtherDataSet);
%LET releventkey = %tvtdl(%repeater(%STR(Key: ),%countwords(&releventkey,%STR( ))),&releventkey,%STR( ),%STR(,));
_ic__djm_rc1 = _djm_iij&i..find(&releventkey);
if _ic__djm_rc1 = 0 then
do;
do _djm_index1pointer = _ic__djm_start to _ic__djm_end by 1;
set &index2Root.&i point = _djm_index1pointer;
%IF &I = &FirstIndexNumber %THEN %DO;
_djm_thash.add();
set &IndexedDataSet(keep=&Indexeddatasetvars rename=(%tvtdl(&IndexedDataSetVars,%PL(&IndexedDataSetVars,&PrefixIndexedDataSet),%STR(=),%STR( )))) point = _djm_pointer;
output;
%END;
%ELSE %IF &I ^= &FirstIndexNumber %THEN %DO;
_iorc_ = _djm_thash.check();
if _iorc_ ^= 0 then
do;
_djm_thash.add();
set &IndexedDataSet(keep=&Indexeddatasetvars rename=(%tvtdl(&IndexedDataSetVars,%PL(&IndexedDataSetVars,&PrefixIndexedDataSet),%STR(=),%STR( )))) point = _djm_pointer;
output;
end;
%END;
end;
end;
%END;
_djm_thash.clear();
run;
%exit:
%mend icarusindexjoin;
%macro multihashjoin(HashedDataSet=_DJM_NONE, 
HashedDataSetVars=_DJM_NONE,
PrefixHashedDataSet=b_,
HashDataSetIDVar=_DJM_NONE,
OtherDataSet=_DJM_NONE,
OtherDataSetVars=_DJM_NONE,
PrefixOtherDataSet = a_,
ControlDataSet=_DJM_NONE,
Outdata=work.multihashjoined,
DorV=V,
ExcludeMissings=N,
exp=12);
%local i Vars;
%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMissings,1,1));
%LET HashedDataSetVars = %UPCASE(&HashedDataSetVars);
%LET OtherdataSetVars = %UPCASE(&OtherDataSetVars);
%LET PrefixHashedDataSet = %UPCASE(&PrefixHashedDataSet);
%LET PrefixOtherDataSet = %UPCASE(&PrefixOtherDataSet);
%IF %dsetvalidate(&HashedDataSet)=0 %THEN
%DO;
%PUT ERROR: HashedDataSet does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF %dsetvalidate(&OtherDataSet)=0 %THEN
%DO;
%PUT ERROR: Other data set does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF &ControlDataSet = _DJM_NONE %THEN %DO;
%PUT ERROR: Must supply a control data set;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF &ControlDataSet^=_DJM_NONE %THEN
%DO;
%IF %dsetvalidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: Control Data Set does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%LET Vars = %varlistfromdset(&ControlDataSet);
%IF %Varsindset(&HashedDataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%END;
%IF &HashDataSetIDVar=_DJM_NONE %THEN %DO;
%PUT ERROR: You must supply a HashDataSetIDVar;
%PUT ERROR: So the algorithm knows how to identify records from the hashdataset;
%PUT ERROR: that have already been compared to each record in the other;
%PUT ERROR: data set.  Aborting multihashjoin...;
%GOTO exit;
%END;
%local keepvarsA renamevarsA keepvarsB renamevarsB OutVarsA OutVarsB;
%IF &OtherDataSetVars = _DJM_NONE %THEN
%LET OtherDataSetVars = %varlistfromdset(&OtherDataSet);
%IF &HashedDataSetVars = _DJM_NONE %THEN
%LET HashedDataSetvars = %varlistfromdset(&HashedDataSet);
%let keepVarsA =;
%let renameVarsA =;
%let keepVarsB =;
%let renameVarsB =;
%DO I = 1 %TO %numofobs(&ControlDataSet);
%let keepVarsA = %Uniquewords(&keepVarsA %varkeeplistdset(&ControlDataSet,&I));
%END;
%let KeepVarsB = &keepVarsA;
%let keepVarsA = %Uniquewords(&keepVarsA &HashedDataSetVars);
%let keepVarsA = %Uniquewords(%UPCASE(&keepVarsA &HashDataSetIDVar));
%let renamevarsA = %PL(&keepVarsA,&PrefixHashedDataSet);
%let keepVarsB = %Uniquewords(%UPCASE(&keepVarsB &OtherDataSetVars));
%let OutVarsA = %PL(&HashedDataSetVars,&PrefixHashedDataSet);
%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);
Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
length _ic__djm_rc1 8 _ic__djm_rc2 8;
IF _N_ = 0 then
set &HashedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,&PrefixHashedDataSet),%STR(=),%STR( ))));
IF _N_ = 1 then
do;
call missing(_ic__djm_rc1, _ic__djm_rc2);
%DO I = 1 %TO %numofobs(&ControlDataSet) %BY 1;
%HashWriter(Hashname=_djm_iij&i,	
DataSet=&HashedDataSet,
DataVars=&HashedDataSetVars,
KeyVars=%UPCASE(%varkeeplistdset(&ControlDataSet,&I)),
addprefix=&PrefixHashedDataSet,
removeprefix=_DJM_NONE,
ExcludeMissings=&ExcludeMissings,
exp=&exp,
MultiData=Y)
%END;
declare hash _djm_thash(hashexp:&exp, multidata:"N");
_djm_thash.defineKey("&PrefixHashedDataSet.&HashDataSetIDVar");
_djm_thash.definedone();
end;
set &OtherDataSet(keep=&KeepVarsB rename=(%tvtdl(&KeepVarsB,%PL(&KeepVarsB,&PrefixOtherDataSet),%STR(=),%STR( ))));
%local releventkey;
%DO I = 1 %TO %numofobs(&ControlDataSet);
%LET releventkey = %varkeeplistdset(&ControlDataSet,&I);
%LET releventkey = %PL(&releventkey,&PrefixOtherDataSet);
%LET releventkey = %tvtdl(%repeater(%STR(Key: ),%countwords(&releventkey,%STR( ))),&releventkey,%STR( ),%STR(,));
%IF &I = 1 %THEN %DO;
_iorc_ = _djm_iij&i..find(&releventkey);
do while (_iorc_=0);
output;
_djm_thash.add();
_iorc_ = _djm_iij&i..find_next();
end;
%END;
%ELSE %IF &I ^= 1 %THEN %DO;
_iorc_ = _djm_iij&i..find(&releventkey);
do while (_iorc_=0);
_ic__djm_rc1 = _djm_thash.check();
if _ic__djm_rc1 ^= 0 then do;
_ic__djm_rc2 = _djm_thash.add();
output;
end;
_iorc_ = _djm_iij&i..find_next();
end;
%END;
%END;
_djm_thash.clear();
run;
%exit:
%mend multihashjoin;
%macro multihashpointjoin(HashedDataSet=_DJM_NONE, 
HashedDataSetVars=_DJM_NONE,
PrefixHashedDataSet=b_,
OtherDataSet=_DJM_NONE,
OtherDataSetVars=_DJM_NONE,
PrefixOtherDataSet=a_,
ControlDataSet=_DJM_NONE,
Indexviewroot=work.mhpjindex,
Outdata=work.mhpjoined,
DorV=V,
ExcludeMissings=N,
exp=12);
%local i Vars Viewvars;
%LET DorV = %UPCASE(%SUBSTR(&DorV,1,1));
%LET ExcludeMissings = %UPCASE(%SUBSTR(&ExcludeMissings,1,1));
%LET HashedDataSetVars = %UPCASE(&HashedDataSetVars);
%LET OtherdataSetVars = %UPCASE(&OtherDataSetVars);
%LET PrefixHashedDataSet = %UPCASE(&PrefixHashedDataSet);
%LET PrefixOtherDataSet = %UPCASE(&PrefixOtherDataSet);
%IF %dsetvalidate(&HashedDataSet)=0 %THEN
%DO;
%PUT ERROR: HashedDataSet does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF %dsetvalidate(&OtherDataSet)=0 %THEN
%DO;
%PUT ERROR: Other data set does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF &ControlDataSet = _DJM_NONE %THEN %DO;
%PUT ERROR: Must supply a control data set;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%IF &ControlDataSet^=_DJM_NONE %THEN
%DO;
%IF %dsetvalidate(&ControlDataSet)=0 %THEN
%DO;
%PUT ERROR: Control Data Set does not exist;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%LET Vars = %varlistfromdset(&ControlDataSet);
%IF %Varsindset(&HashedDataSet,&Vars)=0 %THEN
%DO;
%PUT ERROR: Variables from the Control Data Set are not present in &Dataset;
%PUT ERROR: Aborting multihashjoin...;
%GOTO exit;
%END;
%END;
%local keepvarsA renamevarsA keepvarsB renamevarsB OutVarsA OutVarsB;
%IF &OtherDataSetVars = _DJM_NONE %THEN
%LET OtherDataSetVars = %varlistfromdset(&OtherDataSet);
%IF &HashedDataSetVars = _DJM_NONE %THEN
%LET HashedDataSetvars = %varlistfromdset(&HashedDataSet);
%let keepVarsA =;
%let renameVarsA =;
%let keepVarsB =;
%let renameVarsB =;
%DO I = 1 %TO %numofobs(&ControlDataSet);
%let keepVarsA = %Uniquewords(&keepVarsA %varkeeplistdset(&ControlDataSet,&I));
%END;
%let KeepVarsB = &keepVarsA;
%let keepVarsA = %Uniquewords(&keepVarsA &HashedDataSetVars);
%let keepVarsA = %Uniquewords(%UPCASE(&keepVarsA));
%let renamevarsA = %PL(&keepVarsA,&PrefixHashedDataSet);
%let keepVarsB = %Uniquewords(%UPCASE(&keepVarsB &OtherDataSetVars));
%let OutVarsA = %PL(&HashedDataSetVars,&PrefixHashedDataSet);
%let OutVarsB = %PL(&OtherDataSetVars,&PrefixOtherDataSet);
%DO I = 1 %TO %numofobs(&ControlDataSet);
%let Viewvars = %varkeeplistdset(&ControlDataSet,&I);
Data &Indexviewroot.&i %IF &ExcludeMissings=Y %THEN (where=(%termlistpattern(&Viewvars, %STR(IS NOT MISSING),%STR( ),%STR( AND )))); /view=&Indexviewroot.&i;
length _djm_mhjpoint 8;
set &HashedDataSet(keep=&ViewVars);
_djm_mhjpoint = _N_;
run;
%END;
Data &outdata.(keep=%uniquewords(&OutVarsA &OutVarsB)) %IF &DorV=V %THEN /view=&outdata;;
length _ic__djm_rc1 8 _ic__djm_rc2 8 _ic__djm_mhjpoint 8;
IF _N_ = 0 then
set &HashedDataSet(keep=&KeepVarsA rename=(%tvtdl(&KeepVarsA,%PL(&KeepVarsA,_ic_),%STR(=),%STR( ))));
IF _N_ = 1 then
do;
call missing(_ic__djm_rc1, _ic__djm_rc2, _ic__djm_mhjpoint);
%DO I = 1 %TO %numofobs(&ControlDataSet) %BY 1;
%HashWriter(Hashname=_djm_iij&i,	
DataSet=&Indexviewroot.&i,
DataVars=_djm_mhjpoint,
KeyVars=%UPCASE(%varkeeplistdset(&ControlDataSet,&I)),
addprefix=_ic_,
removeprefix=_DJM_NONE,
ExcludeMissings=&ExcludeMissings,
exp=&exp,
MultiData=Y)
%END;
declare hash _djm_thash(hashexp:&exp, multidata:"N");
_djm_thash.defineKey("_ic__djm_mhjpoint");
_djm_thash.definedone();
end;
set &OtherDataSet(keep=&KeepVarsB rename=(%tvtdl(&KeepVarsB,%PL(&KeepVarsB,&PrefixOtherDataSet),%STR(=),%STR( ))));
%local releventkey;
%DO I = 1 %TO %numofobs(&ControlDataSet);
%LET releventkey = %varkeeplistdset(&ControlDataSet,&I);
%LET releventkey = %PL(&releventkey,&PrefixOtherDataSet);
%LET releventkey = %tvtdl(%repeater(%STR(Key: ),%countwords(&releventkey,%STR( ))),&releventkey,%STR( ),%STR(,));
%IF &I = 1 %THEN %DO;
_iorc_ = _djm_iij&i..find(&releventkey);
do while (_iorc_=0);
set &HashedDataSet(keep=&HashedDataSetVars rename=(%tvtdl(&HashedDataSetVars,%PL(&HashedDataSetVars,&PrefixHashedDataSet),%STR(=),%STR( )))) point = _ic__djm_mhjpoint;
output;
_djm_thash.add();
_iorc_ = _djm_iij&i..find_next();
end;
%END;
%ELSE %IF &I ^= 1 %THEN %DO;
_iorc_ = _djm_iij&i..find(&releventkey);
do while (_iorc_=0);
_ic__djm_rc1 = _djm_thash.check();
if _ic__djm_rc1 ^= 0 then do;
set &HashedDataSet(keep=&HashedDataSetVars rename=(%tvtdl(&HashedDataSetVars,%PL(&HashedDataSetVars,&PrefixHashedDataSet),%STR(=),%STR( )))) point = _ic__djm_mhjpoint;
_ic__djm_rc2 = _djm_thash.add();
output;
end;
_iorc_ = _djm_iij&i..find_next();
end;
%END;
%END;
_djm_thash.clear();
run;
%exit:
%mend multihashpointjoin;
%macro plainblocking(	DataSetA=_DJM_NONE,DataSetB=_DJM_NONE,
BlockVarsA=_DJM_NONE,BlockVarsB=_DJM_NONE,
VarsA=_DJM_NONE,VarsB=_DJM_NONE,
prefixa=a_,prefixb=b_,behaviour=1,exp=12,
outdata=work.blocked,DorV=V,
Excludemissings=Y);
%local cartesian;
%let cartesian = N;
%IF (&DataSetA=_DJM_NONE OR &DataSetB=_DJM_NONE) %THEN
%DO;
%PUT ERROR: You must enter both Data Set A and Data Set B;
%PUT ERROR: You cannot enter just one;
%PUT ERROR: If both are the same, feel free to supply the same data set for both parameters;
%PUT ERROR: Aborting the Plain Blocking Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSetA)=0 %THEN
%DO;
%PUT ERROR: &DataSetA does not exist;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%IF %dsetvalidate(&DataSetB)=0 %THEN
%DO;
%PUT ERROR: &DataSetB does not exist;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%IF &BlockVarsA=_DJM_NONE AND &BlockVarsB=_DJM_NONE %THEN
%DO;
%LET cartesian = Y;
%let behaviour = 2;
%LET Excludemissings = N;
%END;
%ELSE %IF (&BlockVarsA=_DJM_NONE OR &BlockVarsB=_DJM_NONE) %THEN
%DO;
%PUT ERROR: You must enter both BlockVars A and BlockVars B;
%PUT ERROR: You cannot enter just one;
%PUT ERROR: Aborting the Plain Blocking Macro...;
%GOTO exit;
%END;
%ELSE %IF &BlockVarsA^=&BlockVarsB %THEN
%DO;
%IF %countwords(&BlockVarsA,%STR( ))^=%countwords(&BlockVarsB,%STR( )) %THEN
%DO;
%PUT ERROR: A different number of variables have been specified in BlockVarsA and BlockVarsB;
%PUT ERROR: Aborting the Plain Blocking Macro...;
%GOTO exit;
%END;
%END;
%IF &BlockVarsA^=_DJM_NONE AND &BlockVarsB^=_DJM_NONE %THEN
%DO;
%IF %varsindset(&DataSetA,&BlockVarsA)=0 %THEN
%DO;
%PUT ERROR: At least one of the blocking variables does not exist on &DataSetA;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSetB,&BlockVarsB)=0 %THEN
%DO;
%PUT ERROR: At least one of the blocking variables does not exist on &DataSetB;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%END;
%IF &VarsA=_DJM_NONE %THEN
%DO;
%LET VarsA=%varlistfromdset(&DataSetA);
%END;
%IF &VarsB=_DJM_NONE %THEN
%DO;
%LET VarsB=%varlistfromdset(&DataSetB);
%END;
%IF %varsindset(&DataSetA,&VarsA)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables does not exist on &DataSetA;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%IF %varsindset(&DataSetB,&VarsB)=0 %THEN
%DO;
%PUT ERROR: At least one of the Linking variables does not exist on &DataSetB;
%PUT ERROR: Aborting Plain Blocking Macro...;
%GOTO exit;
%END;
%IF &behaviour=1 %THEN
%DO;
%HashJoin(DataSetA=&DataSetA,DataSetB=&DataSetB,JoinVarsA=&BlockVarsA,JoinVarsB=&BlockVarsB,DataVarsA=&VarsA,DataVarsB=&VarsB,exp=&exp,outdata=&outdata,DorV=&DorV,prefixA=&prefixA,prefixB=&prefixB,Excludemissings=&Excludemissings,jointype=IJ
);
%END;
%ELSE %IF &behaviour=2 %THEN
%DO;
PROC SQL;
%IF &DorV=D %THEN
CREATE TABLE &Outdata AS;
%ELSE %IF &DorV=V %THEN
CREATE VIEW &Outdata AS;
SELECT %tvtdl(%PL(&VarsA,a.),%PL(&VarsA,&prefixa),%STR( AS ) ,%STR(,)),%tvtdl(%PL(&VarsB,b.),%PL(&VarsB,&prefixb),%STR( AS ),%STR(,))
FROM &DataSetA as a, &DataSetB as b
%IF &cartesian=N %THEN
%DO;
WHERE %tvtdl(%PL(&BlockVarsA,a.),%PL(&BlockVarsB,b.),%STR(=),%STR( AND )) %IF &Excludemissings=Y %THEN AND %termlistpattern(%PL(&BlockVarsA,a.),IS NOT MISSING,%STR( ),%STR( AND ));
%END;
;
QUIT;
%END;
%exit:
%mend plainblocking;
%macro SNHood(
DataSet=, 
SortVar=,
Order=_DJM_NONE,
Outdata=work.SNHood,
VorD=V,
window=_DJM_NONE,
forevar=_DJM_NONE,
aftvar=_DJM_NONE,
prefixA=a_,
prefixB=b_,
denialvar=_DJM_NONE,
rollover=N,
tagsort=N
);
%let SortVar=%UPCASE(&SortVar);
%let Order=%UPCASE(&Order);
%let VorD=%UPCASE(%SUBSTR(&VorD,1,1));
%let tagsort = %UPCASE(%SUBSTR(&tagsort,1,1));
%let rollover = %UPCASE(%SUBSTR(&rollover,1,1));
%local I SortVar2 order2 sortorder num;
%IF %dsetvalidate(&DataSet) = 0 %THEN %DO;
%PUT ERROR: Data set &Dataset does not exist;
%PUT ERROR: Aborting snhood...;
%GOTO exit;
%END;
%IF &Order^=_DJM_NONE %THEN
%DO;
%let I=1;
%do %while(%scan(&SortVar,&I,%str( )) ^= %str( ));
%let order2=%scan(&Order,&I,%str( ));
%let SortVar2=%scan(&SortVar,&I,%str( ));
%if &order2^=D %THEN
%let order2=;
%else %let order2=DESCENDING;
%let sortorder=&sortorder &order2 &SortVar2;
%let I = %eval(&I+1);
%end;
%let SortVar=&sortorder;
%END;
%let num=%numofobs(&DataSet);
%let Varlist=%varlistfromdset(&DataSet);
%IF &window^=_DJM_NONE AND &forevar^=_DJM_NONE AND &aftvar^=_DJM_NONE %THEN
%DO;
%PUT ERROR: User has entered values for window, forevar and aftvar;
%PUT ERROR: These options are mutually exclusive;
%PUT ERROR: ABORTING.;
%GOTO exit;
%end;
%IF &window>&num AND &rollover=N AND &window^=_DJM_NONE %THEN
%DO;
%PUT ERROR: Window size in sorted neighbourhood greater than resulting size of data set.;
%PUT ERROR: Consider use of rollover option.;
%PUT ERROR: ABORTING.;
%GOTO exit;
%end;
%IF &forevar^=_DJM_NONE AND &aftvar^=_DJM_NONE %THEN %DO;
%LET Rollover = Y;
%END;
proc sort data=&Dataset
%IF &tagsort=Y %THEN tagsort;;
by &SortVar;
run;
%IF &foreVar=_DJM_NONE AND &aftvar=_DJM_NONE %THEN
%DO;
data &outdata(drop=_DJM_J) %IF &VORD^=D %THEN /VIEW=&Outdata;;
%IF %UPCASE(%SUBSTR(&rollover,1,1))=N OR &rollover=_DJM_NONE %THEN
%DO;
do _DJM_i = 1 to &num;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;
_DJM_j=1;
do while (_DJM_j<=&window-1 AND _DJM_i+_DJM_j<=&num);
newpoint=_DJM_i+_DJM_j;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
output;
_DJM_j=_DJM_j+1;
end;
end;
stop;
%END;
%ELSE
%DO;
do _DJM_i = 1 to &num;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;
_DJM_j=1;
do while (_DJM_j<=&window-1);
newpoint=_DJM_i+_DJM_j;
do until (newpoint<=&num);
if newpoint>&num then
newpoint=newpoint-&num;
end;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
output;
_DJM_j=_DJM_j+1;
end;
end;
stop;
%END;
run;
%END;
%ELSE
%DO;
%IF %varsindset(&dataset,&forevar &aftvar)=0 %THEN
%DO;
%PUT ERROR: Variables &forevar and &aftvar were not found on the reference data set:%UPCASE(&dataset);
%PUT ERROR: ABORTING;
%GOTO exit;
%END;
data &outdata(drop=_djm_j) %IF &VORD^=D %THEN /VIEW=&Outdata;;
do _DJM_i = 1 to &num;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixA),%STR(=),%STR( )))) point=_DJM_i;
_DJM_j=0-&prefixa.&forevar;
do while (_DJM_j<0);
newpoint=_DJM_i+_DJM_j;
do until (newpoint<=&num AND newpoint>=1);
if newpoint<=0 then
newpoint=newpoint+&num;
end;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
output;
_DJM_j=_DJM_j+1;
end;
_DJM_j=0+&prefixa.&aftvar;
do while (_DJM_j>0);
newpoint=_DJM_i+_DJM_j;
do until (newpoint<=&num AND newpoint>=1);
if newpoint>&num then
newpoint=newpoint-&num;
end;
set &dataset(rename=(%tvtdl(&varlist,%PL(&varlist,&prefixB),%STR(=),%STR( )))) point=newpoint;
%IF &denialvar^=_DJM_NONE %THEN if &prefixA.&denialvar^=&prefixB.&denialvar then;
output;
_DJM_j=_DJM_j-1;
end;
end;
stop;
run;
%END;
%exit:
%mend SNHood;
%mend icarus_install;