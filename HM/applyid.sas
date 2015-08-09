/* This little macro applies a numeric ID to a data set, using the data steps simple _N_ generated variable */

%macro applyid(DataSet,IDVar);

data &DataSet;
set &DataSet;
&IDVar=_n_;
run;

%mend applyid;