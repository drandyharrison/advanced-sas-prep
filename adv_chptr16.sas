/* Advanced programming for SAS 9 */
/* Chapter 16: Using lookup tables to match data */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

DATA wndchill (DROP=row col);
	/* values:  wind chill (apparent temperature, Fahrenheit) */
	/* rows:    wind speed (mph) 5 - 40 in 5mph increments */
	/* columns: air temperature (Fahrenheit) -10 - +30 in 5 degree increments */
	ARRAY wc{8,9} _TEMPORARY_
		(-22, -16, -11,  -5,   1,  7, 13, 19, 25,
		 -28, -22, -16, -10,  -4,  3,  9, 15, 21,
		 -32, -26, -19, -13,  -7,  0,  6, 13, 19,
		 -35, -29, -22, -15,  -9, -2,  4, 11, 17,
		 -37, -31, -24, -17, -11, -4,  3,  9, 16,
		 -39, -33, -26, -19, -12, -5,  1,  8, 15,
		 -41, -34, -27, -21, -14, -7,  0,  7, 14,
		 -43, -36, -29, -22, -15, -8, -1,  6, 13);
	SET sasuser.flights;
	row = ROUND(wspeed, 5)/5;		/* translate wspeed into which row to read */
	col = (ROUND(temp, 5)/5) + 3;	/* translate temp into which column to read */
	WindChill = wc{row, col};		/* read the wind chill from the temporary array */
RUN;

PROC PRINT DATA=wndchill;
	title "wind chill for flights - using an array as a lookup";
RUN;

/* using stored array values as a lookup */
DATA lookup1;
	/* create an (empty) array to hold look up values */
	ARRAY targets{1997:1999, 12} _TEMPORARY_;
	/* before reading first observation populate array */
	IF _N_ = 1 THEN 
		DO i = 1997 to 1999;					/* loop through the years, on separate line to be clear of loop */
			SET sasuser.ctargets;				/* read the target cargo revenue targets
												   one observation per year with variables Jan - Dec */
			ARRAY mnth{*} Jan--Dec;				/* array to hold the monthly targets for the current observation's year
												   the double hyphen reads values based on their order in the PDV rather than alphabetically */
			DO j = 1 TO dim(mnth);
				targets{year, j} = mnth{j};		/* populate targets with each month's target for current observation's year */
			END;
	END;
	/* read in the actual monthly revenue */
	SET sasuser.monthsum (KEEP=salemon revcargo monthno);
	year = INPUT(SUBSTR(salemon, 4), 4.) - 13;	/* get the year from the date string and convert it to a numeric */
												/* targets are for 1997 - 1999, revenue 2010 - 2012, adjusted to work */
	Ctarget = targets{year, monthno};			/* get the corresponding target */
	FORMAT ctarget DOLLAR15.2;
	LABEL	ctarget="Cargo revenue target"
			revcargo="Cargo revenue";
RUN;
PROC PRINT DATA=lookup1 LABEL NOOBS;
	title "Cargo revenue against target";
	title2 "(monthly breakdown)";
	VAR salemon revcargo ctarget;
RUN;

/* redo wind chill example with stored array */
%LET datadir=/folders/myfolders/sasuser.v94/advanced-sas-prep/;
FILENAME wcfile "&datadir.windchill.dat";
DATA wclkup;
	INFILE	wcfile DLM=",";
	/* read in the temperatures */
	INPUT	F_m10	/* -10F */
			F_m05
			F_0		/* 0F */
			F_p05	/* +5F */
			F_p10
			F_p15
			F_p20
			F_p25
			F_p30;
RUN;

title "Wind chill lookup table";
PROC PRINT DATA=wclkup;
RUN;

DATA wndchll1(DROP=i j row col F_m10--F_p30);
	/* create an empty array to hold the windchill lookup */
	ARRAY wc{8,9} _TEMPORARY_;
	IF _N_ = 1 THEN
		DO i = 1 to 8;
			SET wclkup;		/* read the wind chill lookup */
			ARRAY wc_temp{*} F_m10--F_p30;	/* temporary array to hold wind chill for current observation's wind speed */
			DO j = 1 TO DIM(wc_temp);
				wc{i,j} = wc_temp{j};
			END;
	END;
	SET sasuser.flights(KEEP=flight temp wspeed);
	row = ROUND(wspeed, 5)/5;					/* translate wspeed into which row to read */
	col = (ROUND(temp, 5)/5) + 3;				/* translate temp into which column to read */
	WindChill_F = wc{row, col};					/* read the wind chill from the temporary array */
	WindChill_C = (WindChill_F - 32) * 5/9;		/* wind chill in Celsius */
	temp_c = (temp - 32) * 5/9;
	FORMAT WindChill_F WindChill_C temp temp_c wspeed 5.1;
	LABEL	WindChill_F="Wind chill (F)"
			WindChill_C="Wind chill (C)"
			temp="Air temp. (F)"
			wspeed="Wind speed (mph)"
			temp_c="Air temp. (C)";
RUN;

PROC PRINT DATA=wndchll1 LABEL NOOBS;
	title "Wind chill (reading in lookup)";
	VAR flight wspeed temp WindChill_F temp_c WindChill_C;
RUN;