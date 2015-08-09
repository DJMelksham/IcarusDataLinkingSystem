options cmplib=work.icarusfunctions;

proc proto package=work.icarusfunctions.strings;
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

proc fcmp outlib=work.icarusfunctions.strings;
	/* FCMP wrapper for Jaro string comparator */
function jaro(s1 $, s2 $);
val = jaro(strip(s1),strip(s2));
       return (val);
   endsub;
   	
   /* FCMP wrapper for Winkler string comparator */
function winkler(s1 $, s2 $, number);
	val = cwinkler(strip(s1), strip(s2), number);
       return (val);
   endsub;

   quit; 