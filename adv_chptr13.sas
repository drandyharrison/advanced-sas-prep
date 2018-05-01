/* Advanced programming for SAS 9 */
/* Chapter 13: Creating samples and indexes */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

/* Create a 10 observation from a known number of (142) observations */
DATA subset;
	DO pickit = 1 TO 142 BY 15;
		SET sasuser.revenue POINT=pickit;
		OUTPUT;
	END;
	STOP;
RUN;

title "Systematic sample of 10 observations from a known number of observations (142)";
PROC PRINT DATA=subset;
RUN;

/* creating a systematic sample from an unkown number of obseervations */
DATA subset2;
	DO pickit = 1 TO totobs BY 10;
		SET sasuser.revenue NOBS=totobs POINT=pickit;
		OUTPUT;
	END;
	CALL SYMPUT('numobs', TRIM(LEFT(totobs)));
	STOP;
RUN;

title "Systematic sample of observations from a unknown number of observations (&numobs)";
PROC PRINT DATA=subset2;
RUN;

%LET sample=15;	/* the sample size for the next two data sets */

/* creating a random sample with replacement */
DATA rsubset (DROP=sampsize i);
	sampsize = &sample.;
	DO i = 1 TO sampsize;
		pickit = CEIL(totobs * RANUNI(0));
		SET sasuser.revenue NOBS=totobs POINT=pickit;
		OUTPUT;
	END;
	STOP;
RUN;

PROC PRINT DATA=rsubset;
	title "Random sample with replacement";
RUN;

/* Creating a random sample without replacement */
DATA rsubset2 (DROP=obsleft sampsize);
	sampsize = &sample.;				/* the sample size to be created, which is decremented until zero */
	obsleft = totobs;					/* number of observations left in the data set */
	DO WHILE(sampsize > 0);				/* keep going until we have all the samples we want */
		pickit + 1;						/* move to the next observation */
		/* add this observation to sample */
		if RANUNI(0) < sampsize/obsleft THEN DO;
			SET sasuser.revenue POINT=pickit NOBS=totobs;
			OUTPUT;
			sampsize = sampsize - 1;	/* decrement number of observations to add to sample */
		END;
		obsleft = obsleft - 1;
	END;
	STOP;
RUN;

PROC PRINT DATA=rsubset2 HEADING=h LABEL;
	title "Random sample without replacement";
RUN;

/* a simple index on a data set */
DATA simple (INDEX=(division));
	SET sasuser.empdata;
RUN;

/* two simple indexes, the second contains unique values for EmpID */
DATA simple2 (INDEX=(division empid/UNIQUE));
	SET sasuser.empdata;
RUN;

/* a composite index */
DATA composite (INDEX=(EmpDiv=(division empid)));
	SET sasuser.empdata;
RUN;

/* using MSGLEVEL=I to confirm creation of an index */
OPTIONS MSGLEVEL=I;
FILENAME sale2000 "/folders/myfolders/sasuser.v94/sale2000.dat";
DATA sales2000 (INDEX=(origin FlightData=(flightid date)/UNIQUE));
	INFILE	sale2000 DSD;
	INPUT	FlightID $
			RouteID $
			Origin $
			Dest $
			Cap1st
			CapBusiness
			CapEcon
			CapTotal
			CapCargo
			Date
			Pax1st
			PaxBusiness
			PaxEcon
			Rev1st
			RevBusiness
			RevEcon
			SaleMon $
			CargoWgt
			RevCargo;
	FORMAT Date DATE9.;
RUN;

/* delete the origin index and create two new ones */
PROC DATASETS LIBRARY=work NOLIST;
	MODIFY sales2000;
	INDEX DELETE origin;							/* delete an index */
	INDEX CREATE flightid;							/* create a simple index */
	INDEX CREATE FromTo=(origin dest);				/* create a composite index */
QUIT;

/* creating and deleting indexes with PROC SQL */
PROC SQL;
	CREATE INDEX origin ON sales2000(origin);		/* create a simple index */
QUIT;

PROC SQL;
	CREATE INDEX ToFrom ON sales2000(dest, origin);	/* create a composite index */
	DROP INDEX origin FROM sales2000;				/* delete an index */
QUIT;

/* list the indexes and descriptor portion of the dataset sales2000 */
title "Contents of the data set sales2000";
PROC CONTENTS DATA=sales2000;
RUN;

title "Contents of the work library";
PROC CONTENTS DATA=work._ALL_;
RUN;

/* copy the data set sales2000 from work to sasuser */
/* I don't have write permission for sasuser, so this won't work */
/*
PROC COPY OUT=sasuer IN=work;
	SELECT sales2000;
RUN;
*/

/* renaming a data set */
PROC DATASETS LIB=work NOLIST;
	CHANGE sales2000=revenue2k;
RUN;

/* renaming a variable */
PROC DATASETS LIB=work NOLIST;
	MODIFY revenue2k;
	RENAME flightid=FlightNum;
RUN;