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
