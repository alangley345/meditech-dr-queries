DECLARE @facility VARCHAR(25);
set @facility = 'facility_identifier'

DECLARE @transfer_facility_id_receiving VARCHAR(50);
set @transfer_facility_id_receiving = 'transfer_facility_id_receiving'

DECLARE @transfer_facility_id_sending VARCHAR(50);
set @transfer_facility_id_sending = 'transfer_facility_id_sending'


SELECT ALL 
       @facility																												 AS facility_identifier
	  ,CONCAT(SUBSTRING([Name],0,5),SUBSTRING([Name],CHARINDEX(',',[Name],0)+1,2),RIGHT([UniquePublicIdentifier],4))			 AS unique_personal_identifier
	  ,CONVERT(DATE,[ServiceDateTime])																							 AS arrival_dt
      ,CONVERT(DATE,[BirthDateTime])																							 AS date_of_birth
	  ,CONVERT(DATE,bar.[DischargeDateTime])																					 AS discharge_dt
	  ,CASE	
			WHEN [Response] = 'H'                  then 'E1'
			WHEN [Response] = 'M'                  then 'E1.02'
			WHEN [Response] = 'MA'                 then 'E1.02.001'
			WHEN [Response] = 'CH'                 then 'E1.02.003'
			WHEN [Response] = 'PR'				   then 'E1.06'
			WHEN [Response] = 'C'                  then 'E1.07'																 
			WHEN [Response] = 'NH'			       then 'E2'																	 																		 
			ELSE 'E9'																											 
	   END																														 AS ethnicity	
	  ,[UnitNumber] as medical_record_number																					 
	  ,[UnitNumber] as patient_control_number																					 
	  ,CASE																														 
			WHEN [RaceID] IN ('I','N')           then 'R1'																		 
			WHEN [RaceID] IN ('A','C','J','K')   then 'R2' 																		 
			WHEN [RaceID] = 'AI'                 then 'R2.01'																	 
			WHEN [RaceID] = 'F'                  then 'R2.08'																	 
			WHEN [RaceID] = 'B'                  then 'R3'																		 
			WHEN [RaceID] = 'W'                  then 'R4.01.001'																 
			WHEN [RaceID] = 'S'                  then 'R4.01.002'																 
			WHEN [RaceID] IN ('CH','G')          then 'R4.02.001'																 
			WHEN [RaceID] = 'OP'			     then 'R4.04'																	 
			WHEN [RaceID] = 'W'                  then 'R5'																		 
			ELSE 'R9'																											 
	   END																														 AS race
      ,CASE																													 
			WHEN  [ArrivalID] = 'OH'      then '1'
			ELSE '0'
	   END																														 AS transferred_in	
	  ,CASE																													 
			WHEN  [DispositionID] = 'OHOSP'      then '1'
			ELSE '0'
	   END																														 AS transferred_out
	  ,@transfer_facility_id_receiving																							 AS transfer_facility_id_receiving
	  ,@transfer_facility_id_sending																							 As transfer_facility_id_sending
	  ,CASE
			WHEN ResultRW IN ('DETECTED','Detected','Positive','Positive') THEN '1'
			ELSE '0'
	   END																														 AS history_covid
	  ,CASE
			WHEN 
				ResultRW IN ('DETECTED','Detected','Positive','Positive') THEN ResultDateTime
			ELSE NULL
	   END																														 AS history_covid_dt					
      ,[AbsDrgDiagnoses].[Diagnosis]																							 AS obesity			
	  

-------------------------------------------------------------------------------------------------------------------------------------------------------
  FROM [CH_MTLIVE].[dbo].[BarVisits]																							 AS bar

  JOIN [CH_MTLIVE].[dbo].[AbsDrgDiagnoses]  ON bar.[VisitID] = [AbsDrgDiagnoses].[VisitID]                                       
  JOIN [CH_MTLIVE].[dbo].[AdmVisitQueries]  ON bar.[VisitID] = [AdmVisitQueries].[VisitID]
  JOIN [CH_MTLIVE].[dbo].[AdmDischarge]     ON bar.[VisitID] = [AdmDischarge].[VisitID]
  JOIN [CH_MTLIVE].[dbo].[AdmittingData]    ON bar.[VisitID] = [AdmittingData].[VisitID]

  --COVID DATA
  JOIN (SELECT ALL [VisitID] AS VisitID
		,TestPrintNumberID   AS TestPrintNumberID
		,ResultRW		     AS ResultRW
		,ResultDateTime      AS ResultDateTime
		 FROM [CH_MTLIVE].[dbo].[LabSpecimenTests] as CovidTests
		 WHERE TestPrintNumberID IN ('800.4051','100.0030','800.1036')
		) AS CovidTests ON bar.[VisitID] = CovidTests.[VisitID]
  
 
  WHERE   [ServiceDateTime]          IS NOT NULL
  AND   [BirthDateTime]            IS NOT NULL
  AND   bar.[DischargeDateTime]    IS NOT NULL
  AND   QueryID = 'ETHNICITY'
  AND   [UnitNumber]			   IS NOT NULL
  AND   CONVERT(DATE,[ServiceDateTime])  >= '2022-01-01'
  AND   [AbsDrgDiagnoses].Diagnosis like '%E66%'

  ORDER BY bar.[VisitID],(CASE
			WHEN ResultRW IN ('DETECTED','Detected','Positive','Positive') THEN '1'
			ELSE '0'
	   END	)
