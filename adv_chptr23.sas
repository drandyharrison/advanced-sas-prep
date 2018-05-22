/* Advanced programming for SAS 9 */
/* Chapter 23: Selecting efficient sorting strategies */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);
%LET datadir=/folders/myfolders/sasuser.v94/;
%LET numrows=5000;

/* read in some sample superstore data (from https://community.tableau.com/docs/DOC-1236) */
DATA orders (DROP=CustomerName Segment Country ProductName);
	/* to only read first N observations use OBS= option with INFILE */
	/* there's a 3MB limit on results */
	INFILE "&datadir.superstore.csv" DSD OBS=&numrows.;
	INPUT	row
			OrderID :$12.
			OrderDate :DDMMYY10.
			ShipDate :DDMMYY10.
			ShipMode :$32.
			CustomerID :$32.
			CustomerName :$32.
			Segment :$32.
			Country :$32.
			City :$32.
			State :$32.
			ZipCode
			Region :$32.
			ProductID :$32.
			Category :$32.
			SubCategory :$32.
			ProductName :$128.
			Sales :$32.
			Quantity
			Discount
			Profit;
	FORMAT OrderDate ShipDate DATE11.;
	IF Segment = "Consumer" AND Country = "United States";
	year = YEAR(OrderDate);
RUN;

title "Raw order data (sample)";
PROC PRINT DATA=orders (OBS=25) NOOBS;
	VAR	OrderID OrderDate Year CustomerID  
		City State ZipCode ProductID  
		Sales Quantity Discount Profit;
RUN;

/* Creating a summary report the includes the number of orders for each quarter */
/* Define format for quarters */
PROC FORMAT;
	VALUE qtrfmt
		'01JAN2014'd - '31MAR2014'd = '14Q1'
		'01APR2014'd - '30JUN2014'd = '14Q2'
		'01JUL2014'd - '30SEP2014'd = '14Q3'
		'01OCT2014'd - '31DEC2014'd = '14Q4'
		'01JAN2015'd - '31MAR2015'd = '15Q1'
		'01APR2015'd - '30JUN2015'd = '15Q2'
		'01JUL2015'd - '30SEP2015'd = '15Q3'
		'01OCT2015'd - '31DEC2015'd = '15Q4'
		'01JAN2016'd - '31MAR2016'd = '16Q1'
		'01APR2016'd - '30JUN2016'd = '16Q2'
		'01JUL2016'd - '30SEP2016'd = '16Q3'
		'01OCT2016'd - '31DEC2016'd = '16Q4'
		'01JAN2017'd - '31MAR2017'd = '17Q1'
		'01APR2017'd - '30JUN2017'd = '17Q2'
		'01JUL2017'd - '30SEP2017'd = '17Q3'
		'01OCT2017'd - '31DEC2017'd = '17Q4'
		OTHER = "-";
RUN;

PROC SORT DATA=orders;
	BY OrderDate;
RUN;

DATA quarters (KEEP=count OrderDate RENAME=(OrderDate=Quarter));
	SET orders;
	FORMAT OrderDate qtrfmt.;
	/* GROUPFORMAT means FIRST and LAST are created based on the formated values not the internal ones */
	BY OrderDate GROUPFORMAT;
	IF FIRST.OrderDate THEN count = 0;
	Count + 1;
	IF LAST.OrderDate;
RUN;

title "Number of orders by Quarter (with GROUPFORMAT)";
PROC PRINT DATA=quarters NOOBS;
RUN;

/* now without GROUPFORMAT */
DATA quarters2 (KEEP=count OrderDate RENAME=(OrderDate=Quarter));
	SET orders;
	FORMAT OrderDate qtrfmt.;
	BY OrderDate;
	IF FIRST.OrderDate THEN count = 0;
	Count + 1;
	IF LAST.OrderDate;
RUN;

title "Number of orders by Quarter (without GROUPFORMAT)";
PROC PRINT DATA=quarters2 NOOBS;
RUN;
