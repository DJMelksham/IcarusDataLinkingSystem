%macro report_time;
%sysfunc(time(), time.);
%mend report_time;