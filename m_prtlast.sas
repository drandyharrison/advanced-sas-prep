%MACRO prtlast;
	%IF &SYSLAST NE _NULL_ %THEN %DO;
		PROC PRINT DATA=&SYSLAST (OBS=5);
			title "Listing of &SYSLAST data set";
		RUN;
	%END;
	%ELSE
		%PUT No data set has been created yet.;
%MEND prtlast;