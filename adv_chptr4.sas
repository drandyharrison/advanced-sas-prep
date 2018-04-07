/* Advanced programming for SAS 9 */
/* Chapter 4: Combining tables vertically */

/* calculate create date for inclusion in footnote */
%let date = %sysfunc(today(), date11.);

/* define footnote for all plots */
footnote "Prepared by Andy Harrison [(c) &date.]";
