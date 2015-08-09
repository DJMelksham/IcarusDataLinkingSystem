%macro genprob(
Dataset=_DJM_NONE,
ProbVars=_DJM_NONE,
Outdata=work.Probability,
ProbMax=0.99999999,
ProbMin=0.00000001,
positivevalue=1,
WeightVar=_DJM_AP_weight,
exp=12);

/* Reminder: positivevalue represents the value that we will be calculating the probability from:

i.e 0,1,or 2 from the agreement pattern file.  */

%local i varnum a_Var b_Var;

/**************************************************
ERROR CHECKING SECTION
**************************************************/

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

/*************************************************
ACTUAL CALCULATION SECTION
*************************************************/

/*********************************************************/
/* A DATA STEP TO PULL EVERYTHING OFF IN ONE PASS       */
/********************************************************/
Data &outdata(keep=&ProbVars);

set &dataset(rename = ( %tvtdl(&allvars,&plallvars,%STR(=),%STR( )))) end=_djm_eof;

/* Setting variable length */
length _djm_total 8 
%let I=1;
%do %while(&I<=&varnum);
					%scan(&probvars,&i,%STR( )) 8 
					_djm_var&i.count 8 
					%LET I=%EVAL(&I+1);
				%END;
;


/* Setting retained variables */
retain _djm_total
%let I=1;
%do %while(&I<=&varnum);
					_djm_var&i.count 
					%LET I=%EVAL(&I+1);
				%END;
;

IF _N_=1 then do;
_djm_total=0;
/* Initialising variables to zero */
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