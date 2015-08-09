/**********************************************************************************
* PROGRAM: ESTIMATE SIZE                                                          *
* VERSION: 1.0                                                                    *
* AUTHOR:  DAMIEN JOHN MELKSHAM                                                   *
* DATE:    06/08/2012                                                             *
***********************************************************************************
* PURPOSE: ESTIMATES THE SIZE OF A DATA SET BASED UPON THE LENGTH OF VARIABLES    *
*          AND THE NUMBER OF OBSERVATIONS                                         *
***********************************************************************************
* COMMENTS: USES A HOST OF THE OTHER UTILITY MACROS                               *
**********************************************************************************/

%macro EstimateSize(Dataset,Variables);
%local I reclength observations size;
%let reclength=%findreplace(%Varlengths(&Dataset,&Variables),%STR( ),%STR(+));
%let observations=%numofobs(&DataSet);
%let size=%EVAL((&reclength)*&observations);
&size
%mend EstimateSize;