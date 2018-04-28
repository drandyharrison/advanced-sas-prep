/* Advanced programming for SAS 9 */
/* Chapter 10: Processing macro variables at execution time */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";

/* limitations of creating a macro variable at execution time, with %LET */
OPTIONS SYMBOLGEN PAGESIZE=30;
%LET crsnum = 3;
DATA revenue;
	SET sasuser.all END=final;
	WHERE course_number = &crsnum;
	total + 1;
	IF paid = 'Y' THEN paidup + 1;
	IF final then DO;
		PUT total= paidup=;			/* write information to the log */
		IF paidup < total THEN DO;
			%LET foot = Some fees are unpaid;
		END;
		ELSE DO;
			%LET foot = All students have paid their fees;
		END;
	END;
RUN;

PROC PRINT DATA=revenue;
	VAR student_name student_company paid;
	title "Payment status for course &crsnum";
	title2 "(macro variable not created as intended)";
	footnote "&foot";
	/* when a title[n] or foot[n] statement is defined, all higher titles/footnotes are 'deleted' */
	footnote2 &foot2_arg &foot2_val;
RUN;


/* corrected version wich creates a macro variable at execution time, with CALL SYMPUT */
%LET crsnum = 3;
DATA revenue;
	SET sasuser.all END=final;
	WHERE course_number = &crsnum;
	total + 1;
	IF paid = 'Y' THEN paidup + 1;
	IF final then DO;
		PUT total= paidup=;			/* write information to the log */
		IF paidup < total THEN DO;
			CALL SYMPUT('foot', 'Some fees are unpaid');
		END;
		ELSE DO;
			CALL SYMPUT('foot', 'All students have paid their fees');
		END;
	END;
RUN;

PROC PRINT DATA=revenue;
	VAR student_name student_company paid;
	title "Payment status for course &crsnum";
	title2 "(macro variable created at execution time)";
	footnote "&foot";
	footnote2 &foot2_arg &foot2_val;
RUN;

/* assigning the value of a DATA step variable to a macro variable */
DATA revenue;
	SET sasuser.all END=final;
	WHERE course_number = &crsnum;
	total + 1;
	IF paid = 'Y' THEN paidup + 1;
	IF final then DO;
		CALL SYMPUT('numpaid', paidup);
		CALL SYMPUT('numstu', total);
		CALL SYMPUT('crsname', course_title);
	END;
RUN;

PROC PRINT DATA=revenue;
	VAR student_name student_company paid;
	title "Payment status for course &crsname (#&crsnum)";
	title2 "(assigning the value of a DATA variable to a macro variable with SYMPUT)";
	footnote "Note: &numpaid paid out of &numstu students";
	footnote2 &foot2_arg &foot2_val;
	
RUN;

/* example of the use of SYMPUTX */
DATA revenue;
	SET sasuser.all END=final;
	WHERE course_number = &crsnum;
	total + 1;
	IF paid = 'Y' THEN paidup + 1;
	IF final then DO;
		CALL SYMPUTX('crsname', course_title);
		CALL SYMPUTX('date', PUT(begin_date, mmddyy10.));
		CALL SYMPUTX('due', PUT(fee * (total - paidup), DOLLAR8.));
	END;
RUN;

PROC PRINT DATA=revenue;
	VAR student_name student_company paid;
	title "Fee status for course &crsname (#&crsnum) held &date";
	title2 "(using SYMPUTX)";
	footnote "Note: &due in unpaid fees";
	footnote2 &foot2_arg &foot2_val;
RUN;

/* using SYMPUT with a DATA step expression, */
/* to remove leading and trailing blanks from the title and footnote of the earlier example */
DATA revenue;
	SET sasuser.all END=final;
	WHERE course_number = &crsnum;
	total + 1;
	IF paid = 'Y' THEN paidup + 1;
	IF final then DO;
		CALL SYMPUT('numpaid', TRIM(LEFT(paidup)));	/* since numeric expressions are automatically converted */
		CALL SYMPUT('numstu', TRIM(LEFT(total)));	/* to character using BEST12. format and any leading or  */
		CALL SYMPUT('crsname', TRIM(course_title));	/* trailing blanks are stored in the macro variable */
	END;
RUN;

PROC PRINT DATA=revenue NOOBS;
	VAR student_name student_company paid;
	title "Payment status for course &crsname (#&crsnum)";
	title2 "(using a DATA step expression with SYMPUT)";
	footnote "Note: &numpaid paid out of &numstu students";
	footnote2 &foot2_arg &foot2_val;
RUN;

/* creating multiple macro variables with CALL SYMPUT */
DATA _NULL_;
	SET sasuser.courses;
	CALL SYMPUT(course_code, TRIM(course_title));	/* generate a macro variable for each course */
RUN;

%PUT _USER_;										/* list the macro variables in the log */

footnote "Without indirect reference";
footnote2 &foot2_arg &foot2_val;
/* use the macro variables to generate separate reports for two of the courses */
%LET crsid=C005;
PROC PRINT DATA=sasuser.schedule NOOBS LABEL;
	WHERE course_code = "&crsid";
	VAR location begin_date teacher;
	title "Schedule for &c005";
RUN;

%LET crsid=C002;
PROC PRINT DATA=sasuser.schedule NOOBS LABEL;
	WHERE course_code = "&crsid";
	VAR location begin_date teacher;
	title "Schedule for &c002";
RUN;
/* This is an improvement on hard-coding the course code and name for each separate call, */
/* but there's still room for improvement */

/* an improved implementation using indirect references */
/* use the macro variables to generate separate reports for two of the courses */
footnote "With indirect reference";
footnote2 &foot2_arg &foot2_val;
%LET crsid=C005;
PROC PRINT DATA=sasuser.schedule NOOBS LABEL;
	WHERE course_code = "&crsid";
	VAR location begin_date teacher;
	title "Schedule for &&&crsid";
RUN;

%LET crsid=C002;
PROC PRINT DATA=sasuser.schedule NOOBS LABEL;
	WHERE course_code = "&crsid";
	VAR location begin_date teacher;
	title "Schedule for &&&crsid";
RUN;
/* the two PROC PRINT statments are identical, it's only the %LET statements that vary */
/* so there's still further improvement possible */

/* creating a series of macro variables by concatnating the course number */
DATA _NULL_;
	SET sasuser.schedule;
	CALL SYMPUT('teach'||LEFT(course_number),	/* concatenate course number, without leading spaces onto macro variable name */
				TRIM(teacher));					/* assign the teacher name to the macro variable */
RUN;

/* Create a report for one of the courses, which references one of the courses */
%LET crs = 3;
PROC PRINT DATA = sasuser.register NOOBS;
	WHERE course_number = &crs;
	VAR student_name paid;
	title "Roster for course #&crs";
	title2 "taught by &&teach&crs";
	footnote;
	footnote2 &foot2_arg &foot2_val;
RUN;

/* using SYMGET to obtain the value of a different macro variable for each iteration of a DATA step */
DATA teachers;
	SET sasuser.register;
	LENGTH teacher $ 20;
	/* assign the value of the macro variable teach[n] - where n = course_number - to teacher, for each observation */
	teacher = SYMGET('teach' || LEFT(course_number));
RUN;

PROC PRINT DATA=teachers (OBS=20);
	VAR student_name course_number teacher;
	title "teacher for each registered student";