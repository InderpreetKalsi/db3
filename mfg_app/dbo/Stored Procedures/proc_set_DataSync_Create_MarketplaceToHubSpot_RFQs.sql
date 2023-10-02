

/*
-- SELECT TOP 101 [rfq number], [MFG Discipline], [MFG 1st Discipline],[MFG 2nd Discipline] ,* FROM DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs
*/

CREATE PROCEDURE [dbo].[proc_set_DataSync_Create_MarketplaceToHubSpot_RFQs]
AS
BEGIN
	DECLARE @RfqRfqQuoteLink		VARCHAR(4000)
	DECLARE @PageLink VARCHAR(25) = '&quotes=Quotes'				  

	IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @RfqRfqQuoteLink = 'https://uatapp.mfg.com/#/rfq/rfqdetail?rfqId='
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @RfqRfqQuoteLink = 'https://app.mfg.com/#/rfq/rfqdetail?rfqId='
	END
	ELSE IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @RfqRfqQuoteLink = 'https://qaapp.mfg.com/#/rfq/rfqdetail?rfqId='
	END
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #tmp_inserted_rfq_id  
	DROP TABLE IF EXISTS #tmp_rfq_discipline  
	DROP TABLE IF EXISTS #tmp_rfq_materials
	DROP TABLE IF EXISTS #tmp_mfg_rfq_not_exists

	DECLARE @HoursDifferenceBetweenUTCandEST  INT
	 
	SET @HoursDifferenceBetweenUTCandEST  = 
	(
		CASE	
			WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-05:00' THEN -5
			WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-04:00' THEN -4
		END
	)
	   
   /* load RFQs discipline_level*/    --- childid  -- [name]
   SELECT    
    mr.rfq_id as rfq_num  
    , (SELECT [name]  FROM dbo.fn_rfq_discipline (mrp.part_category_id, 0))  as discipline_level0  
    , (SELECT [name]  FROM dbo.fn_rfq_discipline (mrp.part_category_id, 1))  as discipline_level1  
    , (SELECT [name]  FROM dbo.fn_rfq_discipline (mrp.part_category_id, 2))  as discipline_level2 
   INTO #tmp_rfq_discipline   
   FROM   
   mp_companies mcom (NOLOCK)  
   JOIN mp_contacts mcon (NOLOCK) on mcom.company_id = mcon.company_id  
   JOIN mp_rfq mr (NOLOCK) on mcon.contact_id = mr.contact_id  
   LEFT JOIN mp_rfq_parts mrp (NOLOCK) on mr.rfq_id = mrp.rfq_id  
   LEFT JOIN mp_parts mp  (NOLOCK) on mrp.part_id = mp.part_id  
   /* */  
 

	/* Fetch RFQs id which are not rxisted into hubspot data */
		 SELECT rfq_id
		INTO #tmp_inserted_rfq_id
		 FROM  mp_rfq(NOLOCK) a
		 WHERE NOT EXISTS (
							SELECT [Rfq Number]
						    FROM DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs(NOLOCK) b  
						    WHERE b.[Rfq Number] = a.rfq_id 
						  )
	  ----AND a.rfq_id between 1193950  and 1194049 ---- this condition remove later
 	/* */
	 
	 
	/* fetching mfg rfq details which are not in zoho table zoho_rfq*/   
	BEGIN
    SELECT    
		a.rfq_id, ISNULL(a.rfq_name,CONVERT(VARCHAR(500),a.rfq_id)) rfq_name 
		,a.rfq_description ,  a.contact_id ,j.assigned_sourcingadvisor  
		,a.rfq_status_id [rfqstatus]
		--,Quotes_needed_by [CloseDate]
		,
		(
		CASE 			
			WHEN rfq_pref_manufacturing_location_id = 4 THEN  CONVERT(datetime,DATEADD(MINUTE,-00,DATEADD(HOUR,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			WHEN rfq_pref_manufacturing_location_id = 5 THEN  CONVERT(datetime,DATEADD(MINUTE,-00,DATEADD(HOUR,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			WHEN rfq_pref_manufacturing_location_id = 6 THEN  CONVERT(datetime,DATEADD(MINUTE,-00,DATEADD(HOUR,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			WHEN rfq_pref_manufacturing_location_id = 7 THEN  CONVERT(datetime,DATEADD(MINUTE,-00,DATEADD(HOUR,@HoursDifferenceBetweenUTCandEST,quotes_needed_by ))) 
			WHEN rfq_pref_manufacturing_location_id = 2 THEN  CONVERT(datetime,DATEADD(HOUR,+2,quotes_needed_by )) 	
			WHEN rfq_pref_manufacturing_location_id = 3 THEN  CONVERT(datetime,DATEADD(MINUTE,+30,DATEADD(HOUR,+5,quotes_needed_by )))  
			ELSE quotes_needed_by
		END
		) [CloseDate] 		
		,rfq_guid,release_date,rfq_part_count,rfq_number_of_quotes,e.first_name + ' ' + e.last_name as buyer_name  
		,rfq_pref_manufacturing_location_id  
		,g.discipline_level0  
		,h.discipline_level1  
		,i.discipline_level2  
		,e.company_id  
		,CASE WHEN a.RfqEncryptedId IS NOT NULL THEN 
				CONCAT( @RfqRfqQuoteLink, REPLACE(REPLACE( a.RfqEncryptedId ,'+','%2B'),'=','%3D'),@PageLink) 
				ELSE
				NULL
				END AS [RfqQuoteLink]
		,CASE WHEN om.IsExistsInOrderManagement = 1 AND om.rfq_status_id = 6 THEN 
			CONCAT( @RfqRfqQuoteLink, REPLACE(REPLACE( a.RfqEncryptedId ,'+','%2B'),'=','%3D'),'&order=Order') 
			ELSE NULL
			END AS [RfqReshapeOrderLink]
    INTO #tmp_mfg_rfq_not_exists    
    FROM mp_rfq (NOLOCK) a    
    LEFT JOIN (SELECT rfq_id , MAX(status_date) release_date FROM mp_rfq_release_history(NOLOCK) GROUP BY rfq_id ) b  on b.rfq_id = a.rfq_id     
    LEFT JOIN (SELECT rfq_id , COUNT(rfq_part_id) rfq_part_count FROM mp_rfq_parts(NOLOCK) GROUP BY rfq_id ) c  on c.rfq_id = a.rfq_id  
    LEFT JOIN (SELECT rfq_id , COUNT(contact_id) rfq_number_of_quotes FROM  mp_rfq_quote_supplierquote(NOLOCK) WHERE is_quote_submitted = 1 GROUP BY rfq_id ) d on d.rfq_id = a.rfq_id    
    LEFT JOIN mp_contacts(NOLOCK) e on e.contact_id =  a.contact_id  
    LEFT JOIN  
   (      
    SELECT DISTINCT  abc.rfq_id as rfq_id   
    ,CASE WHEN cnt = 1 then b.rfq_pref_manufacturing_location_id ELSE 7 END AS rfq_pref_manufacturing_location_id  
     FROM (  
      SELECT  rfq_id    
      ,COUNT(rfq_pref_manufacturing_location_id) cnt  
      FROM mp_rfq_preferences   (NOLOCK) 
      GROUP BY rfq_id    
    ) abc  JOIN mp_rfq_preferences b on abc.rfq_id = b.rfq_id  
   ) f on f.rfq_id = a.rfq_id  
     LEFT JOIN   
   (  
    SELECT   
     mr.rfq_id   
     ,REPLACE (
	 STUFF((SELECT DISTINCT ';' +  CONVERT(varchar(max),discipline_level0 )  
    FROM #tmp_rfq_discipline  
    WHERE rfq_num = mr.rfq_id  
    FOR XML PATH('')), 1, 1, '') 
	,'&amp;','&')
	AS discipline_level0  
    FROM mp_rfq mr  
   ) g on g.rfq_id = a.rfq_id  
   LEFT JOIN   
   (  
    SELECT   
     mr1.rfq_id   
	 ,REPLACE (
     STUFF((SELECT DISTINCT ';' +  CONVERT(varchar(max),discipline_level1 )  
    FROM #tmp_rfq_discipline  
    WHERE rfq_num = mr1.rfq_id  
    FOR XML PATH('')), 1, 1, '') 
	,'&amp;','&')
	AS discipline_level1  
    FROM mp_rfq mr1  
   ) h on h.rfq_id = a.rfq_id  
   LEFT JOIN   
   (  
    SELECT   
     mr2.rfq_id   
	 ,REPLACE (
     STUFF((SELECT DISTINCT ';' +  CONVERT(varchar(max),discipline_level2 )  
    FROM #tmp_rfq_discipline  
    WHERE rfq_num = mr2.rfq_id  
    FOR XML PATH('')), 1, 1, '') 
	,'&amp;','&')
	AS discipline_level2  
    FROM mp_rfq mr2  
   ) i on i.rfq_id = a.rfq_id  
   LEFT JOIN  
    (   
    SELECT a1.company_id,a1.assigned_sourcingadvisor  
    FROM mp_companies (NOLOCK) a1  
    JOIN mp_contacts (NOLOCK) b1 on a1.Assigned_SourcingAdvisor = b1.contact_id  
    ) j on  j.company_id = e.company_id  
	LEFT JOIN 
	(
	SELECT  a.Rfq_Id ,a.rfq_status_id ,
	CASE WHEN b.RfqId is null THEN 0 ELSE 1 END AS IsExistsInOrderManagement
	FROM   mp_rfq (NOLOCK) a 
	LEFT JOIN mpordermanagement(NOLOCK) b ON b.RfqId = a.rfq_id
	) om  ON om.rfq_id = a.rfq_id
    WHERE    a.rfq_id in     
    (    
     SELECT rfq_id FROM #tmp_inserted_rfq_id (NOLOCK)
    )    
	AND a.contact_id IS NOT NULL 

	/*
	Insertd records into HubSpotRFQs
	*/
	INSERT INTO datasync_marketplacehubspot.dbo.hubspotrfqs
            ([rfq number],
             [rfq name],
             [buyer id],
             [rfq description],
             [rfq close date],
             [assigned engineer],
             [rfq buyer status id],
             [vision link],
             [rfq release date],
             [part count],
             [number of quotes],
             [buyer name],
             [mfg discipline],
             [mfg 1st discipline],
             [mfg 2nd discipline],
             [region],
             [mfg legacy rfq id],
             [created date],
             [synctype],
             [issynced],
			 [Rfq Quote Link],
			 [Rfq Reshape Order Link]
			 )
	SELECT rfq_id,
       rfq_name,
       contact_id,
       rfq_description,
       closedate,
       assigned_sourcingadvisor,
       rfqstatus,
       rfq_guid,
       release_date,
       rfq_part_count,
       rfq_number_of_quotes,
       buyer_name,
       discipline_level0,
       discipline_level1,
       discipline_level2,
       rfq_pref_manufacturing_location_id,
       rfq_id,
       Getutcdate(),
       1 synctype,
       0 issync,
	   [RfqQuoteLink],
	   [RfqReshapeOrderLink]
	FROM   #tmp_mfg_rfq_not_exists 
 

	/* Update ALL -> Hubspot - RFQ - Part Materials Sync up for all existing records into HubSpotRFQs table */
		SELECT DISTINCT 
			A.RFQ_ID 
			,D.MATERIAL_NAME_EN AS MATERIAL  
		INTO #tmp_rfq_materials
		FROM MP_RFQ				A (NOLOCK) 
		JOIN MP_RFQ_PARTS		B (NOLOCK) ON A.RFQ_ID = B.RFQ_ID
		JOIN MP_MST_MATERIALS	D (NOLOCK) ON B.MATERIAL_ID = D.MATERIAL_ID

	 
		UPDATE A	
			SET 
				a.[Rfq Materials] = B.MATERIALS
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs A  (NOLOCK) 
		JOIN
		(
			SELECT DISTINCT
			A.RFQ_ID 
			,STUFF((SELECT ', ' + CAST(MATERIAL AS VARCHAR(MAX)) [text()]
					 FROM #tmp_rfq_materials 
					 WHERE RFQ_ID = A.RFQ_ID
					 FOR XML PATH(''), TYPE)
					.value('.','NVARCHAR(MAX)'),1,2,' ') MATERIALS
 
			FROM #tmp_rfq_materials A
		) B ON A.[Rfq Number] = B.RFQ_ID
		WHERE  LEN(ISNULL(A.[Rfq Materials],''))  != LEN(B.MATERIALS)
		AND A.[Rfq Number] IN (select rfq_id from #tmp_inserted_rfq_id) ---- this condition used for only updated newly inserted rfq 

		 
 

	/**/


	END

END
