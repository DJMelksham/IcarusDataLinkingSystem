/******************************************************************************/
/* Being a very simple macro, designed to return the TOP N observations given an ID and a weight.
   If there are less than N observations, the macro will return only the number of observations which 
   actually exist.
   Returns other variables in the observation as well.
   Requires the provision of an ID variable, and a weight variable.
   The user is given the option of whether to take the top N observations, or the top N weights
   (recognising that the top N weights designates a possibly undisclosed number of returned records,
	whereas TOP N observations has a logical maximum number of observations that can be returned.)*/

/* Performance options are as such:
1= NOEQUALS;
2= Regular proc sort;
3= NOEQUALS AND TAGSORT;
4= TAGSORT;*/

/*******************************************************************************/

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