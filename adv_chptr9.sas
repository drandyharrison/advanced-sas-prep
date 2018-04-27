/* Advanced programming for SAS 9 */
/* Chapter 9: Introducing macro variables */

/* define footnote for all plots using automatic macro variables */
footnote "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";

/* assign text that contains an apostrophe to a macro variable */
options symbolgen;
/* Need to further mask the apostrophe with a prefix % */
%LET text = %STR(Joan%'s report);
PROC PRINT DATA=sasuser.courses;
	WHERE DAYS > 3;
title "&text";
RUN;

/* use of %nrstr */
%LET period = May&June;
%PUT Period resolves to: &period;
%LET period = %NRSTR(May&June);
%PUT Period resolves to: &period;

/* use of %BQUOTE demonstrating that there is no need to mask the apostrophe */
%LET text = %BQUOTE(Joan's 2nd report);
PROC PRINT DATA=sasuser.courses;
	WHERE DAYS > 3;
title "&text";
RUN;

/* example of %UPCASE */
%LET paidval = n;
PROC MEANS DATA=sasuser.all sum maxdec=0;
	WHERE paid = "%UPCASE(&paidval)";
	VAR fee;
	CLASS course_title;
title "Uncollected fees for each course";
RUN;

/* example of %QUPCASE */
%LET a = begin;
%LET b = &a;
%PUT UPCASE produces:: %UPCASE(&b);
%PUT QUPCASE produces:: %QUPCASE(&b);	/* Doesn't seem to make any difference */

/* example of %SUBSTR */
%LET date = 30JAN2002;
PROC PRINT DATA = sasuser.schedule;
		WHERE	begin_date between "01%SUBSTR(&date,3)"d AND
				"&date"d;
title "All courses held so far this month";
title2 "(as of &date)";
RUN;

/* example of %INDEX */
%LET a = A very long value;
%LET b = %INDEX(&a,v);
%PUT v occurs at position &b.;

/* example of %SCAN */
DATA work.thisyear;
	SET sasuser.schedule;
	WHERE YEAR(begin_date)=YEAR("&SYSDATE9"d);
RUN;

%LET libref = %SCAN(&SYSLAST, 1, .);
%LET dsname = %SCAN(&SYSLAST, 2, .);
PROC DATASETS lib = &libref nolist;
	title "Contents of the data set &syslast";
	CONTENTS DATA = &dsname;
RUN;
QUIT;

/* examples of nested %SYSFUNC and %QSYSFUNC */
title "Report produced on %SYSFUNC(LEFT(%QSYSFUNC(TODAY(), WORDDATE.)))";