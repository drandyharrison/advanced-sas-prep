/* Advanced programming for SAS 9 */
/* Chapter 14: Combining data vertically */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

/* Use FILENAME statement to concatenate raw data files */
%LET datadir=/folders/myfolders/sasuser.v94/;
FILENAME qtr1 ("&datadir.month1.dat" "&datadir.month2.dat" "&datadir.month3.dat");

DATA firstqtr;
	INFILE qtr1;	/* qtr1 referenced as a single raw data file */
	INPUT	Flight $
			Origin $
			Dest $
			Date : DATE9.
			RevCargo : COMMA15.2;
RUN;

title "Combine data vertically with FILENAME";
PROC PRINT DATA=firstqtr (FIRSTOBS=45 OBS=55);
	FORMAT	Date : DATE9.
			RevCargo : DOLLAR11.2;
RUN;

/* Combining data vertically with the FILEVAR= option of the INFILE statement */
/* concatenate the current month plus the two previous */
%LET currmnth=11;
DATA quarter;
	DO i = %EVAL(&currmnth-2) TO &currmnth;
		/* use COMPRESS() to remove leading spaces when i < 10 */
		nxtfile = "&datadir.month" || COMPRESS(PUT(i,2.) || ".dat", " ");
		/* read until the last observation, */
		/* prevents the last observation of the 1st and 2nd raw data files being read */
		/* this avoids the DATA step terminating earlier than intended */
		DO UNTIL (lastobs);
			/* temp is an arbitrarily named placeholder */
			INFILE temp FILEVAR=nxtfile END=lastobs;
			INPUT	Flight $
					Origin $
					Dest $
					Date : DATE9.
					RevCargo : COMMA15.2;
			OUTPUT;
		END;
	END;
	STOP;	/* to prevent an infinite loop */
RUN;

title "Combine data vertically with FILEVAR=";
PROC PRINT DATA=quarter (FIRSTOBS=45 OBS=55) LABEL;
	LABEL i='Month';
	FORMAT	Date : DATE9.
			RevCargo : DOLLAR11.2;
RUN;

/* a revised version which uses MONTH() and TODAY() to read the current month and the previous n */
%LET mnth2rd = 3;	/* number of months to read */
DATA quarter2 (DROP=startmnth endmnth);
	startmnth = MONTH(INTNX('month', TODAY(), 1-%EVAL(&mnth2rd)));
	/* use INTX to decrement months accounting for year boundaries (Feb - 2, for example) */
	endmnth = MONTH(TODAY());
	DO i = startmnth TO endmnth;
		/* use COMPRESS() to remove leading spaces when i < 10 */
		nxtfile = "&datadir.month" || COMPRESS(PUT(i,2.) || ".dat", " ");
		/* read until the last observation, */
		/* prevents the last observation of the 1st and 2nd raw data files being read */
		/* this avoids the DATA step terminating earlier than intended */
		DO UNTIL (lastobs);
			/* temp is an arbitrarily named placeholder */
			INFILE temp FILEVAR=nxtfile END=lastobs;
			INPUT	Flight $
					Origin $
					Dest $
					Date : DATE9.
					RevCargo : COMMA15.2;
			OUTPUT;
		END;
	END;
	STOP;	/* to prevent an infinite loop */
RUN;

title "Combine data vertically with FILEVAR= (up to current month)";
PROC PRINT DATA=quarter2 LABEL;
	LABEL i='Month';
	FORMAT	Date : DATE9.
			RevCargo : DOLLAR11.2;
RUN;

/* appending data sets */
/* create local copy of cap2001 */
DATA cap2001;
	SET sasuser.cap2001;
RUN;

PROC APPEND BASE=cap2001 DATA=sasuser.capacity;
RUN;

title "Appended data set";
PROC PRINT DATA=cap2001;
RUN;

/* concatenating multiple data files by reading the files to concatenate from a SAS data set */
/* create the data set of file names */
DATA readit;
	INPUT fname $12.;
	DATALINES;
route1.dat
route2.dat
route3.dat
route8.dat
route9.dat
route10.dat
;
RUN;
/* check read ok */
PROC PRINT DATA=readit NOOBS;
RUN;
/* read in and concatenate data files listed in the readit data set */
DATA newroute (DROP=fname);
	SET readit;
	nxtfile = "&datadir." || fname;
	PUT "Reading " nxtfile;
	INFILE in FILEVAR=nxtfile END=lastfile;
	DO WHILE (lastfile=0);
		INPUT	@1 RouteID $7.
				@8 Origin $3.
				@11 Dest $3.
				@14 Distance 5.
				@19 Fare1st 4.
				@23 FareBusiness 4.
				@27 FareEcon 4.
				@31 FareCargo 5.;
		OUTPUT;
	END;
RUN;

title "Concatenate a list of files read from a data set";
PROC PRINT DATA=newroute NOOBS;
RUN;

/* read in and concatenate data files listed in an external file */
%LET filelst=rawdatafiles.dat;	/* the name of the file containing the list of files */
DATA newroute2 (DROP=readit);
	/* read in the next file to read in */
	INFILE "&datadir.advanced-sas-prep/&&filelst";
	INPUT readit $12.;
	nxtfile = "&datadir." || readit;
	INFILE in FILEVAR=nxtfile END=lastobs;
	DO WHILE (lastobs = 0);
		INPUT	@1 RouteID $7.
				@8 Origin $3.
				@11 Dest $3.
				@14 Distance 5.
				@19 Fare1st 4.
				@23 FareBusiness 4.
				@27 FareEcon 4.
				@31 FareCargo 5.;
		OUTPUT;
	END;
RUN;

title "Concatenate a list of files read from an external file";
PROC PRINT DATA=newroute2 NOOBS;
RUN;
