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
QUIT;

/* Display all the rows and columns in sasuser.staffchanges */
title "Select all rows and columns (with feedback)";
title2;
PROC SQL feedback;
	SELECT *
	FROM sasuser.staffchanges;
QUIT;

/* Restricting the number of rows displayed (with the OUTOBS= option) */
title "Restricting the number of rows displayed";
PROC SQL OUTOBS=10;
	SELECT flightnumber, date
	FROM sasuser.flightschedule;
QUIT;

/* Displaying unique rows with the DISTINCT keyword */
title "Displaying unique rows";
PROC SQL;
	SELECT DISTINCT flightnumber, destination
	FROM sasuser.internationalflights;
QUIT;

/* An example of using the BETWEEN-AND operator */
title "An example of using the BETWEEN-AND operator";
PROC SQL;
	SELECT	jobcode,
			salary
	FROM sasuser.payrollmaster
	WHERE salary BETWEEN 70000 AND 80000;
QUIT;

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
QUIT;

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
QUIT;

/* An example of using the LIKE operator */
title "An example of using the LIKE operator";
PROC SQL;
	SELECT	ffid,
			name,
			address
	FROM sasuser.frequentflyers
	WHERE address LIKE "% P%PLACE";
QUIT;

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
QUIT;