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
      ,CASE
			WHEN 
				[AbsDrgDiagnoses].[Diagnosis] IN (
					'E66.1','E66.01','E66.09','E66.2','E66.8','E66.9','Z68.30','Z68.31','Z68.32','Z68.33',
					'Z68.34','Z68.35','Z68.36','Z68.37','Z68.38','Z68.39','Z68.41','Z68.42','Z68.43',
					'Z68.44','Z68.45','O99.214','O99.215','O99.210','O99.211','O99.212','O99.213'
				) THEN '1'
			ELSE '0'
	   END																														 AS obesity			
	  ,CASE
			WHEN 
				[AbsDrgDiagnoses].[Diagnosis] IN (
					'O75.3','O03.37','O03.87','O04.87','O07.37','O08.82','O85','O86.04','O98.811','O98.812','O98.813',
					'O98.819','O98.82','O98.83','O98.911','O98.912','O98.913','O98.919','O98.92','O98.93','O98.511',
					'O98.512','O98.513','O98.519','O98.52','O98.53'
				) THEN '1'
			ELSE '0'
	   END																														 AS pregnancy_status		
      ,CASE
			WHEN 
				[AbsDrgDiagnoses].[Diagnosis] IN (
					'J09.X1','J09.X2','J09.X3','J09.X9','J10.00','J10.01','J1008','J10.1','J10.2','J10.81','J10.82',
					'J10.83','J10.89','J11.0','J11.00','J11.08','J11.1','J11.2','J11.8','J11.81','J11.82','J11.83','J11.89'
				) THEN '1'
			ELSE '0'
	   END																														 AS flu_positive
	  ,CASE
			WHEN 
				[AbsDrgDiagnoses].[Diagnosis] IN (
					'3E1.M39Z','5A1.D70Z','5A1.D80Z','5A1.D90Z'
				) THEN '1'
			ELSE '0'
	   END																														 AS dialysis_treatment
	  ,CASE
			WHEN 
				[AbsDrgDiagnoses].[Diagnosis] IN (
					'3E1.M39Z','5A1.D70Z','5A1.D80Z','5A1.D90Z'
				) THEN '1'
			ELSE '0'
	   END																														 AS dialysis_treatment

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
		 FROM [CH_MTLIVE].[dbo].[LabSpecimenTests] AS CovidTests
		 WHERE TestPrintNumberID IN ('800.4051','100.0030','800.1036')
		) AS CovidTests ON bar.[VisitID] = CovidTests.[VisitID]
  
 
  WHERE   [ServiceDateTime]                  IS NOT NULL
  AND     [BirthDateTime]                    IS NOT NULL
  AND     bar.[DischargeDateTime]            IS NOT NULL
  AND     QueryID = 'ETHNICITY'
  AND     [UnitNumber]			             IS NOT NULL
  AND     CONVERT(DATE,[ServiceDateTime])    >=          '2022-01-01'

  ORDER BY bar.[VisitID]
