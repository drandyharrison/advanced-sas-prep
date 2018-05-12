/* Advanced programming for SAS 9 */
/* Chapter 17: Formatting data */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);
%LET datadir=/folders/myfolders/sasuser.v94/advanced-sas-prep/;

/* creating a non-overlapping format (review) */
LIBNAME library "&datadir./formats";
PROC FORMAT LIB=library;
	/* group airline routes into zones */
	VALUE $routes
		'Route1' = 'Zone 1'
		'Route2' - 'Route4' = 'Zone 2'
		'Route5' - 'Route7' = 'Zone 3'
		' ' = 'Missing'
		OTHER = 'Unknown';
	/* label airport codes as International or Domestic */
	VALUE $dest
		'AKL', 'AMS', 'ARN', 'ATH', 'BKK', 'BRU',
		'CBR', 'CCU', 'CDG', 'CPH', 'CPT', 'DEL',
		'DXB', 'FBU', 'FCO', 'FRA', 'GLA', 'GVA',
		'HEL', 'HKG', 'HND', 'JED', 'JNB', 'JRS',
		'LHR', 'LIS', 'MAD', 'NBO', 'PEK', 'PRG',
		'SIN', 'SYD', 'VIE', 'WLG' = 'International'
		'ANC', 'BHM', 'BNA', 'BOS', 'DFW', 'HNL',
		'IAD', 'IND', 'JFK', 'LAX', 'MCI', 'MIA',
		'MSY', 'ORD', 'PWM', 'RDU', 'SEA', 'SFO' = 'Domestic';
	/* group cargo revenue figures into bands */
	VALUE revfmt
		. = 'Missing'
		low - 10000 = 'up to $10k'
		10000 <- 20000 = '$10k+ - $20k'
		20000 <- 30000 = '$20k+ - $30k'
		30000 <- 40000 = '$30k+ - $40k'
		40000 <- 50000 = '$40k+ - $50k'
		50000 <- 60000 = '$50k+ - $60k'
		60000 <- HIGH = 'more than $60k';
RUN;

/* create a format with an overlapping range */
PROC FORMAT LIBRARY=library;
	VALUE dates (MULTILABEL)							/* MULTILABEL option indicates format will have overlapping ranges */
		'01JAN2000'd - '31MAR2000'd = '1st quarter'
		'01APR2000'd - '30JUN2000'd = '2nd quarter'
		'01JUL2000'd - '30SEP2000'd = '3rd quarter'
		'01OCT2000'd - '31DEC2000'd = '4th quarter'
		'01JAN2000'd - '30JUN2000'd = '1st half'
		'01JUL2000'd - '31DEC2000'd = '2nd half';
RUN;

/* apply format with overlapping range in a PROC TABULATE step */
title "Applying a multilabel format - with overlapping ranges";
PROC TABULATE DATA=sasuser.sale2000 FORMAT=DOLLAR15.2;	/* specify default format for each cell */
	FORMAT date dates.;									/* apply the dates format to the variable date */
	CLASS date /MLF;									/* MLF option to activate multilabel formatting */
	VAR revcargo;
	TABLE date, revcargo*(mean median);					/* creates a row for each formatted value of date */
RUN;

/* formatting how numbers are displayed using a PICTURE statement */
PROC FORMAT LIB=library;
	PICTURE rainamt
		0  -   2 = 'slight:   9.99'		/* as there are no non-zero digit selectors, values have leading zeros */
		2< -   4 = 'moderate: 9.99'
		4< - <10 = 'heavy:    9.99'
		OTHER    = 'check:    999';
RUN;
/* read in some rain data */
DATA rain;
	INPUT amount;
	DATALINES;
	4
	3.9
	20
	0.5
	6
;
RUN;
/* print out the rain data, applying format */
title "Formatted rain data";
PROC PRINT DATA=rain;
	FORMAT amount rainamt.;
RUN;
/* use directives with a PICTURE statement to format employee hire dates */
PROC FORMAT LIBRARY=library;
	PICTURE mydate
			/* LOW - HIGH ensures all values are included */
			/* the 0 in %d directive indicates single digit days of month should be prefixed with a zero */
			/* blank spaces to increase length of format definition to length of values */
		LOW - HIGH = "%0d-%b%Y  " (DATATYPE=DATE);
RUN;

title "Employee data with hiredate formatted using directives";
PROC PRINT DATA=sasuser.empdata (KEEP=division hiredate lastname OBS=5) NOOBS;
	FORMAT hiredate mydate.;
	LABEL	hiredate="Hire Date"
			lastname="Surname";
RUN;

/* list formats in my catalog */
title "Formats created so far";
PROC FORMAT LIBRARY=library FMTLIB;
RUN;

/* Just list the $routes format */
title "The $route format";
PROC FORMAT LIBRARY=library FMTLIB;
	SELECT $routes;
RUN;

/* copy format between catalogs */
PROC CATALOG CATALOG=library.formats;
	COPY OUT=work.formats;
	SELECT routes.formatc;
RUN;
title "Copy $routes from library.formats catalog to work.formats catalog";
PROC CATALOG CAT=work.formats;
	CONTENTS;
RUN;
QUIT;

/* using NOFMTERROR to substitue formats when SAS cannot load the specified format */
title "Substituting formats using NOFMTERR";
OPTIONS NOFMTERR;
PROC PRINT DATA=sasuser.cargorev (OBS=10) NOOBS;
	FORMAT	route $route.
			date mydate.
			revcargo DOLLAR15.2;
RUN;

/* creating a format from a data set and apply it */
/* create a format that labels the three letter airport code with the name of the city where the airport is located */
/* use acities to create the format, but it's not in the correct structure to use with CNTLIN= */
title "create a format from a data set";
title2 "(list data set variables)";
PROC CONTENTS DATA=sasuser.acities;
RUN;
/* restructure the data into the correct format to use with CNTLIN= */
DATA aports;
	KEEP start label fmtname;
	RETAIN fmtname "$airport";
	SET sasuser.acities (RENAME=(Code=Start City=Label));
RUN;
title2 "(restructure data to correct format to use with CNTLIN=)";
PROC PRINT DATA=aports (OBS=10) NOOBS;
RUN;
title2 "(create and document format)";
/* create format */
PROC FORMAT LIB=library CNTLIN=aports;
RUN;
/* document format */
PROC FORMAT LIB=library FMTLIB;
	SELECT $airport;
RUN;
title2 "(apply format)";
PROC PRINT DATA=sasuser.cargo99 (OBS=5);
	VAR origin dest cargorev;
	FORMAT origin dest $airport.;
RUN;

/* create a data set from a format, to append an existing format */
/* export the $airport format to a data set */
PROC FORMAT lib=library CNTLOUT=fmtdata;	/* export the format catalog to a new data set: fmtdata */
	SELECT $airport;						/* only export data for the format $airport */
RUN;
title "a format exported to a data set";
PROC PRINT DATA=fmtdata (OBS=5) NOOBS;
	VAR fmtname start end label min max default length fuzz;
RUN;
/* insert additional rows into the data set, using PROC SQL */
PROC SQL;
	INSERT INTO fmtdata (fmtname, start, end, label)
		VALUES ('$AIRPORT', 'YYC', 'YYC', 'Calgary, AB')	
		VALUES ('$AIRPORT', 'YYZ', 'YYZ', 'Toronto, ON')
		VALUES ('$AIRPORT', 'YQB', 'YQB', 'Quebec, QC')
		VALUES ('$AIRPORT', 'YUL', 'YUL', 'Montreal, QC');
		/* when adding the format name, */
		/* prefix with $ to avoid an error: this range is repeated, or values overlap: .-.. */
		/* even though no prefix in data set */
		/* rows prefixed with $ are added those without aren't, if all aren't get the error */
QUIT;
title "check rows have been added";
PROC PRINT DATA=fmtdata;
	VAR fmtname start end label;
RUN;
/* create a format from the revised SAS data set */
PROC FORMAT LIB=library CNTLIN=fmtdata;
RUN;
title "check revised format";
PROC FORMAT LIB=library FMTLIB;
	SELECT $airport;
RUN;