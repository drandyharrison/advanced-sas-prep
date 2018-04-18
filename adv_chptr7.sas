/* Advanced programming for SAS 9 */
/* Chapter 7: Creating and managing views using PROC SQL */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";

/* Create a view that includes information on flight attendants, including current age */
PROC SQL;
	CREATE VIEW work.faview AS
		SELECT	UPCASE(SUBSTR(firstname, 1, 1)) || '. ' || PROPCASE(lastname) AS name,
				gender,
				INT((today() - DateofBirth)/365.25) AS Age,		/* calculate age today */
				SUBSTR(jobcode, 3, 1) AS Level,
				salary
		FROM	sasuser.payrollmaster p,
				sasuser.staffmaster s
		WHERE	p.empid = s.empid;
		
/* Query the view */
PROC SQL;
	title "Query flight attendant view";
	SELECT	*
	FROM	faview;
	
/* Calculate mean age by level */
title "Mean age by level";
PROC TABULATE DATA=faview;
	CLASS Level;
	VAR Age;
	TABLE level*age*mean;
RUN;

PROC SQL;
	DESCRIBE VIEW faview;
	
/* Create a view that includes salary and monthly salary */
PROC SQL;
	/* create a working copy, so I can access it in the update later */
	CREATE TABLE work.payrollmaster2 AS
		SELECT	*
		FROM	sasuser.payrollmaster;
	title "Create a view that includes salary and monthly salary";
	CREATE VIEW work.raisev AS
		SELECT		empid,
					jobcode,
					salary FORMAT=DOLLAR12.,
					salary/12 AS MonthlySalary FORMAT=DOLLAR12.
		FROM		payrollmaster2;
	/* Select a subsey of jobcodes */
	SELECT	*
	FROM	raisev
	WHERE	jobcode IN ('PT2', 'PT3');
	
/* Update salary for PT3, cannot update MonthlySalary via the UPDATE statement because it's derived
/* but it will be updated because it's derived from salary */
PROC SQL;
	title "20% raise of PT3";
	UPDATE raisev
		SET salary = 1.20 * salary
		WHERE	jobcode = 'PT3';
	SELECT	*
	FROM	raisev
	WHERE	jobcode IN ('PT2', 'PT3');
	
/* Drop a view */
PROC SQL;
	DROP VIEW raisev;