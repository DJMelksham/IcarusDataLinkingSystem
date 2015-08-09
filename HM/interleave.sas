

%macro interleave(list1,list2);

%local I result;
	%let I=1;

	%do %while(%scan(&list1,&I,%str( )) ne %STR( ));
%let result=&result %scan(&list1,&I,%str( )) %scan(&list2,&I,%str( ));
		%let I = %eval(&I+1);
	%end;

	&result


%mend interleave;