%macro report_datetime;
%sysfunc(date(),EURDFWKX.), %sysfunc(time(), time.);
%mend report_datetime;