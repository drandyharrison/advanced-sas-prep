/* Advanced programming for SAS 9 */
/* Chapter 18: Modifying SAS data sets and tracking changes */

/* define footnote for all plots using automatic macro variables */
%LET foot2_arg = color=blue italic;
%LET foot2_val = "Prepared by Andy Harrison [(c) &sysdate9.] at &systime on &sysday";
footnote &foot2_arg &foot2_val;

/* print working directory to log */
%PUT Current directory: %SYSGET(PWD);
%LET datadir=/folders/myfolders/sasuser.v94/advanced-sas-prep/;

/* an airline wants to give passengers more leg room */
/* decrease number of seats in business and economy */
/* create local copy of capacity data set */
DATA capacity;
	SET sasuser.capacity;
RUN;
/* set % reduction levels for business and economy */
%LET redbuss = 0.9;
%LET redecon = 0.95;
/* number of observations when just inspecting data set */
%LET inspobs = 5;
/* inspect original capacity */
title "original capacity";
PROC PRINT DATA=capacity (OBS=&inspobs) NOOBS;
RUN;
/* modify capacity */
DATA capacity;
	MODIFY capacity;
	CapEcon = INT(CapEcon * &redecon);
	CapBusiness = INT(CapBusiness * &redbuss);
RUN;
title "new capacity";
PROC PRINT DATA=capacity (OBS=&inspobs) NOOBS;
RUN;
/* Now suppose some of the route IDs need to be changed */
DATA capacity;
	MODIFY	capacity
			sasuser.newrtnum;	/* new route IDs */
	BY FlightID;				/* match on flight ID */
RUN;
title "transactional data";
PROC PRINT DATA=sasuser.newrtnum;
RUN;
title "revised routes";
PROC PRINT DATA=capacity (OBS=&inspobs) NOOBS;
RUN;
/* update and correct 1999 cargo date */
/* create a local copy of the cargo data with the composite index FlghtDte */
DATA cargo99 (INDEX=(FlghtDte=(FlightId Date)));
	SET sasuser.cargo99;
RUN;
/* inspect master data */
title "master cargo data";
PROC PRINT DATA=cargo99 (OBS=&inspobs) NOOBS;
RUN;
/* update cargo data */
DATA cargo99;
	/* correct cargo data */
	SET sasuser.newcgnum (RENAME=(capcargo=newCapCargo cargowgt=newCargoWgt cargorev=newCargoRev));
	MODIFY cargo99 KEY=FlghtDte;	/* FlghtDte is a composite index of FlightId and Date */
	CapCargo = newCapCargo;
	CargoWgt = newCargoWgt;
	CargoRev = newCargoRev;
RUN;
title "corected cargo data";
PROC PRINT DATA=cargo99 (OBS=&inspobs) NOOBS;
RUN;
/* applying constraints to a data set with PROC DATASETS */
/* for a data set containing route information and passenger information */
/* create a local copy of capinfo */
DATA capinfo;
	SET sasuser.capinfo;
RUN;
/* initiate an audit trail on capinfo */
PROC DATASETS NOLIST;
	AUDIT capinfo;
	INITIATE;
	LOG	DATA_IMAGE=NO		/* don't store D* updates */
		BEFORE_IMAGE=NO;	/* don't store DR ops */
							/* so only errors */
	/* add some user variables */
	USER_VAR	who $20 LABEL='Who made the change'
				why $20 LABEL="Why they made the change";
RUN;
QUIT;
PROC DATASETS NOLIST;
	MODIFY capinfo;
	/* define integrity constraint to ensure routeid is a primary key - which means it's also
	   not missing and unique */
	IC CREATE PKIDInfo=PRIMARY KEY(routeid)
		MESSAGE='You must supply a unique route ID';
	/* define an integrity constraint to ensure 1st capacity is less than business capacity
	   provided business class capacity is not missing */
	IC CREATE Class1=CHECK(WHERE=(cap1st < capbusiness or capbusiness=.))
		MESSAGE="1st class capacity cannot exceed business capacity";
QUIT;
/* try to modify the data that violates the integrity constraints */
DATA capinfo;
	MODIFY capinfo;
	cap1st = 3 * cap1st;
RUN;
/* view the integrity constraints */
title "capinfo with integrity constraints";
PROC DATASETS NOLIST;
	CONTENTS DATA=capinfo;
RUN;
/* remove the integrity constraints */
PROC DATASETS NOLIST;
	MODIFY capinfo;
	IC DELETE PKIDInfo;
	IC DELETE Class1;
RUN;
/* confirm deleted */
title "capinfo with integrity constraints removed";
PROC DATASETS NOLIST;
	CONTENTS DATA=capinfo;
RUN;
/* read audit file */
title "audit trail";
PROC PRINT DATA=capinfo (TYPE=AUDIT);
RUN;
/* terminate the audit trail */
PROC DATASETS NOLIST;
	AUDIT capinfo;
	TERMINATE;
QUIT;
/* examples of generation data sets */
/* create a local copy of caregorev */
/* enable generation data sets for a maximum of four generations */
DATA cargorev;
	SET sasuser.cargorev  (GENMAX=4);
RUN;