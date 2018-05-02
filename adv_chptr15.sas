/* Advanced programming for SAS 9 */
/* Chapter 15: Combining data horizaontally */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);

/* Use FILENAME statement to concatenate raw data files */
%LET datadir=/folders/myfolders/sasuser.v94/;
