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

title "Ticket agents";
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
	
/* Demonstrate integrity constraints */
PROC SQL;
	title "Basic integrity constraints example";
	CREATE TABLE work.employees
		(ID char(5) PRIMARY KEY,								/* The column ID is the primary key */
		 Name char(10),
		 Gender char(1) NOT NULL CHECK(gender IN ('M', 'F')),	/* Gender cannot missing values and must be either 'M' or 'F' */
		 HDate date LABEL='Hire Date');							/* Hire date is a type date */
	DESCRIBE TABLE employees;									/* writes the constraints to results */

/* Creating integrity constraints using a constraint specification */
PROC SQL;
	title "Creating integrity constraints using a constraint specification";
	CREATE TABLE work.discounts3
		(Destination char(3),
		 BeginDate num FORMAT=DATE9.,
		 EndDate num FORMAT=DATE9.,
		 Discount num  FORMAT=PERCENT6.2,
		 CONSTRAINT ok_discount CHECK(discount le 0.5),			/* Limits discounts to 50% */
		 CONSTRAINT notnull_dest NOT NULL(destination));		/* Prevents missing values being entered for a destination */
	DESCRIBE TABLE discounts3;
	
/* Insert some data, some of which violates the intregity clauses (default undo policy) */
title "Inserting data that violate integrity constraints";
PROC SQL;
	INSERT INTO discounts3
		VALUES ('CDG', '03MAR2010'd, '10MAR2010'd, 0.15)
		VALUES ('LHR', '10MAR2010'd, '12MAR2010'd, 0.55);	/* violates the ok_discount constraint */
		/* all the inserts are deleted on error */
PROC SQL;
	SELECT * FROM discounts3;								/* separate PROC SQL statement as previous one will stop on error */
	
/* And again with UNDO_POLICY=NONE */
title "Inserting data that violate integrity constraints (with UNDO_POLICY=NONE only display constraints)";
PROC SQL UNDO_POLICY=NONE;									/* UNDO_POLICY applies to the whole PROC SQL statement or until a RESET */
	CREATE TABLE work.discounts4
		(Destination char(3),
		 BeginDate num FORMAT=DATE9.,
		 EndDate num FORMAT=DATE9.,
		 Discount num FORMAT=PERCENT6.2,
		 CONSTRAINT ok_discount CHECK(discount le 0.5),		/* Limits discounts to 50% */
		 CONSTRAINT notnull_dest NOT NULL(destination));	/* Prevents missing values being entered for a destination */
	DESCRIBE TABLE CONSTRAINTS discounts4;					/* only display the table constraints */
	INSERT INTO discounts4
		VALUES ('CDG', '03MAR2010'd, '10MAR2010'd, 0.15)
		VALUES ('LHR', '10MAR2010'd, '12MAR2010'd, 0.55);	/* violates the ok_discount constraint */
PROC SQL;
		SELECT * FROM discounts4;							/* separate PROC SQL statement as previous one will stop on error */

/* updating a subset of rows with a single expression */
PROC SQL OUTOBS = 10;										/* only display first 10 observations */
	CREATE TABLE work.payrollmaster_new AS					/* create a working copy of payrollmaster */
		SELECT * FROM sasuser.payrollmaster;
	title "Before pay rise";
	SELECT * 												/* Display before payrise */
	FROM payrollmaster_new;
	title "10% payrise to all level 1 employees";
	UPDATE payrollmaster_new
		SET salary=salary * 1.10
		WHERE jobcode LIKE '__1';
	SELECT * 												/* Display after payrise */
	FROM payrollmaster_new;

/* again but different payrises for different levels */
PROC SQL OUTOBS = 10;
	title "Variable payrise by level";
	UPDATE payrollmaster_new
		SET salary=salary * 
		CASE												/* no case operand */
			WHEN SUBSTR(jobcode, 3, 1) = '1'				/*  5% payrise for level 1 */
				THEN 1.05
			WHEN SUBSTR(jobcode, 3, 1) = '2'				/* 10% payrise for level 2 */
				THEN 1.10
			WHEN SUBSTR(jobcode, 3, 1) = '3'				/* 15% payrise for level 3 */
				THEN 1.15
			ELSE 1.08										/*  8% for all others - avoids returning a missing value */
		END;												/* End of the case clause */
	SELECT * 												/* Display after level based payrise */
	FROM payrollmaster_new;


/* again but different payrises for different levels (rewritten using an optional case operand) */
PROC SQL OUTOBS = 10;
	title "Variable payrise by level (with case operand)";
	CREATE TABLE work.payrollmaster_new2 AS
		SELECT * FROM sasuser.payrollmaster;
	UPDATE payrollmaster_new2
		SET salary=salary * 
		CASE SUBSTR(jobcode, 3, 1)							/* the case operand can only be included if SET clause uses = */
			WHEN '1'										/*  5% payrise for level 1 */
				THEN 1.05
			WHEN '2'										/* 10% payrise for level 2 */
				THEN 1.10
			WHEN '3'										/* 15% payrise for level 3 */
				THEN 1.15
			ELSE 1.08										/*  8% for all others - avoids returning a missing value */
		END;												/* End of the case clause */
	SELECT * 												/* Display after level based payrise */
	FROM payrollmaster_new2;

/* using CASE within a SELECT statement */
PROC SQL OUTOBS = 10;
	title "Report: employee job levels";
	SELECT		lastname LABEL = "Surname",
				firstname LABEL= "Christian name",
				jobcode LABEL = "Job code",
				CASE SUBSTR(jobcode, 3, 1)
					WHEN '1'
						THEN 'Junior'
					WHEN '2'
						THEN 'Senior'
					WHEN '3'
						THEN 'Principal'
					ELSE 'None'
				END AS JobLevel LABEL = "Job Level"
	FROM		sasuser.payrollmaster p, sasuser.staffmaster s
	WHERE		p.empid = s.empid
	ORDER BY	lastname, firstname;
	
/* Delete all records from frequent flyers of member who have used all their miles or more than they have in their accounts */
PROC SQL OUTOBS=20;
	title "Deleting rows";
	/* create a working copy */
	CREATE TABLE work.frequentflyers2 AS
		SELECT	ffid,
				milestraveled,
				pointsearned,
				pointsused
		FROM	sasuser.frequentflyers;
	/* delete rows */
	DELETE FROM frequentflyers2
	WHERE pointsearned <= pointsused;
	/* have a look */
	SELECT *
	FROM frequentflyers2;
	
/* Add columns to a working copy of payrollmaster */
PROC SQL OUTOBS=10;
	title "Adding columns";
	CREATE TABLE work.payrollmaster4 AS
		SELECT *
		FROM sasuser.payrollmaster;
	/* Add columns */
	ALTER TABLE payrollmaster4
		ADD	Bonus num FORMAT=PERCENT6.2,
			Level char(3);
	/* Have a look */
	SELECT *
	FROM payrollmaster4;
	
/* Now drop the columns just added */
PROC SQL OUTOBS = 10;
	title "Dropping one of the columns just added";
	ALTER TABLE payrollmaster4
		DROP Level;
	SELECT *
	FROM payrollmaster4;
	
/* modify a column */
PROC SQL OUTOBS = 10;
	title "Modify the salary column";
	ALTER TABLE payrollmaster4
		MODIFY salary FORMAT=DOLLAR11.2 LABEL="Salary amt.";
	SELECT *
	FROM payrollmaster4;
	
/* make different changes in a single ALTER TABLE statement */
PROC SQL OUTOBS = 10;
	title "All at once";
	ALTER TABLE payrollmaster4
		ADD		Age num
		MODIFY	DateofHire date FORMAT=ddmmyy10.
		DROP	DateofBirth,
				Gender,
				Bonus;
	SELECT *
	FROM payrollmaster4;
	
/* Get rid of the temporary table payrollmaster4 */
PROC SQL;
	title "Drop table";
	DROP TABLE payrollmaster4;
	SELECT *
	FROM payrollmaster4;
		
	