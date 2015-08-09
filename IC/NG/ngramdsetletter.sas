%macro ngramdsetletter(Dataset=,Outdata=work.ngrammed,Var=_DJM_NONE,Rollover=N,N=2,NgramVar=Ngram,DorV=D);
	%local MaxLengthofwords NumofNgrams LengthofNgrams NumofROLetters Error I Value number;
	%LET Rollover=%UPCASE(%SUBSTR(&Rollover,1,1));
	%LET DorV=%UPCASE(%SUBSTR(&DorV,1,1));
	%LET ERROR=&N;

	/*************************************************************************************/
	/* Step 1: Obtain the maximum length and maximum number of N grams */
	/*************************************************************************************/
	Data _null_;
		set &Dataset end=_djm_eof;
		length _djm_wordlength 8 _djm_wordlengthstore 8;
		retain _djm_wordlength _djm_wordlengthstore;

		if _n_=1 then
			do;
				_djm_wordlength=1;
				_djm_wordlengthstore=1;
			end;

		_djm_wordlength=length(strip(&Var));

		IF _djm_wordlength<&N then do;
			call symput('Error',put(_djm_wordlength,BEST12.));
			call symput('Value',SFNAME);
			call symput('Number',put(_N_,BEST12.));
			end;

		IF _djm_wordlength>_djm_wordlengthstore THEN
			_djm_wordlengthstore=_djm_wordlength;

		if _djm_eof then
			do;
				call symput('MaxLengthofwords',put(_djm_wordlengthstore,best12.));
			end;
	run;

	/* Error check if a variable has less words than the number of N grams requested */
/*	%IF &Error<&N %THEN*/
/*		%DO;*/
/*			%PUT ERROR: A record for the variable &Var contains less letters than the number of N grams requested;*/
/*			%PUT ERROR: Aborting...;*/
/*			%PUT &ERROR;*/
/*			%PUT &VALUE;*/
/*			%PUT &Number;*/
/*			%GOTO exit;*/
/*		%END;*/

	/* If N=1 then there's no use also having the rollover option set */
	%IF &N=1 %THEN
		%LET Rollover=N;

	/* Then we calculate the number of N-Grams and their maximum possible length */
	/* If the rollover option is set, then the maximum number of N grams per observation is equal to the number of letters in a word */
	%IF &Rollover=Y %THEN
		%DO;
			%LET NumofNgrams=%EVAL(&MaxLengthofwords);
			%LET NumofROLetters=%EVAL(&N-1);
		%END;
	%ELSE
		%DO;
			%LET NumofNGrams=%EVAL(&MaxLengthofWords-&N+1); /* Number of N grams possible in a finite string */
			%LET NumofROLetters=0;
		%END;

	/*************************************************************************************/
	/* Step 2: Data step where the Ngrams are actually calculated */
	/*************************************************************************************/
	%IF &Rollover=Y %THEN
		%DO;

			Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
				set &Dataset;
				length _djm_ngcount 8 _djm_olength 8

					%DO I=1 %TO &NumofNGrams %BY 1;
				&NgramVar.&I $&N
		%END;
	;

	array rolett {&NumofROLetters} $1 _temporary_;
	array alllett {%EVAL(&NumofROLetters+&MaxLengthofwords)} $1 _temporary_;
	array _djm_NG {&NumofNGrams} $&N %DO I=1 %TO &NumofNGrams %BY 1;
	&NgramVar.&I
	%END;
	;
	/**********************************/
	/* Populating the allwords arrays */
	/**********************************/
	/* On the first run, there are no ro words */
	IF _N_=1 THEN
		DO;
			_djm_olength=length(strip(&Var));
			_djm_ngcount=_djm_olength-&N+1;
			_djm_rowordcount=0;
			_djm_larraylen=_djm_olength;

			do _djm_i=1 to _djm_larraylen by 1;
				alllett[_djm_i]=substr(&Var,_djm_I,1);
			end;
		END;

	/* On all other runs, there will always be ro words */
	ELSE
		DO;
			_djm_olength=length(strip(&Var));
			_djm_ngcount=_djm_olength;
			_djm_rowordcount=&NumofROLetters;
			_djm_larraylen=_djm_olength+&NumofROLetters;

			do _djm_i=1 to &NumofROLetters by 1;
				alllett[_djm_i]=rolett[_djm_i];
			end;

			do _djm_i=%EVAL(&NumofROLetters+1) to _djm_larraylen by 1;
				alllett[_djm_i]=substr(&Var,_djm_I-&NumofROLetters,1);
			end;
		END;

	/***********************************************************/
	/* With the allwords array populated, calculate the NGrams */
	/***********************************************************/
	do _djm_i=1 to _djm_ngcount by 1;
		_djm_ng[_djm_i]=CAT(
			%DO I=1 %TO &N %BY 1;

		%IF &I^=&N %THEN
			%DO;
				alllett[%EVAL(&I-1)+_djm_i],
			%END;
		%ELSE
			%DO;
				alllett[%EVAL(&I-1)+_djm_i]
			%END;
%END;
		);
	end;

	/*****************************************************************************************/
	/* With the N grams calculated, populate the RO words and clear arrays for the next round*/
	/*****************************************************************************************/
	do _djm_i=1 to &NumofROLetters by 1;
		rolett[_djm_i]=substr(&Var,_djm_olength-&NumofROLetters+_djm_i,1);
	end;
			run;

%END;

			/* IF ROLLOVER IS NOT SET, DO THIS INSTEAD*/
		%ELSE
			%DO;

			Data &outdata (drop=_djm_:)%IF &DorV=V %THEN /view=&outdata;;
				set &Dataset;
				length _djm_ngcount 8 _djm_olength 8

					%DO I=1 %TO &NumofNGrams %BY 1;
				&NgramVar.&I $&N
		%END;
	;

	array alllett {%EVAL(&NumofROLetters+&MaxLengthofwords)} $1 _temporary_;
	array _djm_NG {&NumofNGrams} $&N %DO I=1 %TO &NumofNGrams %BY 1;
	&NgramVar.&I
	%END;
	;
	/**********************************/
	/* Populating the allwords arrays */
	/**********************************/
	/* On the first run, there are no ro words */
	
			_djm_olength=length(strip(&Var));
			_djm_ngcount=_djm_olength-&N+1;
			_djm_rowordcount=0;
			_djm_larraylen=_djm_olength;

			do _djm_i=1 to _djm_larraylen by 1;
				alllett[_djm_i]=substr(&Var,_djm_I,1);
			end;

	/***********************************************************/
	/* With the allwords array populated, calculate the NGrams */
	/***********************************************************/
	do _djm_i=1 to _djm_ngcount by 1;
		_djm_ng[_djm_i]=CAT(
			%DO I=1 %TO &N %BY 1;

		%IF &I^=&N %THEN
			%DO;
				alllett[%EVAL(&I-1)+_djm_i],
			%END;
		%ELSE
			%DO;
				alllett[%EVAL(&I-1)+_djm_i]
			%END;
%END;
		);
	end;

			run;


			%END;

		%exit:
%mend ngramdsetletter;