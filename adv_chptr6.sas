/* Advanced programming for SAS 9 */
/* Chapter 6: Creating and managing indexes using PROC SQL */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Creating a simple index */
PROC SQL;
	/* create a working copy of payrollmaster */
	CREATE TABLE work.payrollmaster AS
		SELECT	*
		FROM	sasuser.payrollmaster;
	CREATE INDEX Empid
		ON work.payrollmaster(Empid);
		
/* Create a composite, unique index */
PROC SQL;
	/* create a working copy of marchflights */
	CREATE TABLE work.marchflights AS
		SELECT	*
		FROM	sasuser.marchflights;
	CREATE UNIQUE INDEX Daily
		ON work.marchflights(Flightnumber, Date);

/* display any indexes associated with tables */
PROC SQL;
	DESCRIBE TABLE payrollmaster;
	DESCRIBE TABLE marchflights;
	
/* Query the dictionary of indexes */
PROC SQL;
	title "Dictionary of indexes";
	SELECT	*
	FROM	Dictionary.Indexes
	WHERE	libname = "WORK";

/* Are my indexes being used? */
OPTIONS MSGLEVEL=I;							/* reports information on whether indexes are being used */
											/* only use for testing and debugging */
PROC SQL;
	title "Are my indexes being used?";
	SELECT	*
	FROM	marchflights
	WHERE	Flightnumber = '182';
	title "Index isn't used - but it is";
	SELECT	*
	FROM	marchflights
	WHERE	Flightnumber IN ('182', '202')
	ORDER BY Flightnumber;
	
PROC SQL;
	title "Force SAS to not use indexes";
	SELECT	*
	FROM	marchflights (IDXWHERE=NO)			/* IDXWHERE controls whether indexes are used - NO forces sequential processing */
												/* It can also be used as a system option, with OPTIONS */
	WHERE	Flightnumber = '182';

/* Control which index is used */
PROC SQL;
	title "Control which index to use";
	/* create a new simple index */
	CREATE INDEX Date
		ON marchflights(Date);
	SELECT	*
	FROM	marchflights (IDXNAME = Daily)		/* Force SAS to use composite index Daily, */
												/* although it would've chose to use the simple index Date */
	WHERE	Flightnumber IN ('182')
	ORDER BY Flightnumber;

/* dropping an index */
PROC SQL;
	DROP INDEX Daily
	FROM marchflights;
	