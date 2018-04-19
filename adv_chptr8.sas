/* Advanced programming for SAS 9 */
/* Chapter 8: Managing processing using PROC SQL */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Example of using INOBS= and OUTOBS= to control execution */
PROC SQL INOBS=5;
	title "Example of INOBS=";
	SELECT	*
	FROM	sasuser.mechanicslevel1
	OUTER UNION CORR
	SELECT	*
	FROM	sasuser.mechanicslevel2;
	
PROC SQL INOBS=10 NUMBER;
	title "Example of row numbers";
	SELECT	flightnumber,
			destination
	FROM	sasuser.internationalflights;
	
PROC SQL INOBS=10 DOUBLE;
	title "Example of double spaced";
	SELECT	flightnumber,
			destination
	FROM	sasuser.internationalflights;

PROC SQL INOBS=10;
	title "without flow";
	SELECT		ffid,
				membertype,
				name,
				address,
				city,
				state,
				zipcode
	FROM		sasuser.frequentflyers
	ORDER BY	pointsused;

PROC SQL INOBS=10 FLOW=10 15;
	title "with flow";
	SELECT		ffid,
				membertype,
				name,
				address,
				city,
				state,
				zipcode
	FROM		sasuser.frequentflyers
	ORDER BY	pointsused;
	
PROC OPTIONS OPTION=STIMER VALUE;
RUN;

/* Examples without and with the STIMER option */
PROC SQL;
	SELECT	name,
			address,
			city,
			state,
			zipcode
	FROM	sasuser.frequentflyers;
	SELECT	name,
			address,
			city,
			state,
			zipcode
	FROM	sasuser.frequentflyers
	WHERE	pointsearned > 7000 AND pointsused < 3000;
	
	
PROC SQL STIMER;
	SELECT	name,
			address,
			city,
			state,
			zipcode
	FROM	sasuser.frequentflyers;
	SELECT	name,
			address,
			city,
			state,
			zipcode
	FROM	sasuser.frequentflyers
	WHERE	pointsearned > 7000 AND pointsused < 3000;
	
/* Example of RESET */
PROC SQL OUTOBS=10;
	title "Example of using the RESET statement";
	/* only the OUTOBS=10 option applies */
	SELECT	flightnumber,
			destination
	FROM	sasuser.internationalflights;
	RESET NUMBER;
	/* the OUTOBS=10 and NUMBER options apply */
	SELECT	flightnumber,
			destination
	FROM	sasuser.internationalflights
	WHERE	boarded > 200;
	RESET OUTOBS=;
	/* only the NUMBER option applies */
	SELECT	flightnumber,
			destination
	FROM	sasuser.internationalflights
	WHERE	boarded > 100;

/* SAS dictionaries */
PROC SQL;
	/* what does the dictionary tables look like */
	DESCRIBE TABLE Dictionary.Tables;
	/* what are the tables in the sasuer library */
	title "Dictionary.Tables for sasuser library";
	SELECT	PROPCASE(memname) FORMAT=$20. LABEL="Table name",	/* name of the table */
			nobs LABEL="No. rows",								/* number of observations/records/rows */
			nvar LABEL="No. columns",							/* number of variables/fields/columns */
			crdate												/* creation date */
	FROM	Dictionary.tables
	WHERE	libname = "SASUSER";								/* sasuser library, must be uppercase */
	
PROC SQL;
	/* what does the dictionary columns look like */
	DESCRIBE TABLE Dictionary.Columns;
	/* which tables in sasuser have a column named EmpID */
	title "Tables in sasuser library with a column named EmpID";
	SELECT	PROPCASE(memname) LABEL="Table name"
	FROM	Dictionary.Columns
	WHERE	libname="SASUSER" AND			/* sasuser library */
			name="EmpID";					/* a column named EmpID (case must match) */
