/* Advanced programming for SAS 9 */
/* Chapter 15: Combining data horizontally */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

/* Use FILENAME statement to concatenate raw data files */
%LET datadir=/folders/myfolders/sasuser.v94/;

/* Merging three data sets where pairs of data sets have common variables there are non common variables across all three */
/* version 1: using DATA step match-merge */

/* sort the expenses data set into a temporary data set, ready to merge */
PROC SORT DATA=sasuser.expenses OUT=expenses;
	BY FlightID Date;
RUN;

/* sort the revenue data set into a temporary data set, ready to merge */
PROC SORT DATA=sasuser.revenue OUT=revenue;
	BY FlightID Date;
RUN;

/* create a merged data set by merging expenses and revenue */
DATA revexpns (DROP=rev1st revbusiness revecon expenses);
	MERGE	expenses(IN=e)
			revenue(IN=r);
	BY FlightID Date;
	IF e AND r;													/* only merge if there are matching entries */
		Profit = SUM(rev1st, revbusiness, revecon, -expenses);	/* calculate profit */
RUN;

/* sort revexpns, ready to merge with the third data set */
PROC SORT DATA=revexpns;
	BY Dest;
RUN;

/* sort the acities data set into a temporary data set, ready to merge */
PROC SORT DATA=sasuser.acities OUT=acities;
	BY Code;
RUN;

/* merge revexpns and acities */
DATA alldata;
	MERGE	revexpns (IN=r)
			acities (IN=a RENAME=(code=dest) KEEP=City Name Code);
	BY Dest;
	IF r AND a;													/* only output matching observations */
RUN;

/* report merged results */
PROC PRINT DATA=alldata (OBS=5) NOOBS;
	title "Result of merging three data sets - with match-merge";
	FORMAT Date DATE9.;
RUN;

/* The same merge using PROC SQL inner join */
PROC SQL;
	CREATE TABLE sqljoin AS
		SELECT		r.flightid,
					r.date FORMAT=DATE9.,
					r.origin,
					r.dest,
					SUM(r.rev1st, r.revbusiness, r.revecon) - e.expenses AS Profit,
					a.city,
					a.name
		FROM		sasuser.expenses e,
					sasuser.revenue r,
					sasuser.acities a
		WHERE		e.flightid = r.flightid
					AND e.date = r.date
					AND a.code = r.dest
		ORDER BY	r.dest,
					r.flightid,
					r.date;
QUIT;

/* report merged results */
PROC PRINT DATA=sqljoin (OBS=5);
	title "Result of merging three data sets - with SQL join";
	FORMAT Date DATE9.;
RUN;

/* combining data with many-to-many match */
/* combining flight schedule and flight attendant schedule to record flight attendant names against flights */
/* with PROC SQL */
PROC SQL;
	CREATE TABLE flightemps AS
		SELECT	fs.*,
				firstname,
				lastname
		FROM	sasuser.flightschedule fs,
				sasuser.flightattendants fa
		WHERE	fs.empid = fa.empid;
QUIT;

PROC PRINT DATA = flightemps;
	title "Combining data with many-to-many match - with SQL join";
RUN;

/* getting the same answer with match-merge */
DATA flightemp3 (DROP=empnum jobcode);
	SET sasuser.flightschedule;
	DO i = 1 to num;
		SET sasuser.flightattendants (RENAME=(empid=empnum)) NOBS=num POINT=i;
		if empid=empnum THEN OUTPUT;
	END;
RUN;

PROC PRINT DATA = flightemp3;
	title "Combining data with many-to-many match - with match-merge";
RUN;

/* combining summary and detailed data */
/* method 1: create a summary data set then merge with the detailed data */
/* create a summary data set with the total cargo revenue */
PROC MEANS DATA=sasuser.monthsum NOPRINT;
	VAR revcargo;
	OUTPUT OUT=summary SUM=CargoSum;
RUN;
PROC PRINT DATA=summary;
	title "Total cargo revenue";
	FORMAT CargoSum DOLLAR18.2;
RUN;
/* merge into detailed data and calculate percentage revenue per month */
DATA percent1(DROP=CargoSum);
	IF _N_ = 1 THEN SET summary(KEEP=CargoSum);	/* at fisrt iteration read in summary data */
												/* remeber it is preserved in the PDV for all iterations,
												   if not overwritten */
	SET sasuser.monthsum(KEEP=salemon revcargo);
	pctrev = revcargo/cargosum;
	FORMAT pctrev PERCENT6.2;
RUN;
PROC PRINT DATA=percent1 NOOBS;
	title "Percentage revenue per month";
RUN;
/* using the sum statement to do the above in one step */
DATA percent2(DROP=totalrev);
	IF _N_ = 1 THEN DO UNTIL (lastobs);						/* don't forget this is evaulated at end of loop */
		SET sasuser.monthsum (KEEP=revcargo) END=lastobs;
		totalrev + revcargo;								/* calculate the total revenue */
	END;
	SET sasuser.monthsum (KEEP=salemon revcargo);
	pctrev = revcargo/totalrev;
	FORMAT pctrev PERCENT6.2;
RUN;
PROC PRINT DATA=percent1 NOOBS;
	title "Percentage revenue per month (using sum statement)";
RUN;

/* using the KEY= option to combine two data sets where one is much larger than the other */
/* create composite index in temporary copy of the data set */
DATA sale2000 (index=(flightdate = (flightid date)));
	SET sasuser.sale2000;
RUN;

*PROC CONTENTS DATA=sale2000;
*RUN;

DATA profit;
	SET sasuser.dnunder;
	/* the KEY= option requires the values for the index to be populated in the PDV */
	SET sale2000 (KEEP=routeid flightid date rev1st revbusiness revecon revcargo) KEY=flightdate;
	Profit = SUM(rev1st, revbusiness, revecon, revcargo, -expenses);
RUN;

PROC PRINT DATA=profit;
	title "combining data sets with the KEY= option";
	FORMAT rev1st revbusiness revecon revcargo expenses profit DOLLAR16.2;
RUN;

/* use _IORC_ to capture error in last observation */

DATA profit3 flterr;
	SET sasuser.dnunder;
	/* the KEY= option requires the values for the index to be populated in the PDV */
	SET sale2000 (KEEP=routeid flightid date rev1st revbusiness revecon revcargo) KEY=flightdate;
	IF _IORC_ = 0 THEN DO;
		/* if no error, calculate profit */
		Profit = SUM(rev1st, revbusiness, revecon, revcargo, -expenses);
		OUTPUT profit3;		/* output to results data set */
	END;
	ELSE DO;
		_ERROR_=0;			/* clear error flag */
		OUTPUT flterr;		/* output to errors data set */
	END;
RUN;

PROC PRINT DATA=profit3;
	title "combining data sets with the KEY= option (error captured)";
	FORMAT rev1st revbusiness revecon revcargo expenses profit DOLLAR16.2;
RUN;

PROC PRINT DATA=flterr;
	title "combining data sets with the KEY= option (observations with errors)";
	FORMAT rev1st revbusiness revecon revcargo expenses profit DOLLAR16.2;
RUN;
