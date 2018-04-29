/* Advanced programming for SAS 9 */
/* Chapter 11: Creating and using macro programs */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

OPTIONS MCOMPILENOTE=ALL;

/* a simple macro */
%MACRO prtlast;
	/* print the last data set accessed */
	PROC PRINT DATA=&SYSLAST (OBS=5);
	title "Listing of the &SYSLAST data set";
	RUN;
%MEND prtlast;	/* including the macro name in %MEND improves readability */

/* some examples of calling the macro prtlast */
PROC SORT DATA=sasuser.courses OUT=courses;
	BY course_code;
RUN;

%prtlast

PROC SORT DATA=sasuser.schedule OUT=schedule;
	BY begin_date;
RUN;

OPTIONS MPRINT;		/* display SAS statements send to SAS compiler, by the macro, in the log */
%prtlast;

PROC SORT DATA=sasuser.students OUT=students;
	BY student_name;
RUN;

OPTIONS MLOGIC;		/* indicate macro actions taken during execution, in the log */
%prtlast

/* an example of a macro definition with positional parameters */
%MACRO printdsn(dsn, vars);
	%* data set on which to report (first positional parameter);
	%* variables - in data set - on which to report (second positional parameter);
	PROC PRINT DATA=&dsn;
		VAR &vars;
		title "Listing of %UPCASE(&dsn) data set (printdsn)";
	RUN;
%MEND printdsn;

%printdsn(sasuser.courses, course_code course_title days)
/* a null value can be used to replace one of the positional parameters by using commas as placeholders */

/* a second version of printdsn using keyword parameters */
%MACRO printdsn2(dsn=sasuser.courses, vars=course_code course_title days);
	PROC PRINT DATA=&dsn;
		VAR &vars;
		title "Listing of %UPCASE(&dsn) data set (printdsn2)";
	RUN;
%MEND printdsn2;	/* if the macro definitions don't match, a warning appears in the log */

%printdsn2(dsn=sasuser.schedule, vars=teacher course_code begin_date)
/* to call printdsn2 with the default values, call %printdsn2() */

/* An example of a macro with a variable number of parameters */
%MACRO printz /PARMBUFF;
	%PUT SYSPBUFF contains :: &syspbuff;	/* lists the parameters */
	%LET idx=1;
	%LET libref=%SCAN(&SYSPBUFF, &idx);		/* get the first parameter's value (the library for the datasets) */
	%LET idx=%EVAL(&idx+1);					/* increment the value of the macro variable idx */
	%LET dsname=%SCAN(&SYSPBUFF, &idx);		/* get the second parameter's value (the first data set) */
	%DO %WHILE(&dsname NE);					/* loop while dsname is not missing/null */
		PROC PRINT DATA=&libref..&dsname;	/* print the contents of the data set */
			title "Contents of data set &libref..&dsname";
		RUN;
		%LET idx=%EVAL(&idx+1);				/* increment the value of the macro variable idx */
		%LET dsname=%SCAN(&SYSPBUFF, &idx);	/* get the value of the next parameter */
	%END;
%MEND printz;

%printz(sasuser, courses, schedule);

/* an example of using %IF...%THEN and IF...THEN in a macro */
%MACRO choice(status);
	DATA fees;
		SET sasuser.all;
		%IF &status=PAID %THEN %DO;		/* control the subsetting logic included in the DATA step */
			WHERE paid = 'Y';
			KEEP student_name course_code begin_date totalfee;
		%END;
		%ELSE %DO;
			WHERE paid = 'N';
			KEEP student_name course_code begin_date totalfee latechg;
			latechg = fee * 0.10;
		%END;
		/* add local surcharge */
		/* (this could also be done using WHEN) */
		IF location = 'Boston' THEN totalfee = fee * 1.06;
		ELSE IF location = 'Seattle' THEN totalfee = fee * 1.025;
		ELSE IF location = 'Dallas' THEN totalfee = fee * 1.05;
	RUN;
%MEND choice;

OPTIONS MPRINT MLOGIC;
%choice(PAID)

/* generate a report on the enrollment at each training centre listed in sasuser.all */
%MACRO attend(crs2, 						/* course code, a positional parameter */
			  start=01Jan2001,				/* start date, a keyword parameter with a default value */
			  stop=31Dec2001);				/* stop date, a keyword parameter with a default value */
	%LET start = %UPCASE(&start);			/* make dates all uppercase */
	%LET stop = %UPCASE(&stop);
	PROC FREQ DATA = sasuser.all;
		WHERE	begin_date BETWEEN "&start"d AND "&stop"d;
		TABLE	location /NOCUM;
		title "Enrollment from &start to &stop";
		%IF crs2= %THEN %DO;		/* if no course code specified, summarise for all courses */
			title2 "all courses";
		%END;
		%ELSE %DO;
			title2 "for course &crs2 only";
			WHERE ALSO course_code="&crs2";	/* subset to the given course code */
		%END;
	RUN;
%MEND attend;

%attend(start=01jul2001);	/* enrollment for all courses from 1st July 2001 */

%attend(C003);				/* enrollment for course code C003 */

/* conditional processing of parts of a statement */
/* print of table frequency counts from a SAS data set, */
/* either one-way or two-way depending on whether the parameter rows is specified */
%MACRO counts (cols=_ALL_, rows=, dsn=&SYSLAST);
	title "Frequency counts for %UPCASE(&dsn) data set";
	PROC FREQ DATA=&dsn;
		TABLES
			%IF &rows NE %THEN &rows *;
			&cols;
	RUN;
%MEND counts;

/* two-way table */
%counts(dsn=sasuser.all, cols=paid, rows=course_number)

/* one-way table */
%counts(dsn=sasuser.all, cols=paid)

/* using an iterative %DO loop */
DATA _NULL_;
	SET sasuser.schedule END=no_more;
	CALL SYMPUT('teach' || LEFT(_n_), (TRIM(teacher)));		/* create a macro variable for each observation */
	IF no_more THEN CALL SYMPUT('count', _n_);				/* a macro variable to hold number of observations */
RUN;

OPTIONS NOMLOGIC;
%MACRO putloop;
	%LOCAL i;							/* define loop variable */
	%DO i = 1 %TO &count;				/* loop through all the records */
		%PUT teach&i is &&teach&i;		/* output the value of each of the teach[i] macro variables */
	%END;
%MEND putloop;

%putloop

/* use a %DO loop to create a series of steps in a DATA step */
%MACRO hex(start=1, stop=10, incr=1);
	%LOCAL i;
	DATA _NULL_;
		%DO i = &start %TO &stop %BY &incr;
			value = &i;
			PUT "Hexadecimal form of &i is " value HEX6.;
		%END;
	RUN;
%MEND hex;

OPTIONS MPRINT MLOGIC SYMBOLGEN;
%hex(start=20, stop=30, incr=2)

/* create a macro loop to create an entire DATA step */
/* read read a series of external files - rawYYYY.dat - for course offerings over a series of years */
%MACRO readraw(first=1999,last=2005);
	%LOCAL year;
	%DO year=&first %TO &last;
		DATA year&year;
			INFILE "raw&year..dat";
			INPUT	course_code $4.
					location $15.
					begin_date DATE9.
					teacher $25.;
		RUN;
		
		PROC PRINT DATA=year&year;
			title "Scheduled classes for &year";
			FORMAT begin_date DATE9.;
		RUN;
	%END;
%MEND readraw;

/* not called as the raw files don't exist */
/* %readraw(first=2000, last=2002) */

/* example of the use of %SYSEVALF */
%MACRO figureit(a,b);
	%LET y = %SYSEVALF(&a+&b);
	%PUT The result with SYSEVALF is: &y;
	%PUT BOOLEAN conversion:          %SYSEVALF(&a+&b, boolean);
	%PUT CEIL conversion:             %SYSEVALF(&a+&b, ceil);
	%PUT FLOOR conversion:            %SYSEVALF(&a+&b, floor);
	%PUT INTEGER conversion:          %SYSEVALF(&a+&b, integer);
%MEND figureit;

OPTIONS NOMLOGIC NOSYMBOLGEN;
%figureit(100, 1.59);
	