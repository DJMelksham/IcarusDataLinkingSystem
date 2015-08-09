
%macro ngramdsetword(Dataset=,Outdata=work.ngrammed,Var=_DJM_NONE,N=2,NgramVar=Ngram,Rollover=N,DorV=D,Delimiters=%STR( ),modifiers=o);
	%local MaxNumofwords MaxLengthofwords NumofNgrams LengthofNgrams NumofROWords Error I;
	%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));
	%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));

	/*************************************************************************************/
	/* Step 1: Obtain the maximum length and maximum number of N grams */
	/*************************************************************************************/
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

	/* Error check if a variable has less words than the number of N grams requested */
	%IF &Error=ERROR %THEN
		%DO;
			%PUT ERROR: A record for the variable &Var contains less words than the number of N grams requested;
			%PUT ERROR: Aborting...;
			%GOTO exit;
		%END;

	/* If N=1 then there's no use also having the rollover option set */
	%IF &N=1 %THEN
		%LET Rollover=N;

	/* Then we calculate the number of N-Grams and their maximum possible length */
	/* If the rollover option is set, then the maximum number of N grams per observation is equal to the number of words in a variable */
	%IF &Rollover=Y %THEN
		%DO;
			%LET NumofNgrams=%EVAL(&MaxNumofwords);
			%LET LengthofNGrams=%EVAL((&MaxLengthofwords*&N)+(&N-1)); /* We need to calculate the lengths with space for blanks as delimiters */
			%LET NumofROWords=%EVAL(&N-1);
		%END;
	%ELSE
		%DO;
			%LET NumofNGrams=%EVAL(&MaxNumofwords-&N+1); /* Number of N grams possible in a finite string */
			%LET LengthofNGrams=%EVAL((&MaxLengthofwords*&N)+(&N-1)); /* We need to calculate the lengths with space for blanks as delimiters */
			%LET NumofROWords=0;
		%END;

	/*************************************************************************************/
	/* Step 2: Data step where the Ngrams are actually calculated */
	/*************************************************************************************/
	%IF &Rollover=Y %THEN
		%DO;

			Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
				set &Dataset;
				length _djm_ngcount 8 _djm_owordcount 8 _djm_rowordcount 8 _djm_warraylen 8

					%DO I=1 %TO &NumofNGrams %BY 1;
				&NgramVar.&I $&LengthofNGrams
		%END;
	;
	/*array owords {&maxnumofwords} $&maxlengthofwords _temporary_;*/
	array rowords {&NumofROWords} $&maxlengthofwords _temporary_;
	array allwords {%EVAL(&maxnumofwords+&NumofROWords)} $&maxlengthofwords _temporary_;
	array _djm_NG {&NumofNGrams} $&lengthofNgrams %DO I=1 %TO &NumofNGrams %BY 1;
	&NgramVar.&I
	%END;
	;
	/**********************************/
	/* Populating the allwords arrays */
	/**********************************/
	/* On the first run, there are no ro words */
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

	/* On all other runs, there will always be ro words */
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

	/***********************************************************/
	/* With the allwords array populated, calculate the NGrams */
	/***********************************************************/
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

	/*****************************************************************************************/
	/* With the N grams calculated, populate the RO words and clear arrays for the next round*/
	/*****************************************************************************************/
	do _djm_i=1 to &NumofROWords by 1;
		rowords[_djm_i]=scan(&Var,_djm_owordcount-&NumofROWords+_djm_i,"&delimiters","&modifiers");
	end;
			run;

%END;

			/* IF ROLLOVER IS NOT SET, DO THIS INSTEAD*/
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
		/**********************************/
		/* Populating the allwords arrays */
		/**********************************/
		/* On the first run, there are no ro words */
		_djm_owordcount=countw(&Var,"&delimiters","&modifiers");
		_djm_ngcount=_djm_owordcount-&N+1;
		_djm_warraylen=_djm_owordcount;

		do _djm_i=1 to _djm_warraylen by 1;
			allwords[_djm_i]=scan(&Var,_djm_I,"&delimiters","&modifiers");
		end;

		/***********************************************************/
		/* With the allwords array populated, calculate the NGrams */
		/***********************************************************/
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

