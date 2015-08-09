%macro getoption(_djm_option);
%local value;

%let value = %sysfunc(getoption(&_djm_option));
&value

%mend getoption;
