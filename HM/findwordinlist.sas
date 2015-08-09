%macro findwordinlist(word,list);

%local result;
%let result=%sysfunc(prxmatch(/\b&word\b/,&list));
%if &result^=0 %THEN %let result=1;
&result

%mend findwordinlist;