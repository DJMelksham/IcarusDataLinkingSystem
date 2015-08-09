/**********************************************************************************
* PROGRAM: Observation to macro facility                                          *
* VERSION: 1.0                                                                    *
* AUTHOR:  Damien John Melksham.                                                  *
* DATE:    12/07/2012                                                             *
***********************************************************************************
* PURPOSE: This program obtains the selected variables from an observation        *
*          in a data set.                                                         *
*                                                                                 *
***********************************************************************************
* COMMENTS: The program returns variables from an observation in a data set.      *
*           It requires three arguments:                                          *
*                                                                                 *
*           1) A data set                                                         *
*           2) The variables in the data set to be returned                       *
*           3) The observation number to return the variables from                * 
*                                                                                 *
*           It has a dependency on the varlistfromdset macro.                     *
*																				  *
*           Apologies for the relative obtuseness in the naming of the variables, *
*           but given the actions of this macro, i believed it best to chose      *
*           some variable names that are unlikely to be duplicated                *
*           by being present in the data sets that people might be working on.    *
*                                                                                 *
**********************************************************************************/

%macro obtomacro(_DJM_rare_dset,_DJM_rare_varlist,_DJM_rare_startnum);

%local _DJM_rare_id _DJM_rare_i _DJM_rare_rc _DJM_rare_close _DJM_rare_result _DJM_rare_tempy %varlistfromdset(&_DJM_rare_dset);

%let _DJM_rare_id=%sysfunc(open(&_DJM_rare_dset));
%syscall set(_DJM_rare_id);
%let _DJM_rare_rc=%sysfunc(fetchobs(&_DJM_rare_id,&_DJM_rare_startnum));
%let _DJM_rare_close=%sysfunc(close(&_DJM_rare_id));

%let _DJM_rare_I=1;

	%do %while(%scan(&_DJM_rare_varlist,&_DJM_rare_I,%str( )) ne %str( ));
	
		%let _DJM_rare_tempy=%scan(&_DJM_rare_varlist,&_DJM_rare_I,%str( ));
		%let _DJM_rare_result=&_DJM_rare_result &&&_DJM_rare_tempy;
		%let _DJM_rare_I = %eval(&_DJM_rare_I+1);
	%end;

&_DJM_rare_result

%mend obtomacro;