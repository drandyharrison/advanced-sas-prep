/* Advanced programming for SAS 9 */
/* Chapter 1: Performing queries with PROC SQL */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* ordering by multiple columns */
title "PROC SQL: ordering by multiple columns";
PROC SQL;
	SELECT	empid,
			jobcode,
			salary,
			salary * 0.06 AS bonus
	FROM sasuser.payrollmaster
	WHERE salary < 32000
	ORDER BY jobcode, empid;
QUIT;

/* querying multiple tables - inner join */
title "PROC SQL: querying multiple tables - inner join";
PROC SQL;
	SELECT		salcomps.empid,
				lastname,
				newsals.salary,
				newsalary
	FROM		sasuser.salcomps,
				sasuser.newsals
	WHERE		salcomps.empid = newsals.empid
	ORDER BY	lastname;
QUIT;

/* Summarising groups of data */
title "PROC SQL: summarising groups of data";
PROC SQL;
	SELECT	membertype,
			sum(milestraveled) AS TotalMiles
	FROM sasuser.frequentflyers
	GROUP BY membertype;
QUIT;

/* Creating output tables */
title "PROC SQL: creating output tables";
PROC SQL;
	CREATE TABLE work.miles AS
		SELECT	membertype,
				sum(milestraveled) AS TotalMiles
		FROM sasuser.frequentflyers
		GROUP BY membertype;
QUIT;

PROC PRINT DATA=miles;
RUN;

/* The HAVING clause */
title "PROC SQL: the HAVING clause";
PROC SQL;
	SELECT		jobcode,
				AVG(salary) AS Avg
	FROM		sasuser.payrollmaster
	GROUP BY	jobcode
	HAVING		AVG(salary) > 40000
	ORDER BY	jobcode;