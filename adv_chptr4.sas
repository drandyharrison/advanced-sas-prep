/* Advanced programming for SAS 9 */
/* Chapter 4: Combining tables vertically */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Example of the EXCEPT operator */
/* Display the names of new employees using */
/*	staffchanges	lists all new employees and existing employees	Lastname, Firstname */
/*					who have had a change in salary or job code                         */
/*	staffmaster		lists all all existing employees				Lastname, Firstname */
PROC SQL;
	title "EXCEPT: new employees";
	/* Any 'formatting' of the columns must match as this defines what's in the internal results table */
	SELECT SUBSTR(Firstname, 1, 1) || '. ' || PROPCASE(Lastname) LABEL="Name"
	FROM sasuser.staffchanges
	EXCEPT ALL					/* We know there are no duplicates, */
								/* ALL prevents the removal of duplicates */
								/* hence is more efficient */
	SELECT SUBSTR(Firstname, 1, 1) || '. ' || PROPCASE(Lastname)
	FROM sasuser.staffmaster;
	
/* If the order of the tables is reversed, we get the existing employees that have had a change in salary of job */
/* Use an in-line to count the number of existing employees that have had a change in salary of job */
PROC SQL;
	title "Number of existing employees that have had a change in salary of job";
	SELECT COUNT(*) LABEL="Number of employees"
	FROM	(SELECT Firstname, Lastname
			 FROM sasuser.staffmaster
			 EXCEPT ALL
			 SELECT Firstname, Lastname
			 FROM sasuser.staffchanges);

/* Example of the INTERSECT operator */
/* Existing employees who have changed their salary */
PROC SQL;
	title "INTERSECT: existing employees who have changed their salary";
	SELECT SUBSTR(Firstname, 1, 1) || '. ' || PROPCASE(Lastname) LABEL="Name"
	FROM sasuser.staffchanges
	INTERSECT ALL
	SELECT SUBSTR(Firstname, 1, 1) || '. ' || PROPCASE(Lastname)
	FROM sasuser.staffmaster;
	
/* Example of the UNION operator */
/* Health clinic data - results of stress tests in 1998 and 1998 */
PROC SQL;
	title "UNION: combined stress test data for 1998 and 1999";
	SELECT *
	FROM sasuser.stress98
	UNION
	SELECT *
	FROM sasuser.stress99;
/* If there are no duplicate records, the query can be accelerated by adding the ALL keyword */

/* UNION Operator with summary functions */
/* Display total points earned, total points used and total miles travelled from members of a frequent-flyer programme */
/* All data are in sasuser.frequentflyers */
/* To display the summary values horizontally in three columns, use the following query */
PROC SQL;
	title "Frequent flyer summary information (horizontal)";
	SELECT	SUM(pointsearned) FORMAT=COMMA12. LABEL="Total points earned",
			SUM(pointsused) FORMAT=COMMA12. LABEL="Total points used",
			SUM(milestraveled) FORMAT=COMMA12. LABEL="Total miles travelled"
	FROM sasuser.frequentflyers;
/* To summarise the vertically, as rows, create three separate queries on the table then combine with a union */
PROC SQL;
	title "UNION: frequent flyer summary information (vertical)";
	SELECT	"Total points earned: ", SUM(pointsearned) FORMAT=COMMA12.
	FROM sasuser.frequentflyers
	UNION
	SELECT	"Total points used: ", SUM(pointsused) FORMAT=COMMA12.
	FROM sasuser.frequentflyers
	UNION
	SELECT	"Total miles travelled: ", SUM(milestraveled) FORMAT=COMMA12.
	FROM sasuser.frequentflyers;

/* Exmaple of an OUTER UNION */
/* Display the employee number, job code and salary for all mechanics working for an airline */
/* There are three levels of mechanic and a separate table for each level, all with the same three columns */
PROC SQL;
	title "OUTER UNION: employee data for all mechanics";
	SELECT *
	FROM sasuser.mechanicslevel1
	OUTER UNION CORR
	SELECT *
	FROM sasuser.mechanicslevel2
	OUTER UNION CORR
	SELECT *
	FROM sasuser.mechanicslevel3;
/* The same using a DATA step */
title "DATA step: employee data for all mechanics";
DATA mechanics;
	SET sasuser.mechanicslevel1 sasuser.mechanicslevel2 sasuser.mechanicslevel3;
RUN;
PROC PRINT DATA=mechanics NOOBS;
RUN;
	