/* Advanced programming for SAS 9 */
/* Chapter 5: Creating and managing tables */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Create an empty table by defining columns */
/* Use the DESCRIBE TABLE statement to display information about a table's structure */
PROC SQL;
	CREATE TABLE work.discount
		(Destination char(3),
		 BeginDate num FORMAT=DATE9.,
		 EndDate num FORMAT=DATE9.,
		 Disc num LABEL="Discount" FORMAT=PERCENT6.2);
QUIT;
/* Write a CREATE TABLE statement to the log, which gives the column definitions of the table */
PROC SQL;
	DESCRIBE TABLE discount;

/* Create a table work.flightdelays2, which has the same columns and attributes as sasuser.flightdelays but no data */
PROC SQL;
	CREATE TABLE work.flightdelays2 LIKE sasuser.flightdelays;
	
PROC SQL;
	DESCRIBE TABLE flightdelays2;

/* Create an empty table with a subset of columns from an existing table */
PROC SQL;
	CREATE TABLE work.flightdelays3 (DROP=delaycategory destinationtype) LIKE sasuser.flightdelays;
	
PROC SQL;
	DESCRIBE TABLE flightdelays3;
	
/* Create a table that contains data for ticket agents employed by an airline */
/* This is a subset of data in sasuser.payrollmaster and sasuer.staffmaster, */
/* subset for employees with Jobcode containing 'TA' */
PROC SQL;
	CREATE TABLE work.ticketagents AS
		SELECT lastname, firstname, jobcode, salary
		FROM sasuser.payrollmaster p, sasuser.staffmaster s
		WHERE p.empid = s.empid AND p.jobcode CONTAINS 'TA'
		ORDER BY jobcode, lastname;
	DESCRIBE TABLE ticketagents;
	
PROC PRINT DATA=ticketagents;
RUN;

/* add data to the table discounts using SET clauses */
PROC SQL;
	title "Adding data using a SET clause";
	INSERT INTO discount		/* No (optional) list of target columns */
		SET	destination = 'LHR',
			begindate = '01MAR2000'd,
			enddate = '05MAR2000'd,
			disc = 0.33
		SET	destination = 'CPH',
			begindate = '03MAR2000'd,
			enddate = '10MAR2000'd,
			disc = 0.15;
	/* Display contents of discount */
	SELECT *
	FROM discount;
	
/* add two more rows using a VALUES clause */
PROC SQL;
	title "Adding data using a VALUE clause";
	INSERT INTO discount
		VALUES ('ORD', '05MAR2000'd, '15MAR2000'd, 0.25)
		VALUES ('YYZ', '06MAR2000'd, '20MAR2000'd, 0.10);
	/* Display contents of discount */
	SELECT *
	FROM discount;
	
/* A mechanic has been promoted from level 2 to level 3, */
/* which requires an entry to be added to sasuser.mechanicslevel3 - which lists all level 3 mechanics */
PROC SQL;
	title "Update records after a mechnanic is promoted to level 3";
	/* Start by creating a temporary copy of sasuser.mechanicslevel3 */
	CREATE TABLE work.mechanicslevel3_new AS
		SELECT * FROM sasuser.mechanicslevel3;
	/* Insert a row into mechanicslevel3_new for the promoted mechanic (empID=1653) */
	INSERT INTO mechanicslevel3_new
		SELECT	empid,
				jobcode,
				salary
		FROM sasuser.mechanicslevel2
		WHERE empid = '1653';
	/* display updated contents */
	SELECT *
	FROM mechanicslevel3_new;