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
RUN;

title "Raw order data";
PROC PRINT DATA=orders NOOBS;
	VAR	OrderID OrderDate CustomerID  
		City State ZipCode ProductID  
		Sales Quantity Discount Profit;
RUN;

/* Creating a summary report the includes the number of 