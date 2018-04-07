/* Advanced programming for SAS 9 */
/* Chapter 3: Combining tables horizontally */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Cartesian product */
PROC SQL;
	title "Cartesian product";
	SELECT *
	FROM sasuser.staffmaster, sasuser.supervisors;
	
/* Complex inner join */
PROC SQL OUTOBS=15;
	TITLE "New York employees";
	SELECT 	SUBSTR(firstname,1,1) || '. ' || PROPCASE(lastname) AS Name,
			jobcode LABEL="Job code",
			INT((TODAY() - dateofbirth)/365.25) AS Age
	FROM	sasuser.payrollmaster AS p,
			sasuser.staffmaster AS s
	WHERE	p.empid = s.empid
			AND state = 'NY'
	ORDER BY 2, 3;
	
/* Inner join with summary functions */
PROC SQL OUTOBS=15;
	TITLE "Average Age of New York employees";
	SELECT 	jobcode LABEL="Job code",
			COUNT(p.empid) as Employees,
			AVG(INT((TODAY() - dateofbirth)/365.25)) FORMAT=4.1 AS AvgAge
	FROM	sasuser.payrollmaster AS p,
			sasuser.staffmaster AS s
	WHERE	p.empid = s.empid
			AND state = 'NY'
	GROUP BY jobcode
	ORDER BY jobcode;
	
/* Example of a left outer join */
PROC SQL OUTOBS=20;
	title "Left outer join: flights in March with delay information (if it exists)";
	SELECT	m.date,
			m.flightnumber LABEL="Flight number",
			m.destination LABEL="Destination (left)",
			f.destination LABEL="Destination (right)",
			delay LABEL="Delay (mimutes)"
	FROM	sasuser.marchflights AS m
			LEFT JOIN	sasuser.flightdelays AS f
			ON	m.date = f.date AND
				m.flightnumber = f.flightnumber
	ORDER BY delay, m.date;
	
/* The same as a right join */
PROC SQL OUTOBS=20;
	title "Right outer join: flights in March with delay information (if it exists)";
	SELECT	m.date,
			m.flightnumber LABEL="Flight number",
			m.destination LABEL="Destination (left)",
			f.destination LABEL="Destination (right)",
			delay LABEL="Delay (mimutes)"
	FROM	sasuser.flightdelays AS f
			RIGHT JOIN	sasuser.marchflights AS m
			ON	m.date = f.date AND
				m.flightnumber = f.flightnumber
	ORDER BY delay, m.date;

/* An inline view */
PROC SQL;
	title "Which air travel destination experienced the worst travel delays in March";
	SELECT	destination,
			average FORMAT=3.0 LABEL="Average delay",
			max FORMAT=3.0 LABEL="Maximum delay",
			/* the calculated fields late and early can be referenced with a CALCULATED keyword, */
			/* as the nested query is evaluated first; the FROM clause is always evaluated first */
			late/(late+early) AS prob FORMAT=5.2 LABEL="Probability of delay"
	FROM	(SELECT	destination,
					AVG(delay) AS average,
					MAX(delay) AS max,
					SUM(delay > 0) AS late,	/* The boolean expression delay > 0 evaluates to 1 (true) or 0 (false) */
											/* Summing these corresponds to counting the number of delays for the destination */
					SUM(delay < 0) AS early	
			 FROM sasuser.flightdelays
			 GROUP BY destination)
	ORDER BY average;

/* List the names of supervisors for the crew on flights to Copenhagen on 4th March 2013 */
/* Using the following four tables: */
/* 	flightschedule		crew who flew to Copenhagen on 4th March 2000	Columns: EmpID, Date, Destination */
/*	staffmaster			names and states of residence for employees		Columns: EmpID, Firstname, Lastname, State */
/*	payrollmaster		job categories for employees					Columns: EmpID, Jobcode */
/*	supervisors			employees who are supervisors					Columns: EmpID, State, JobCategory */
/***/
/* Note: 	supervisors live in the same state as the employees they supervise */
/*			there is one supervisor for each state and job category */
/***/
/* Approach 1: PROC SQL subqueries, joins and in-line views */
PROC SQL;
	title "Query 1: identify crew on Copenhagen (CPH) flight";
	SELECT empid
	FROM sasuser.flightschedule
	WHERE	date = '04Mar2013'd AND
			destination = "CPH";
PROC SQL;
	title "Query 2: find states and job categories of crew members on Copenhagen (CPH) flight";
	/* Query 1 is a sub-query and an inner join combines the two tables it uses */
	SELECT	SUBSTR(Jobcode, 1, 2) AS JobCategory,
			state
	FROM	sasuser.staffmaster AS s,
			sasuser.payrollmaster AS p
	WHERE	s.empid = p.empid and s.empid IN
			(SELECT empid
			 FROM sasuser.flightschedule
			 WHERE	date = '04Mar2013'd AND
					destination = "CPH");
PROC SQL;
	title "Query 3: find employee numbers of the crew supervisors";
	/* Query 2 is an in-line view of Query 3 and is given the alias c */
	/* Query 2 returns the job category and state of each crew member */
	/* Query 3 selects the employee id for supervisors that match the job category and state */
	SELECT empid
	FROM	sasuser.supervisors as m,
			(SELECT	SUBSTR(Jobcode, 1, 2) AS JobCategory,
					state
			 FROM	sasuser.staffmaster AS s,
					sasuser.payrollmaster AS p
			 WHERE	s.empid = p.empid and s.empid IN
					(SELECT empid
					 FROM sasuser.flightschedule
					 WHERE	date = '04Mar2013'd AND
							destination = "CPH")) AS c
	WHERE	m.jobcategory = c.jobcategory AND
			m.state = c.state;
	/* There are a pair of duplicate rows as two crew have the same supervisor */
PROC SQL;
	title "Query 4: find the names of supervisors";
	/* Query 3 becomes a subquery of Query 4, which selects the names of supervisors based on the employee IDs from query 3 */
	SELECT SUBSTR(firstname, 1, 1) || '. ' || PROPCASE(lastname)
	FROM sasuser.staffmaster
	WHERE empid IN
		(SELECT empid
		 FROM	sasuser.supervisors as m,
				(SELECT	SUBSTR(Jobcode, 1, 2) AS JobCategory,
						state
				 FROM	sasuser.staffmaster AS s,
						sasuser.payrollmaster AS p
				 WHERE	s.empid = p.empid and s.empid IN
						(SELECT empid
						 FROM sasuser.flightschedule
						 WHERE	date = '04Mar2013'd AND
								destination = "CPH")) AS c
		 WHERE	m.jobcategory = c.jobcategory AND
				m.state = c.state);
	/* The duplicate supervisor name has been removed */
	
/* Approach 2: PROC SQL multi-way join with reflexive join */
PROC SQL;
	title "Approach 2: Multi-way join with a reflexive join";
	SELECT DISTINCT SUBSTR(e.firstname, 1, 1) || '. ' || PROPCASE(e.lastname)
	FROM	sasuser.flightschedule AS a,
			sasuser.staffmaster AS b,
			sasuser.payrollmaster AS c,
			sasuser.supervisors AS d,
			sasuser.staffmaster AS e
	WHERE	a.date = '04Mar2013'd AND
			a.destination = "CPH" AND
			a.empid = b.empid AND
			a.empid = c.empid AND
			d.jobcategory = SUBSTR(c.jobcode, 1, 2) AND
			d.state = b.state AND
			d.empid = e.empid
	ORDER BY e.lastname;
/* The multi-way join is more efficient that approach 1, but is harder to build in stages - as we did with Approach 1 */
/* In a multi-way join, PROC SQL joins tables in pairs and performs the joins in the most efficient way */
/* staffmaster is read two separate times (a reflexive join) and is assigned a different alias for each time it is read */
/* can we develop in stages - as per approach 1 - then convert into a more efficient multi-way join? */

/* Approach 3: Traditional SAS programming */
title "Approach 3: Traditional SAS programming";
/* find the crew for the flight */
PROC SORT DATA=sasuser.flightschedule (DROP=flightnumber) OUT=crew (KEEP=empid);
	WHERE destination = "CPH" AND date = '04Mar2013'd;
	BY empid;
RUN;
/* find the state and job code for the crew */
PROC SORT DATA=sasuser.payrollmaster (KEEP=empid jobcode) OUT=payroll;
	BY empid;
RUN;
PROC SORT DATA=sasuser.staffmaster (KEEP=empid state firstname lastname) OUT=staff;
	BY empid;
RUN;
DATA at_cat (KEEP=state jobcategory);
	MERGE	crew (in=c)
			staff
			payroll;
	BY empid;
	IF c;
	jobcategory = SUBSTR(jobcode,1,2);
RUN;
/* find the supervisors employee IDs */
PROC SORT DATA=at_cat;
	BY jobcategory state;
RUN;
PROC SORT DATA=sasuser.supervisors OUT=superv;
	BY jobcategory state;
RUN;
DATA super (KEEP=empid);
	MERGE	at_cat(in=s)
			superv;
	BY jobcategory state;
	IF s;
RUN;
/* find the names of the supervisors */
PROC SORT DATA=super NODUPKEY;	/* NODUPKEY removes any duplicates */
	BY empid;
RUN;
DATA names(DROP=empid firstname);
	MERGE	super (in=super)
			staff (KEEP=empid firstname lastname);
	BY empid;
	IF super;
	name = SUBSTR(firstname,1,1) || '. ' || PROPCASE(lastname);
RUN;
PROC SORT DATA=names;
	BY lastname;
RUN;
DATA fin_name (DROP=lastname);
	SET names;
RUN;
PROC PRINT DATA=fin_name noobs uniform;
RUN;
/* In benchmarks, the SQL queries use less CPU time but more I/O operations than this traditional SAS */