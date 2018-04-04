/* Advanced programming for SAS 9 */
/* Chapter 2: Performing advanced queries with PROC SQL */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* An illustration of some of the new query techniques I'll learn */
PROC SQL outobs=20;
	title "Job groups with average salary";
	title2 "> company average salary";
	SELECT	jobcode,
			AVG(salary) as AvgSalary format=DOLLAR11.2,
			COUNT(*) AS count
	FROM sasuser.payrollmaster
	GROUP BY jobcode
	HAVING AVG(salary) >
		(SELECT AVG(salary)
		 FROM sasuser.payrollmaster)
	ORDER BY AvgSalary DESC;


/* Display all the rows and columns in sasuser.staffchanges */
title "Select all rows and columns (with feedback)";
title2;
PROC SQL feedback;
	SELECT *
	FROM sasuser.staffchanges;


/* Restricting the number of rows displayed (with the OUTOBS= option) */
title "Restricting the number of rows displayed";
PROC SQL OUTOBS=10;
	SELECT flightnumber, date
	FROM sasuser.flightschedule;


/* Displaying unique rows with the DISTINCT keyword */
title "Displaying unique rows";
PROC SQL;
	SELECT DISTINCT flightnumber, destination
	FROM sasuser.internationalflights;


/* An example of using the BETWEEN-AND operator */
title "An example of using the BETWEEN-AND operator";
PROC SQL;
	SELECT	jobcode,
			salary
	FROM sasuser.payrollmaster
	WHERE salary BETWEEN 70000 AND 80000;


/* An example of using the CONTAINS operator */
title "An example of using the CONTAINS operator";
PROC SQL OUTOBS=10;
	SELECT name
	FROM sasuser.frequentflyers
	WHERE name CONTAINS 'ER';

/* An example of using the IN operator */
title "An example of using the IN operator";
PROC SQL;
	SELECT date, flightnumber, destination, boarded
	FROM sasuser.internationalflights
	WHERE 	destination IN ('LHR', 'CDG') AND
			date BETWEEN '01MAR2013'd AND '10MAR2013'd;


/* An example of using the IS MISSING/IS NULL operator */
/* retrieve rows that contain missing values for the field Boarded */
title "An example of using the IS MISSING/IS NULL operator";
PROC SQL;
	SELECT	boarded,
			transferred,
			nonrevenue,
			deplaned
	FROM sasuser.marchflights
	WHERE boarded IS MISSING;


/* An example of using the LIKE operator */
title "An example of using the LIKE operator";
PROC SQL;
	SELECT	ffid,
			name,
			address
	FROM sasuser.frequentflyers
	WHERE address LIKE "% P%PLACE";


/* Subsetting rows by a calculated value - used the CALCULATED keyword */
title "Subsetting rows by a calculated value";
PROC SQL OUTOBS=10;
	SELECT	flightnumber,
			date format=DATE9.,
			destination,
			boarded + transferred + nonrevenue AS total format=COMMA5.1,
			CALCULATED total/2 AS half format=COMMA5.1
	FROM sasuser.marchflights
	WHERE CALCULATED total < 100;


/* Enhancing query output */
%let bonuspct = 0.10;			/* 10% bonus */
PROC SQL OUTOBS=15;
	title "Current bonus information";
	title2 "(employees with salary more than $75k)";
	SELECT	empid LABEL='Employee ID',
			jobcode LABEL='Job code',
			salary,
			salary * &bonuspct. AS bonus FORMAT=DOLLAR12.2
	FROM sasuser.payrollmaster
	WHERE salary > 75000
	ORDER BY salary DESC;


/* Add a character constant to the output */
PROC SQL OUTOBS=15;
	title "Current bonus information (2)";
	title2 "(employees with salary more than $75k)";
	SELECT	empid LABEL='Employee ID',
			jobcode LABEL='Job code',
			salary,
			"Bonus is :",
			salary * &bonuspct. FORMAT=DOLLAR12.2	/* The character constant removes the need for the alias,
													   hence AS bonus is removed */
	FROM sasuser.payrollmaster
	WHERE salary > 75000
	ORDER BY salary DESC;


title2;
/* Summarising and grouping data */
title "Summarising and grouping data";
PROC SQL;
	SELECT	membertype LABEL="Member Grade",
			AVG(milestraveled) as AvgMilesTraveled LABEL = "Average Miles Travelled" FORMAT=COMMA12.2
	FROM sasuser.frequentflyers
	GROUP BY membertype;


/* Summary function processing */
PROC SQL;
	title "Summary function processing: single argument";
	SELECT	AVG(salary) AS AvgSalary LABEL="Average Salary" FORMAT=DOLLAR12.2	/* Calculate down column */
	FROM sasuser.payrollmaster;

PROC SQL OUTOBS=10;
	title "Summary function processing: multiple arguments";
	/* Calculate across rows */
	SELECT SUM(boarded, transferred, nonrevenue) AS total LABEL="Passenger numbers" FORMAT=COMMA6.0
	FROM sasuser.marchflights;

/* with OUTOBS all 148 rows would be listed */
PROC SQL OUTOBS = 20;
	title "Summary function processing: with columns outside the aggregator function";
	SELECT	jobcode LABEL="Job code",
			AVG(salary) AS AvgSalary FORMAT=DOLLAR12.2	/* calculates average salary for whole table */
	FROM sasuser.payrollmaster;

PROC SQL;
	title "Summary function processing: with GROUP BY clause";
	SELECT	jobcode LABEL="Job code",
			AVG(salary) AS AvgSalary FORMAT=DOLLAR12.2
	FROM sasuser.payrollmaster
	GROUP BY jobcode;

PROC SQL;
	title "Counting all rows";
	SELECT	COUNT(*) AS Count
	FROM sasuser.payrollmaster;

PROC SQL;
	title "Couting rows in groups";
	SELECT	SUBSTR(jobcode, 1, 2) LABEL="Job category",
			COUNT(*) AS Count
	FROM sasuser.payrollmaster
	GROUP BY 1;
	
PROC SQL;
	title "Count non-missing values in a column";
	SELECT	COUNT(jobcode) AS Count
	FROM sasuser.payrollmaster;
	
PROC SQL;
	title "Count unique values in a column";
	SELECT	COUNT(DISTINCT jobcode) AS Count
	FROM sasuser.payrollmaster;
PROC SQL;
	title "List unique values in a column";
	SELECT	DISTINCT jobcode
	FROM sasuser.payrollmaster;

PROC SQL;
	title "Select groups using a HAVING clause";
	SELECT	jobcode LABEL="Job code",
			AVG(salary) AS AvgSalary FORMAT=DOLLAR12.2
	FROM sasuser.payrollmaster
	GROUP BY jobcode
	HAVING AvgSalary > 56000;

PROC SQL;
	title "Remerging example";
	SELECT	empid LABEL="Employee ID",
			salary,
			(salary/SUM(salary)) AS Percent FORMAT=PERCENT8.2
	FROM sasuser.payrollmaster
	WHERE jobcode CONTAINS "NA";

/* clear titles and footnotes */
title;
title2;
footnote;