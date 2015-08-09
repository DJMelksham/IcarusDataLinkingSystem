
%macro icarus_allfunctions();


%IF %UPCASE(&sysscp) = WIN %THEN %DO;
proc proto package=&Functionlib..icarus;
   /* THE JARO STRING COMPARATOR FUNCTION IN C */
mapmiss double=-1.0;
double cjaro(const char *string1,const char *string2);
   externc cjaro;

double cjaro(const char *string1,const char *string2)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating jaro/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    return ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
}
   externcend;

   /* WINKLER STRING COMPARATOR FUNCTION IN C */

double cwinkler(const char *string1,const char *string2, const double score);
   externc cwinkler;

double cwinkler(const char *string1,const char *string2, const double score)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int sameatstart = 0;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
		if (sameatstart < 4) ++sameatstart;
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating winkler/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    jaroresult = ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
	return (jaroresult+((sameatstart*score)*(1-jaroresult)));
}
   externcend;
 
run;
%END;
%ELSE %DO;
proc proto package=&Functionlib..icarus;
   /* THE JARO STRING COMPARATOR FUNCTION IN C */
mapmiss double=-1.0;
double cjaro(const char *string1,const char *string2);
   externc cjaro;

double cjaro(const char *string1,const char *string2)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating jaro/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    return ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
}
%PUT NOTE: Nonwindows hacknote;
   externcend;

   /* WINKLER STRING COMPARATOR FUNCTION IN C */

double cwinkler(const char *string1,const char *string2, const double score);
   externc cwinkler;

double cwinkler(const char *string1,const char *string2, const double score)
{
register int i;
 int range;
 int string1length;
 int string2length;
 int matches;
 int pos;
 int endpos;
 char string1match[64]={ 0 };
 char string2match[64]={ 0 };
 char string1hold[64]={ 0 };
 char string2hold[64]={ 0 };
 int transpositions;
 int sameatstart = 0;
 int c;
 int k;
 int j;
 double jaroresult;

if (string1[0] == '\0' || string2[0] == '\0') return -1.0;

  /* Next, if the two strings are equal, return 1 */

 i=0;
  while (i<63){
     
    if (string1[i] != string2[i]) {
    break;
      }
    else
		if (sameatstart < 4) ++sameatstart;
      if (string1[i] == '\0'){
    return 1.0;
    }

    i = ++i;

  }

     /* And at last we get to something that looks like the actual function */
 
  /* Get the length of the two strings */

  i = 0;
  while(string1[i++]!='\0'){}
  string1length = i - 1;

  i = 0;
  while(string2[i++]!='\0'){}
  string2length = i - 1;

  if (string1length > 63) string1length = 63;
  if (string2length > 63) string2length = 63;

/*
     The range is required to loop over in calculating winkler/winkler.
  */

  if (string1length >= string2length) {
      range = (string1length/2) - 1;
    } else {
    range = (string2length/2) - 1;
  }

/* Setting up a heap of things.
     The two arrays are used to hold binary match statuses
     from comparisons between characters in the two strings.

     The variable matches is an integer that is equal to the
     number of matches of characters between the two strings.

     Pos is used to both track the beginning search range
     and the current search position
     during searches through the two strings for matching characters.

     Endpos is used to track the ending search range.
*/
matches = 0;

  for(i = 0 ; i < string1length ; ++i){
    pos = ((i - range) > 0) ? (i - range) : 0;
    endpos = ((range + i) < string2length) ? (range + i) : string2length;
    while  ((pos <= endpos) && (string1match[i] != '1')){
      if ((string1[i] == string2[pos]) && (string2match[pos] != '1')){
      matches = ++matches;
      string1match[i]='1';
      string2match[pos]='1';
    }
      ++pos;
    }

  }

/* If there are no matching charactesr, then we do not
     bother with any more work.

     We return the value which says that the two strings
     are not alike at all.
  */

  if (matches == 0){
return 0.0;
}

    if (matches == 1){
      if (string1[0] != string2[0]){
    transpositions=0;
      }
    else {
      transpositions=0;
    }} else {
   
    for(i = 0 ; i < string1length ; ++i){
      string1hold[i]=string1[i];
    }
    for(i = 0; i < string2length ; ++i){
      string2hold[i]=string2[i];
    }

    i = 0;
    transpositions = 0;
    c = 0;
    k = 0;
    j = 0;

 while ((j < matches) || (k < matches)){
      if (j < matches){
    if (string1match[i]=='1'){
      string1hold[j]=string1[i];
j = ++j;
    }
      }
      if (k < matches){
    if (string2match[i]=='1'){
      string2hold[k]=string2[i];
 k = ++k;
    }
      }
      if ((j-1) >= c && (k-1) >= c){
    if (string1hold[c] != string2hold[c]) transpositions = ++transpositions;
    c = ++c;
      }

    i = ++i;
    }

    }

    ;

    jaroresult = ((1.0/3.0)*((matches/(double)string1length)+(matches/(double)string2length)+((matches-(transpositions/2.0))/(double)matches)));
	return (jaroresult+((sameatstart*score)*(1-jaroresult)));
}
%PUT Note: Nonwindows hacknote;
   externcend;
 
run;
%END;

proc fcmp outlib=&Functionlib..icarus;
	/* FCMP wrapper for Jaro string comparator */
function jaro(s1 $, s2 $);
val = cjaro(strip(s1),strip(s2));
       return (val);
   endsub;
   	
   /* FCMP wrapper for Winkler string comparator */
function winkler(s1 $, s2 $, number);
	val = cwinkler(strip(s1), strip(s2), number);
       return (val);
   endsub;

/* CAVERPHONE 2.0 */

FUNCTION CAVERPHONE(string_1 $) $ 10;

IF missing(string_1) THEN return('');
/*Set alphabetic characters to lower case and remove everything but lowercase characters */
workstring=compress(LOWCASE(trim(string_1)),,'kl');
length lengthvar 8;

/* remove final 'e' if it exists */
lengthvar=length(workstring);
if substr(workstring,lengthvar,1)='e' THEN DO;
IF lengthvar=1 THEN workstring='e';
ELSE workstring=substr(workstring,1,lengthvar-1);
end;

/* If the name starts with 'cough' make it 'cou2f' */
lengthvar=length(workstring);
IF find(workstring,'cough',-5)=1 then do;
IF lengthvar=5 then workstring='cou2f';
else workstring='cou2f'||substr(workstring,6);
end;

/* If the name starts with 'rough' make it 'rou2f' */
IF find(workstring,'rough',-5)=1 then do;
IF lengthvar=5 then workstring='rou2f';
else workstring='rou2f'||substr(workstring,6);
end;

/* If the name starts with 'tough' make it 'tou2f' */
IF find(workstring,'tough',-5)=1 then do;
IF lengthvar=5 then workstring='tou2f';
else workstring='tou2f'||substr(workstring,6);
end;

/* If the name starts with 'enough' make it 'enou2f' */
IF find(workstring,'enough',-6)=1 then do;
IF lengthvar=6 then workstring='enou2f';
else workstring='enou2f'||substr(workstring,7);
end;
/* If the name starts with 'trough' make it 'trou2f' */
IF find(workstring,'trough',-6)=1 then do;
IF lengthvar=6 then workstring='trou2f';
else workstring='trou2f'||substr(workstring,7);
end;
/* If the name starts with 'gn' make it '2n' */
IF find(workstring,'gn',-2)=1 then do;
IF lengthvar=2 then workstring='2n';
else workstring='2n'||substr(workstring,3);
end;
/* If the name ends with 'mb' make it 'm2' */
IF find(workstring,'mb',-2)=lengthvar-1 then do;
IF lengthvar=2 then workstring='m2';
else workstring=substr(workstring,1,lengthvar-2)||'m2';
end;

/* replace cq with 2q */

workstring=TRANWRD(workstring,'cq','2q');

/* replace ci with si */

workstring=TRANWRD(workstring,'ci','si');

/* replace ce with se */

workstring=TRANWRD(workstring,'ce','se');

/* replace cy with sy */

workstring=TRANWRD(workstring,'cy','sy');

/* replace tch with 2ch */

workstring=TRANWRD(workstring,'tch','2ch');

/* replace c with k */

workstring=TRANWRD(workstring,'c','k');

/* replace q with k */

workstring=TRANWRD(workstring,'q','k');

/* replace x with k */

workstring=TRANWRD(workstring,'x','k');

/* replace v with f */

workstring=TRANWRD(workstring,'v','f');

/* replace dg with 2g */

workstring=TRANWRD(workstring,'dg','2g');

/* replace tio with sio */

workstring=TRANWRD(workstring,'tio','sio');

/* replace tia with sia */

workstring=TRANWRD(workstring,'tia','sia');

/* replace d with t */

workstring=TRANWRD(workstring,'d','t');

/* replace ph with fh */

workstring=TRANWRD(workstring,'ph','fh');

/* replace b with p */

workstring=TRANWRD(workstring,'b','p');

/* replace sh with s2 */

workstring=TRANWRD(workstring,'sh','s2');

/* replace z with s */

workstring=TRANWRD(workstring,'z','s');

/* STAND BACK! I'M USING PERL REGULAR EXPRESSIONS!*/
/* replace initial vowels with A */

workstring=PRXCHANGE('s/^(a|e|i|o|u)/A/o',-1,workstring);

/* replace all other vowels with a 3 */

workstring=PRXCHANGE('s/(a|e|i|o|u)/3/o',-1,workstring);

/* replace j with y */

workstring=TRANSLATE(workstring,'y','j');

/* replace an initial y3 with Y3 */

workstring=PRXCHANGE('s/^y3/Y3/o',-1,workstring);

/* replace an initial y with A */

workstring=PRXCHANGE('s/^y/A/o',-1,workstring);

/* replace y with 3 */

workstring=TRANSLATE(workstring,'3','y');

/* replace 3gh3 with 3kh3 */

workstring=TRANWRD(workstring,'3gh3','3kh3');

/* replace gh with 22 */

workstring=TRANWRD(workstring,'gh','22');

/* replace g with k */

workstring=TRANSLATE(workstring,'k','g');

/* replace groups of the letter s with a S */

workstring=PRXCHANGE('s/s+/S/o',-1,workstring);

/* replace groups of the letter t with a T */

workstring=PRXCHANGE('s/t+/T/o',-1,workstring);

/* replace groups of the letter p with a P */

workstring=PRXCHANGE('s/p+/P/o',-1,workstring);

/* replace groups of the letter k with a K */

workstring=PRXCHANGE('s/k+/K/o',-1,workstring);

/* replace groups of the letter f with a F */

workstring=PRXCHANGE('s/f+/F/o',-1,workstring);

/* replace groups of the letter m with a M */

workstring=PRXCHANGE('s/m+/M/o',-1,workstring);

/* replace groups of the letter n with a N */

workstring=PRXCHANGE('s/n+/N/o',-1,workstring);

/* replace w3 with W3 */

workstring=TRANWRD(workstring,'w3','W3');

/* replace wh3 with Wh3 */

workstring=TRANWRD(workstring,'wh3','Wh3');

/* if the name ends in w replace the final w with 3 */

workstring=PRXCHANGE('s/w$/3/o',-1,trim(workstring));

/* replace w with 2 */

workstring=TRANSLATE(workstring,'2','w');

/* replace an initial h with an A */

workstring=PRXCHANGE('s/^h/A/o',-1,workstring);

/* replace all other occurrences of h with a 2 */

workstring=TRANSLATE(workstring,'2','h');

/* replace r3 with R3 */

workstring=TRANWRD(workstring,'r3','R3');

/* if the name ends in r replace the final r with 3*/

workstring=PRXCHANGE('s/r$/3/o',-1,trim(workstring));

/* replace r with 2 */

workstring=TRANSLATE(workstring,'2','r');

/* replace l3 with L3 */

workstring=TRANWRD(workstring,'l3','L3');

/* if the name ends in l replace the final l with 3 */

workstring=PRXCHANGE('s/l$/3/o',-1,trim(workstring));

/* replace l with 2 */

workstring=TRANSLATE(workstring,'2','l');

/* remove all 2's */

workstring=TRANSTRN(workstring,'2',trimn(''));

/* if the name ends in 3, replace the final 3 with A */

workstring=PRXCHANGE('s/3$/A/o',-1,trim(workstring));

/* remove all 3's */

workstring=TRANSTRN(workstring,'3',trimn(''));

/* put ten 1's on the end */

workstring=trim(workstring)||'1111111111';

/* take the first ten characters as the code */

CAVERPHONEValue=substr(workstring,1,10);

return(CAVERPHONEValue);
endsub;

/* CHEBYSHEV FUNCTIONS */

FUNCTION CHEBYSHEV2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=MAX(ABS(a1-a2),ABS(b1-b2));
return(distance);
endsub;

FUNCTION CHEBYSHEV3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=MAX(ABS(a1-a2),ABS(b1-b2),ABS(c1-c2));
return(distance);
endsub;

/* CITYBLOCK DISTANCES */

FUNCTION CITYBLOCK2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=ABS(a1-a2)+ABS(b1-b2);
return(distance);
endsub;

FUNCTION CITYBLOCK3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=ABS(a1-a2)+ABS(b1-b2)+ABS(c1-c2);
return(distance);
endsub;

FUNCTION DMETAPHONE(string_1 $, dmetaoption) $ 9;

IF missing(string_1) then return ('');

		slavogermanic=0;
	alternate=0;
	length string $ 64 string_pad $ 64 pre_pad $ 64 DMPV1 $ 9 DMPV2 $ 9;
	string=TRIM(LEFT(UPCASE(string_1)));
	s_length=length(string);

	/* padding the original string so we can index past the end of the string.*/
	string_pad=TRIM(string)||'     ';
	pre_pad='      '||TRIM(string)||'     ';

	/* Searching for letters to check for slavogermanic flag */
	IF INDEX(string,'W')>0 OR INDEX(string,'K')>0 OR INDEX(string,'CZ')>0 OR INDEX(string,'WITZ')>0 THEN
		Slavogermanic=1;
	current=1;

	/* skip these when at start of word */
	IF substr(string_pad,1,2) in ('GN','KN','PN','WR','PS') then
		current=current+1;

	/* Initial 'X' is pronounced 'Z' e.g Xavier */
	else if substr(string_pad,1,1)='X' then
		do;
			DMPV1=compress(DMPV1||'S');
			DMPV2=compress(DMPV2||'S');
			current=current+1;
		end;

	loopcount=0;

	/* start of main loop */
	DO WHILE((length(trim(DMPV1))<=4 OR length(trim(DMPV2))<=4 OR current<=s_length) AND loopcount<64);
		/* just like link king guy, a counter to prevent endless loop */
		loopcount=loopcount+1;
		letter=substr(string_pad,current,1);

		IF letter in ('A','E','I','O','U','Y') AND current=1 THEN
			DO;
				DMPV1=compress(DMPV1||'A');
				DMPV2=compress(DMPV2||'A');
				current=current+1;
			END;

		/* CASE B */
		/* '-MB', E.G 'DUMB', ALREADY SKIPPED OVER */
		ELSE IF letter='B' THEN
			DO;
				DMPV1=compress(DMPV1||'P');
				DMPV2=compress(DMPV2||'P');

				IF substr(string_pad,current+1,1)='B' then
					current=current+2;
				ELSE current=current+1;
			END;
		ELSE IF letter='Ç' THEN
			DO;
				DMPV1=compress(DMPV1||'S');
				DMPV2=compress(DMPV2||'S');
				current=current+1;
			END;

		/* CASE C */
		ELSE IF letter='C' THEN
			DO;
				/* Various Germanic */
				IF (current>2 AND substr(pre_pad,current+6-2,1) NOT IN ('A','E','I','O','U','Y') 
					AND substr(pre_pad,current+6-1,3)='ACH') AND (substr(string_pad,current+2,1) NOT IN ('I','E') 
					OR substr(pre_pad,current+6-2,6) in ('BACHER','MACHER')) THEN
					DO;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');
						current=current+2;
					END;

				/* Special case 'Ceaser' */
				ELSE IF current=1 and substr(string_pad,current,6)='CAESAR' THEN
					do;
						DMPV1=compress(DMPV1||'S');
						DMPV2=compress(DMPV2||'S');
						current=current+2;
					end;

				/* Italian chianti */
				ELSE IF substr(string_pad,current,4)='CHIA' THEN
					DO;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');
						current=current+2;
					END;
				ELSE IF substr(string_pad,current,2)='CH' THEN
					DO;
						/* Find michael */
						IF current>1 and substr(string_pad,current,4)='CHAE' then
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'X');
								current=current+2;
							end;

						/* Greek roots e.g 'chemistry', 'chorus' */
						ELSE IF current=1 and 
							(substr(string_pad,current+1,5) in ('HARAC','HARIS') OR substr(string_pad,current+1,3) IN ('HOR','HYM','HIA','HEM'))
							and substr(string_pad,1,5)^='CHORE' then
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'K');
								current=current+2;
							end;

						/* germanic, greek, or otherwise 'ch' for 'kh' sound */
						else IF (SUBSTR(string_pad,1,4) in ('VAN ','VON ') OR SUBSTR(string_pad,1,3)='SCH') 
							OR SUBSTR(pre_pad,current+6-2,6) in ('ORCHES', 'ARCHIT', 'ORCHID') 
							OR SUBSTR(string_pad,current+2,1) in ('T','S') 
							OR (SUBSTR(pre_pad,current+6-1,1) in ('A','O','U','E') OR (current=1) AND   
							SUBSTR(string_pad,current+2,1) in ('L','R','N','M','B','H','F','V','W',' '))
							Then
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'K');
							End;
						ELSE
							do;
								IF current>1 then
									do;
										IF SUBSTR(string_pad,1,2)='MC' then
											do;
												/* e.g., McHugh */
												DMPV1=compress(DMPV1||'K');
												DMPV2=compress(DMPV2||'K');
											End;
										ELSE
											do;
												DMPV1=compress(DMPV1||'X');
												DMPV2=compress(DMPV2||'K');
											END;
									end;
								ELSE
									do;
										DMPV1=compress(DMPV1||'X');
										DMPV2=compress(DMPV2||'X');
									END;
							END;

						current=current+2;
					END;

				/* e.g, czerny */
				Else IF SUBSTR(string_pad,current,2)='CZ' AND SUBSTR(pre_pad,current+6-2,4)^='WICZ' then
					do;
						DMPV1=compress(DMPV1||'S');
						DMPV2=compress(DMPV2||'X');
						current=current+2;
					END;

				/* e.g., focaccia */
				Else IF SUBSTR(string_pad,current+1,3)='CIA' then
					do;
						DMPV1=compress(DMPV1||'X');
						DMPV2=compress(DMPV2||'X');
						current=current+3;
					END;

				/* double C, but not if e.g. McClellan */
				Else IF SUBSTR(string_pad,current,2)='CC' AND NOT (current=2 AND SUBSTR(string_pad,1,1)='M') then
					do;
						/* bellocchio but not bacchus */
						IF SUBSTR(string_pad,current+2,1) in ('I','E','H') AND 
							SUBSTR(string_pad, current+2,2)^='HU' Then
							do;
								/* accident, accede succeed */
								IF((current=2) AND (SUBSTR(pre_pad,current+6-1,1)='A')) 
									OR SUBSTR(pre_pad,current+6-1,5) in ('UCCEE','UCCES') then
									do;
										DMPV1=compress(DMPV1||'KS');
										DMPV2=compress(DMPV2||'KS');

										/* bacci, bertucci, other Italian */
									End;
								ELSE
									do;
										DMPV1=compress(DMPV1||'X');
										DMPV2=compress(DMPV2||'X');
									END;

								current=current+3;
							end;
						ELSE
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'K');
								current=current+2;
							END;
					END;
				Else IF SUBSTR(string_pad,current,2) in ('CK','CG','CQ') then
					do;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');
						current=current+2;
					END;
				Else IF SUBSTR(string_pad,current,2) in ('CI','CE','CY') then
					do;
						/* italian vs. English */
						IF SUBSTR(string_pad, current, 3) in ('CIO', 'CIE', 'CIA') then
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'X');
							End;
						ELSE
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'S');
							END;

						current=current+2;
					END;
				Else
					do;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');

						* name sent in mac caffrey, mac gregor;
						IF SUBSTR(string_pad,current+1,2) in (' C',' Q',' G') then
							do;
								current=current+3;
							end;
						ELSE
							do;
								IF SUBSTR(string_pad,current+1,1) in ('C','K','Q') 
									AND SUBSTR(string_pad, current+1, 2) not in ('CE', 'CI') THEN
									DO;
										current=current+2;
									END;
								ELSE
									DO;
										current=current+1;
									END;
							END;
					END;
			END;

		/* CASE D */
		Else If letter='D' then
			do;
				IF SUBSTR(string_pad,current,2)='DG' then
					do;
						IF SUBSTR(string_pad,current+2,1) in ('I','E','Y') then
							do;
								/* e.g. edge */
								DMPV1=compress(DMPV1||'J');
								DMPV2=compress(DMPV2||'J');
								current=current+3;
							end;
						ELSE
							do;
								/* e.g. edgar */
								DMPV1=compress(DMPV1||'TK');
								DMPV2=compress(DMPV2||'TK');
								current=current+2;
							END;
					END;
				Else IF SUBSTR(string_pad,current,2) in ('DT','DD') then
					do;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');
						current=current+2;
					END;
				Else
					do;
						DMPV1=compress(DMPV1||'T');
						DMPV2=compress(DMPV2||'T');
						current=current+1;
					end;
			end;

		/* CASE F */
		Else If letter='F' then
			do;
				IF SUBSTR(string_pad,current+1,1)='F' then
					current=current+2;
				ELSE current=current+1;
				DMPV1=compress(DMPV1||'F');
				DMPV2=compress(DMPV2||'F');
			End;

		/* CASE G */
		Else If letter='G' then
			do;
				IF SUBSTR(string_pad,current+1,1)='H' then
					do;
						IF (current>1) AND 
							SUBSTR(pre_pad,current+6-1,1) not in ('A','E','I','O','U','Y') then
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'K');
								current=current+2;
							END;
						Else IF current < 4 then
							do;
								/* ghislane, ghiradelli */
								IF current=1 then
									do;
										IF SUBSTR(string_pad,current+2,1)='I' then
											do;
												DMPV1=compress(DMPV1||'J');
												DMPV2=compress(DMPV2||'J');
											End;
										ELSE
											do;
												DMPV1=compress(DMPV1||'K');
												DMPV2=compress(DMPV2||'K');
											End;

										current=current+2;
									END;
							END;

						/* Parkers rule (with some further refinements) - e.g., hugh
																														       e.g., bough
																														       e.g., broughton */
						Else IF ((current>2) AND SUBSTR(pre_pad,current+6-2,1) in ('B','H','D')) OR 
							((current>3) AND SUBSTR(pre_pad,current+6-3,1) in ('B','H','D')) OR 
							((current>4) AND SUBSTR(pre_pad,current+6-4,1) in ('B','H')) then
							do;
								current=current+2;
							end;
						ELSE
							do;
								* e.g., laugh, McLaughlin, cough, gough, rough, tough;
								IF (current>3) AND 
									SUBSTR(pre_pad,current+6-1,1)='U' AND 
									SUBSTR(pre_pad,current+6-3,1) in ('C','G','L','R','T') then
									do;
										DMPV1=compress(DMPV1||'F');
										DMPV2=compress(DMPV2||'F');
									End;
								ELSE
									do;
										IF (current>1) AND SUBSTR(pre_pad,current+6-1,1)^='I' then
											do;
												DMPV1=compress(DMPV1||'K');
												DMPV2=compress(DMPV2||'K');
											END;
									END;

								current=current+2;
							END;
					END;
				Else IF SUBSTR(string_pad,current+1,1)='N' then
					do;
						IF (current = 2) AND substr(string_pad,1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') AND 
							SlavoGermanic=0 then
							do;
								DMPV1=compress(DMPV1||'KN');
								DMPV2=compress(DMPV2||'N');
							End;
						ELSE
							do;
								/* not e.g. cagney */
								IF SUBSTR(string_pad, current+2, 2) ^= 'EY' 
									AND (SUBSTR(string_pad,current+1,1) ^= 'Y') AND SlavoGermanic=0 then
									do;
										DMPV1=compress(DMPV1||'N');
										DMPV2=compress(DMPV2||'KN');
									End;
								ELSE
									do;
										DMPV1=compress(DMPV1||'KN');
										DMPV2=compress(DMPV2||'KN');
									END;
							END;

						current=current+2;
					END;

				/* tagliaro */
				Else IF SUBSTR(string_pad,current+1,2)='LI' AND SlavoGermanic=0 then
					do;
						DMPV1=compress(DMPV1||'KL');
						DMPV2=compress(DMPV2||'L');
						current=current+2;
					END;

				/* -ges-,-gep-,-gel-, -gie- at beginning */
				Else IF (current=1) and
					(SUBSTR(string_pad,current+1,1)='Y' OR 
					SUBSTR(string_pad,current+1,2) IN ('ES','EP','EB','EL','EY','IB','IL','IN','IE','EI','ER'))
					Then
					do;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'J');
						current=current+2;
					END;

				/* -ger-, -gy- */
				Else IF (SUBSTR(string_pad,current+1,2)='ER' OR SUBSTR(string_pad,current+1,1)='Y')
					AND SUBSTR(string_pad,1,6) not in ('DANGER','RANGER','MANGER') 
					AND SUBSTR(pre_pad,current+6-1,1) not in ('E','I') 
					AND SUBSTR(pre_pad,current+6-1,3) not in ('RGY','OGY') then
					do;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'J');
						current=current+2;
					END;

				/* italian e.g, biaggi */
				Else IF SUBSTR(string_pad,current+1,1) in ('E', 'I', 'Y') OR 
					SUBSTR(pre_pad,current+6-1,4) in ('AGGI','OGGI') then
					do;
						/* obvious Germanic */
						IF SUBSTR(string_pad,1,4) in ('VAN ', 'VON ') OR SUBSTR(string_pad,1,3)='SCH' OR 
							SUBSTR(string_pad,current+1,2)='ET' then
							do;
								DMPV1=compress(DMPV1||'K');
								DMPV2=compress(DMPV2||'K');
							End;
						ELSE
							do;
								/* always soft if french ending */
								IF SUBSTR(string_pad,current+1,4)='IER ' then
									do;
										DMPV1=compress(DMPV1||'J');
										DMPV2=compress(DMPV2||'J');
									End;
								ELSE
									do;
										DMPV1=compress(DMPV1||'J');
										DMPV2=compress(DMPV2||'K');
									END;
							END;

						current=current+2;
					END;
				Else IF SUBSTR(string_pad,current+1,1)='G' then
					do;
						current=current+2;
					end;
				ELSE
					do;
						current=current+1;
						DMPV1=compress(DMPV1||'K');
						DMPV2=compress(DMPV2||'K');
					End;
			End;

		/* CASE H */
		Else If letter='H' then
			do;
				/* only keep if first & before vowel or btw. 2 vowels */
				IF (current=1 OR 
					SUBSTR(pre_pad,current+6-1,1) in ('A', 'E', 'I', 'O', 'U', 'Y')) AND 
					substr(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') then
					do;
						DMPV1=compress(DMPV1||'H');
						DMPV2=compress(DMPV2||'H');
						current=current+2;
					end;
				ELSE
					do;
						current=current+1;
					END;
			End;

		/* CASE J*/
		Else If letter='J' then
			do;
				/* obvious spanish, jose, san jacinto */
				IF SUBSTR(string_pad,current,4)='JOSE' OR SUBSTR(string_pad,1,4)='SAN ' then
					do;
						IF ((current=1) AND (SUBSTR(string_pad,current+4,1)=' ')) OR 
							SUBSTR(string_pad,1,4)='SAN ' Then
							do;
								DMPV1=compress(DMPV1||'H');
								DMPV2=compress(DMPV2||'H');
							End;
						ELSE
							do;
								DMPV1=compress(DMPV1||'J');
								DMPV2=compress(DMPV2||'H');
							END;

						current=current+1;
					END;
				Else IF (current=1) AND SUBSTR(string_pad,current,4)^='JOSE' then
					do;
						DMPV1=compress(DMPV1||'J');
						DMPV2=compress(DMPV2||'A');
					End;
				ELSE
					do;
						/* spanish pron. of e.g. bajador */
						IF SUBSTR(pre_pad,current+6-1,1) IN ('A','E','I','O','U','Y') AND 
							SlavoGermanic=0 AND 
							((SUBSTR(string_pad,current+1,1)='A') OR (SUBSTR(string_pad,current+1,1)='O')) then
							do;
								DMPV1=compress(DMPV1||'J');
								DMPV2=compress(DMPV2||'H');
							End;
						ELSE
							do;
								IF current=s_length then
									do;
										DMPV1=compress(DMPV1||'J');
										DMPV2=compress(DMPV2||'J');
									End;
								ELSE
									do;
										IF SUBSTR(string_pad,current+1,1) not in ('L','T','K','S','N','M','B','Z')           
											AND SUBSTR(pre_pad,current+6-1,1) not in ('S','K','L') then
											do;
												DMPV1=compress(DMPV1||'J');
												DMPV2=compress(DMPV2||'J');
											END;
									END;
							END;
					END;

				IF SUBSTR(string_pad,current+1,1)='J' then
					do;
						current=current+2;
					end;
				ELSE
					do;
						current=current+1;
					END;
			End;

		/* CASE K */
		Else If letter='K' then
			do;
				IF SUBSTR(string_pad,current+1,1)='K' then
					current=current+2;
				ELSE current=current+1;
				DMPV1=compress(DMPV1||'K');
				DMPV2=compress(DMPV2||'K');
			End;

		/* CASE L */
		Else If letter='L' then
			do;
				IF SUBSTR(string_pad,current+1,1)='L' then
					do;
						/* spanish e.g. cabrillo, gallegos */
						IF (current=(s_length-2) AND 
							SUBSTR(pre_pad,current+6-1,4) in ('ILLO','ILLA','ALLE')) 
							OR 
							(current>1 AND (SUBSTR(string_pad,s_length-1, 2) in ('AS', 'OS') OR 
							SUBSTR(string_pad,s_length,1) in ('A','O')) AND 
							SUBSTR(pre_pad,current+6-1,4)='ALLE') Then
							do;
								DMPV1=compress(DMPV1||'L');
								DMPV2=compress(DMPV2||'L');
								current=current+2;
							end;
						else
							do;
								current=current+2;
							end;
					end;
				ELSE
					do;
						DMPV1=compress(DMPV1||'L');
						DMPV2=compress(DMPV2||'L');
						current=current+1;
					end;
			end;

		/* CASE M */
		Else If letter='M' then
			do;
				* dumb,thumb;
				IF SUBSTR(pre_pad,current+6-1,3)='UMB' AND 
					(current+1=s_length OR SUBSTR(string_pad,current+2,2)='ER') 
					OR SUBSTR(string_pad,current+1,1)='M' then
					current=current+2;
				ELSE current=current+1;
				DMPV1=compress(DMPV1||'M');
				DMPV2=compress(DMPV2||'M');
			end;

		/* CASE N */
		Else If letter='N' then
			do;
				IF SUBSTR(string_pad,current+1,1)='N' then
					current=current+2;
				ELSE current=current+1;
				DMPV1=compress(DMPV1||'N');
				DMPV2=compress(DMPV2||'N');
			end;
		Else If letter='Ñ' then
			do;
				current=current+1;
				DMPV1=compress(DMPV1||'N');
				DMPV2=compress(DMPV2||'N');
			end;

		/* CASE P */
		Else If letter='P' then
			do;
				IF SUBSTR(string_pad,current+1,1)='H' then
					do;
						DMPV1=compress(DMPV1||'F');
						DMPV2=compress(DMPV2||'F');
						current=current+2;
					END;

				/* also account for campbell, raspberry */
				Else
					do;
						IF SUBSTR(string_pad, current+1, 1) in ('P', 'B') then
							current=current+2;
						ELSE current=current+1;
						DMPV1=compress(DMPV1||'P');
						DMPV2=compress(DMPV2||'P');
					END;
			End;

		/* CASE Q */
		Else If letter='Q' then
			do;
				IF SUBSTR(string_pad,current+1,1)='Q' then
					current=current+2;
				ELSE current=current+1;
				DMPV1=compress(DMPV1||'K');
				DMPV2=compress(DMPV2||'K');
			end;

		/* CASE R */
		Else If letter='R' then
			do;
				/* french e.g. rogier, but exclude hochmeier */
				IF (current=s_length) AND SlavoGermanic=0 
					AND SUBSTR(pre_pad,current+6-2,2)='IE' 
					AND SUBSTR(pre_pad,current+6-4,2) not in ('ME', 'MA') then
					do;
						DMPV2=compress(DMPV2||'R');
					End;
				ELSE
					do;
						DMPV1=compress(DMPV1||'R');
						DMPV2=compress(DMPV2||'R');
					END;

				IF SUBSTR(string_pad,current+1,1)='R' then
					current=current+2;
				ELSE current=current+1;
			End;

		/* CASE S */
		Else If letter='S' then
			do;
				/* special cases island, isle, carlisle, carlysle */
				IF SUBSTR(pre_pad,current+6-1,3) in ('ISL','YSL') then
					do;
						current=current+1;
					END;

				/* special case sugar */;
				IF (current=1) AND SUBSTR(string_pad,current,5)='SUGAR' then
					do;
						DMPV1=compress(DMPV1||'X');
						DMPV2=compress(DMPV2||'S');
						current=current+1;
					END;
				Else IF SUBSTR(string_pad,current,2)='SH' then
					do;
						/* Germanic */
						IF SUBSTR(string_pad, current+1, 4) in ('HEIM', 'HOEK', 'HOLM', 'HOLZ') then
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'S');
							End;
						ELSE
							do;
								DMPV1=compress(DMPV1||'X');
								DMPV2=compress(DMPV2||'X');
							END;

						current=current+2;
					END;

				/* italian & Armenian */
				Else IF SUBSTR(string_pad,current,3) in ('SIO','SIA') OR SUBSTR(string_pad,current,4)='SIAN' Then
					do;
						IF SlavoGermanic=0 then
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'X');
							End;
						ELSE
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'S');
							END;

						current=current+3;
					END;

				/* german & anglicisations, e.g. smith match schmidt, snider match schneider;
						   also, -sz- in slavic language altho in hungarian it is pronounced s; */
				Else IF current=1 AND 
					(SUBSTR(string_pad,current+1,1) in ('M','N','L','W') 
					OR SUBSTR(string_pad,current+1,1)='Z') then
					do;
						DMPV1=compress(DMPV1||'S');
						DMPV2=compress(DMPV2||'X');

						IF SUBSTR(string_pad,current+1,1)='Z' then
							current=current+2;
						ELSE current=current+1;
					END;
				Else IF SUBSTR(string_pad,current,2)='SC' then
					do;
						/* Schlesingers rule */
						IF SUBSTR(string_pad,current+2,1)='H' then
							do;
								/* dutch origin, e.g. school, schooner */
								IF SUBSTR(string_pad,current+3,2) in ('OO','ER','EN','UY','ED','EM') then
									do;
										/* schermerhorn, schenker */
										IF SUBSTR(string_pad, current+3,2) in ('ER','EN') then
											do;
												DMPV1=compress(DMPV1||'X');
												DMPV2=compress(DMPV2||'SK');
											End;
										ELSE
											do;
												DMPV1=compress(DMPV1||'SK');
												DMPV2=compress(DMPV2||'SK');
											End;

										current=current+3;
									end;
								ELSE
									do;
										IF (current=1) AND SUBSTR(string_pad,3,1) not in ('A','E','I','O','U','Y') AND 
											SUBSTR(string_pad,3,1)^='W' then
											do;
												DMPV1=compress(DMPV1||'X');
												DMPV2=compress(DMPV2||'S');
											End;
										ELSE
											do;
												DMPV1=compress(DMPV1||'X');
												DMPV2=compress(DMPV2||'X');
											END;

										current=current+3;
									END;
							END;
						Else IF SUBSTR(string_pad,current+2,1) in ('I', 'E', 'Y') then
							do;
								DMPV1=compress(DMPV1||'S');
								DMPV2=compress(DMPV2||'S');
								current=current+3;
							END;
						Else
							do;
								DMPV1=compress(DMPV1||'SK');
								DMPV2=compress(DMPV2||'SK');
								current=current+3;
							end;
					END;

				/* french e.g. resnais, artois */
				Else IF (current=s_length) and SUBSTR(pre_pad,current+6-2,2) in ('AI','OI') then
					do;
						DMPV2=compress(DMPV2||'S');
						current=current+1;
					end;
				ELSE
					do;
						DMPV1=compress(DMPV1||'S');
						DMPV2=compress(DMPV2||'S');

						IF SUBSTR(string_pad,current+1,1) in ('S','Z') then
							current=current+2;
						ELSE current=current+1;
					End;
			End;

		/* CASE T */
		Else If letter='T' then
			do;
				IF SUBSTR(string_pad,current,4)='TION' then
					do;
						DMPV1=compress(DMPV1||'X');
						DMPV2=compress(DMPV2||'X');
						current=current+3;
					END;
				Else IF SUBSTR(string_pad,current,3) in ('TIA','TCH') then
					do;
						DMPV1=compress(DMPV1||'X');
						DMPV2=compress(DMPV2||'X');
						current=current+3;
					END;
				Else IF SUBSTR(string_pad,current,2)='TH' OR SUBSTR(string_pad,current,3)='TTH' then
					do;
						/* special case thomas, thames or Germanic */
						IF SUBSTR(string_pad,current+2,2) in ('OM','AM') OR 
							SUBSTR(string_pad,1,4) in ('VAN ','VON ') OR 
							SUBSTR(string_pad,1,3)='SCH' then
							do;
								DMPV1=compress(DMPV1||'T');
								DMPV2=compress(DMPV2||'T');
							End;
						ELSE
							do;
								DMPV1=compress(DMPV1||'0');
								DMPV2=compress(DMPV2||'T');
							END;

						current=current+2;
					END;
				Else
					do;
						IF SUBSTR(string_pad,current+1,1) in ('T','D') then
							current=current+2;
						ELSE current=current+1;
						DMPV1=compress(DMPV1||'T');
						DMPV2=compress(DMPV2||'T');
					END;
			End;

		/* CASE V */
			Else If letter='V' then do;
    IF SUBSTR(string_pad,current+1,1)='V' then current=current+2;
    ELSE current=current+1;
    DMPV1=compress(DMPV1||'F');
		DMPV2=compress(DMPV2||'F');
  End;

  /* CASE W */
Else If letter='W' then do;
    /* can also be in middle of word */
    IF SUBSTR(string_pad,current,2)='WR' then do;
      DMPV1=compress(DMPV1||'R');
		DMPV2=compress(DMPV2||'R');
      current=current+2;
    END;

    Else IF (current=1) AND 
       (SUBSTR(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') OR 
       SUBSTR(string_pad, current, 2)='WH') then do;

       /* Wasserman should match Vasserman */
        IF SUBSTR(string_pad,current+1,1) in ('A', 'E', 'I', 'O', 'U', 'Y') then do;
          DMPV1=compress(DMPV1||'A');
		DMPV2=compress(DMPV2||'F');
        End;
        ELSE do;
        /* need Uomo to match Womo */
          DMPV1=compress(DMPV1||'A');
		DMPV2=compress(DMPV2||'A');
        End;
        current=current+1;
    END;
    /* Arnow should match Arnoff */
    Else IF (current=s_length AND
             SUBSTR(pre_pad,current+6-1,1) in ('A', 'E', 'I', 'O', 'U', 'Y')) OR
            SUBSTR(pre_pad,current+6-1,5) in ('EWSKI','EWSKY','OWSKI','OWSKY') OR
            SUBSTR(string_pad,1,3)='SCH' then do;
		DMPV2=compress(DMPV2||'F');
      current=current+1;
    END;
    /* polish e.g. filipowicz */
    Else IF SUBSTR(string_pad,current,4)in ('WICZ', 'WITZ') then do;
      DMPV1=compress(DMPV1||'TS');
		DMPV2=compress(DMPV2||'FX');
      current=current+4;
    END;
    Else do;
    /* else skip it */
    current=current+1;
    end;
  end;
/* CASE X */
 else If letter='X' then do;
    * french e.g. breaux;
    IF (current^=s_length and 
      SUBSTR(pre_pad,current+6-3,3) not in ('IAU', 'EAU') AND
      SUBSTR(pre_pad,current+6-2,2) not in ('AU', 'OU')) then do;
      DMPV1=compress(DMPV1||'KS');
		DMPV2=compress(DMPV2||'KS');
    END;
    IF SUBSTR(string_pad, current+1, 1) in ('C', 'X') then current=current+2;
    ELSE current=current+1;
  End;
/* CASE Z */
 Else If letter='Z' then do;
    * chinese pinyin e.g. zhao;
    IF SUBSTR(string_pad,current+1,1)='H' then do;
      DMPV1=compress(DMPV1||'J');
		DMPV2=compress(DMPV2||'J');
      current=current+2;
    end;
    ELSE do;
     IF SUBSTR(string_pad,current+1,2) in ('ZO','ZI','ZA') OR 
       (SlavoGermanic=1 AND current>1 AND SUBSTR(pre_pad,current+6-1,1) ne 'T') 
        then do;
        DMPV1=compress(DMPV1||'S');
		DMPV2=compress(DMPV2||'TS');
     end;
     ELSE do;
        DMPV1=compress(DMPV1||'S');
		DMPV2=compress(DMPV2||'S');
     end;
      IF SUBSTR(string_pad,current+1,1)='Z' then current=current+2;
      ELSE current=current+1;
	END;
  END;
/* OTHERWISE DEFAULT RESPONSE */
  ELSE CURRENT=current+1;
	END;

	/* end of main loop */
	IF length(trim(DMPV1))>4 THEN
		DMPV1=substr(DMPV1,1,4);

	IF length(trim(DMPV2))>4 THEN
		DMPV2=substr(DMPV2,1,4);

		if dmetaoption=1 then
			return(DMPV1);
		else if dmetaoption=2 then
			return(DMPV2);
		else return(trim(DMPV1)||','||trim(DMPV2));
	endsub;

/* EUCLIDEAN DISTANCE */

FUNCTION EUCLIDEAN2(a1,b1,a2,b2);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) then return(.);
distance=SQRT((a1-a2)**2+(b1-b2)**2);
return(distance);
endsub;
FUNCTION EUCLIDEAN3(a1,b1,c1,a2,b2,c2);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) then return(.);
distance=SQRT((a1-a2)**2+(b1-b2)**2+(c1-c2)**2);
return(distance);
endsub;

/* Fuzznum functions */

FUNCTION lowfuzz(num_1,num_2,diff);

	IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
	else IF num_1-num_2<=diff AND num_1-num_2>=0 THEN RETURN(1);
	ELSE RETURN(0);

endsub;

FUNCTION highfuzz(num_1,num_2,diff);

	IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
	else IF num_1-num_2>=-(diff) AND num_1-num_2<=0 THEN RETURN(1);
	ELSE RETURN(0);

endsub;

FUNCTION genfuzz(num_1,num_2,diff);

	IF missing(num_1) OR missing(num_2) or missing(diff) then return(.);
	else IF ABS(num_1-num_2)<=diff THEN RETURN(1);
	ELSE RETURN(0);

endsub;

FUNCTION HAMMING(string1 $,string2 $);
if missing(string1) or missing(string2) THEN return(.);
else if string1=string2 THEN return (0);
stringlen1=length(string1);
stringlen2=length(string2);
if stringlen1^=stringlen2 then return (.);
j=0;
do i=1 to stringlen1 by 1;
if substr(string1,i,1)^=substr(string2,i,1) then j=j+1;
end;
return(j);
endsub;

/* Minkowski distance functions */

FUNCTION MINKOWSKI2(a1,b1,a2,b2,p);
if missing(a1) or missing(b1) or missing(a2) or missing(b2) or missing(p) then return(.);
distance=((ABS(a1-a2))**p+(ABS(b1-b2))**p)**(1/p);
return(distance);
endsub;

FUNCTION MINKOWSKI3(a1,b1,c1,a2,b2,c2,p);
if missing(a1) or missing(b1) or missing(c1) or missing(a2) or missing(b2) or missing(c2) or missing(p) then return(.);
distance=((ABS(a1-a2))**p+(ABS(b1-b2))**p+(ABS(c1-c2))**p)**(1/p);
return(distance);
endsub;

/* NYSIIS FUNCTION */

FUNCTION NYSIIS(string_1 $) $ 6;

/* Step 1: Convert string to Uppercase letters, and remove whitespace */
length lengthvar 8 NYSIIS $6 firstchar $1;
workstring = UPCASE(TRIM(LEFT(string_1)));

/* Remove non-alpha characters */

workstring = PRXCHANGE('s/[^A-Z]//o',-1,workstring);

/* Beginning the "real algorithm" */
/* 
	Transcode first characters of name:
	MAC -> MCC
	KN -> NN
	K -> C
	PH, PF -> FF
	SCH -> SSS
*/

IF PRXMATCH('/^MAC/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^MAC/MCC/o',-1,workstring);
ELSE 
IF PRXMATCH('/^KN/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^KN/NN/o',-1,workstring);
ELSE 
IF PRXMATCH('/^K/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^K/C/o',-1,workstring);
ELSE
IF PRXMATCH('/^PH/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^PH|^PF/FF/o',-1,workstring);
ELSE
IF PRXMATCH('/^SCH/o',workstring)>0 THEN
workstring=	PRXCHANGE('s/^SCH/SSS/o',-1,workstring);

/* Transcode two-character suffix as follows,
EE, IE -> Y
DT, RT, RD, NT, ND -> D
*/
	IF PRXMATCH('/EE$|IE$/o',trim(workstring)) THEN
		workstring = PRXCHANGE('s/EE$|IE$/Y/o',-1,trim(workstring));
	else IF PRXMATCH('/DT$|RT$|RD$|NT$|ND$/o',trim(workstring)) THEN
		workstring = PRXCHANGE('s/DT$|RT$|RD$|NT$|ND$/D/o',-1,trim(workstring));
	

/* Save first char for later, to be used as first char of key */

	firstChar = substr(workstring,1,1);
IF length(workstring)=1 THEN workstring='';
ELSE workstring=substr(workstring,2);


/* Translate remaining characters by following these rules sequentially.  Some other comments
have been along the lines of "incrementing one character at a time", but this description is
ambiguous at best, and misleading at worst.  

The code from the original via which I have translated this version implimented the code below:
		EV	->	AF 	else A,E,I,O,U	->	A 	*/                                 
	
	workstring = PRXCHANGE('s/EV/AF/o',-1,workstring);
	workstring = PRXCHANGE('s/[AEIOU]+/A/o',-1,workstring);
	/*	Q	->	G */	  	  	  	  	 
	workstring = PRXCHANGE('s/Q/G/o',-1,workstring);
	/*	Z	->	S */	  	  	  	  	 
	workstring = PRXCHANGE('s/Z/S/o',-1,workstring);
	/*	M	->	N */	  	  	  	  	 
	workstring = PRXCHANGE('s/M/N/o',-1,workstring);
	/*	KN	->	N, else K	->	C */ 	 
	workstring = PRXCHANGE('s/KN/N/o',-1,workstring);
	workstring = PRXCHANGE('s/K/C/o',-1,workstring);
	/*	SCH	->	SSS */ 	  	  	  	  	 
	workstring = PRXCHANGE('s/SCH/SSS/o',-1,workstring);
	/*	PH	->	FF 	*/  	  	  	  	 
	workstring = PRXCHANGE('s/PH/FF/o',-1,workstring);
	/* H -> If previous or next is nonvowel, previous */
	workstring = PRXCHANGE('s/([^AEIOU])H/$1/o',-1,workstring);
	workstring = PRXCHANGE('s/(.)H[^AEIOU]/$1/o',-1,workstring);
	/* W ->	If previous is vowel, then A */
	workstring = PRXCHANGE('s/[AEIOU]W/A/o',-1,workstring);
	
	/* If last character is S, remove it */
	workstring = PRXCHANGE('s/S$//o',-1,trim(workstring));

	/* If last characters are AY, replace with Y */
	workstring = PRXCHANGE('s/AY$/Y/o',-1,trim(workstring));


	/* If last character is A, remove it */
	workstring = PRXCHANGE('s/A$//o',-1,trim(workstring));

	/* Collapse all strings of repeated characters
	 Except for vowels which become A.  The comments say vowels, but the earlier code
	 changed all the vowels to A.  You could make things more efficient here by
	 dropping checks for the other vowel characters, and you could also do this
	 by dropping the same checks for the vowel characters up above in the code as well.

	 But I'm just going to keep things as they are, as it will work fine as it is,
	 it will be more comparable with code from the past, and efficiency is not the 
	 main concern with this algorithm. */

	workstring = PRXCHANGE('s/[AEIOU]+/A/o',-1,workstring);
	workstring = PRXCHANGE('s/B+/B/o',-1,workstring);
	workstring = PRXCHANGE('s/C+/C/o',-1,workstring);
	workstring = PRXCHANGE('s/D+/D/o',-1,workstring);
	workstring = PRXCHANGE('s/F+/F/o',-1,workstring);
	workstring = PRXCHANGE('s/G+/G/o',-1,workstring);
	workstring = PRXCHANGE('s/H+/H/o',-1,workstring);
	workstring = PRXCHANGE('s/J+/J/o',-1,workstring);
	workstring = PRXCHANGE('s/K+/K/o',-1,workstring);
	workstring = PRXCHANGE('s/L+/L/o',-1,workstring);
	workstring = PRXCHANGE('s/M+/M/o',-1,workstring);
	workstring = PRXCHANGE('s/N+/N/o',-1,workstring);
	workstring = PRXCHANGE('s/P+/P/o',-1,workstring);
	workstring = PRXCHANGE('s/Q+/Q/o',-1,workstring);
	workstring = PRXCHANGE('s/R+/R/o',-1,workstring);
	workstring = PRXCHANGE('s/S+/S/o',-1,workstring);
	workstring = PRXCHANGE('s/T+/T/o',-1,workstring);
	workstring = PRXCHANGE('s/V+/V/o',-1,workstring);
	workstring = PRXCHANGE('s/W+/W/o',-1,workstring);
	workstring = PRXCHANGE('s/X+/X/o',-1,workstring);
	workstring = PRXCHANGE('s/Y+/Y/o',-1,workstring);
	workstring = PRXCHANGE('s/Z+/Z/o',-1,workstring);

	/* Use original first char of surname as first char of key */
	lengthvar=length(workstring);
	IF lengthvar>=5 then NYSIIS = firstChar||substr(workstring,1,5);
	ELSE NYSIIS=firstchar||trim(workstring);

return(NYSIIS);
endsub;

FUNCTION EXPECTUNIQUE(odds,numofpersons);

		if missing(odds) or missing(numofpersons) then
			return(.);
		expectedunique=numofpersons*(1-1/odds)**(numofpersons-1);
		return(expectedunique);
	endsub;

quit;

%mend icarus_allfunctions;

%icarus_allfunctions;