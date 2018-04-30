/* Advanced programming for SAS 9 */
/* Chapter 12: Storing macro programs */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

/* base directory for data */
%LET datadir=/folders/myfolders/sasuser.v94/advanced-sas-prep/;

/* include the macro prtlast */
%INCLUDE "&datadir.m_prtlast.sas" /SOURCE2;

%prtlast

PROC SORT DATA=sasuser.courses OUT=ByDays;
	BY Days;
RUN;

%prtlast

/* example of a stored compiled macro */
*LIBNAME macrolib "&datadir.storedlib";
OPTIONS MSTORED SASMSTORE=macrolib;

/* take a text string, divide it into words and create a macro variable to store each word */
/* text  - text string to be parsed */
/* root  - root of the name for the macro variables to store words */
/* delim - delimiter that separates words - default is a space */
%MACRO words(text,root=w,delim=%STR( )) /STORE SOURCE;
	%LOCAL i word;
	%LET i=1;
	%LET word=%SCAN(&text, &i, &delim);		/* get the i-th word (i=1) */
	%DO %WHILE (&word NE );					/* process the next work until none left */
		%GLOBAL &root&i;					/* create a global macro variable to hold i-th word */
		%LET &root&i=&word;					/* assign i-th word to the global macro variable */
		%LET i=%EVAL(&i + 1);				/* increment i by 1 */
		%LET word=%SCAN(&text, &i, &delim);	/* get next word */
	%END;
	%GLOBAL &root.num;
	%LET &root.num=%EVAL(&i-1);				/* the number of words read (default wnum) */
%MEND words;

/* confirm compile macro created by listing the contents of macrolib.sasmacr */
PROC CATALOG CAT=macrolib.sasmacr;
	CONTENTS;
	title "Stored compiled macros";
QUIT;

/* accessing the words macro */
%words(This is a test)
%PUT &wnum words read;
%PUT Word 1 (w1): &w1;
%PUT Word 1 (w2): &w2;
%PUT Word 1 (w3): &w3;
%PUT Word 1 (w4): &w4;

/* copy source of words to SAS log */
%COPY words /SOURCE;