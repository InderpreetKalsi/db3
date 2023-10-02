
/*
 
	M2-4750 Hubspot - Add an RFQ data update sync -DB

-- SELECT top 10 [rfq number], [MFG Discipline], [MFG 1st Discipline],[MFG 2nd Discipline] ,* FROM DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs
 
*/

CREATE PROCEDURE [dbo].[proc_set_DataSync_Update_MarketplaceToHubSpot_RFQs]
AS
BEGIN

	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #tmp_rfq_discipline  
	DROP TABLE IF EXISTS #tmp_mfg_rfq_exists 

	DECLARE @HoursDifferenceBetweenUTCandEST  INT
	DECLARE @ModifiedDate AS DATETIME = GETDATE() -- [Modified Date]
	 
	SET @HoursDifferenceBetweenUTCandEST  = 
	(
		CASE	
			WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-05:00' THEN -5
			WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-04:00' THEN -4
		END
	)
	   
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
 
	 
	
	/* fetching mfg rfq details */   
	BEGIN 
		SELECT    
		a.rfq_id, ISNULL(a.rfq_name,CONVERT(VARCHAR(500),a.rfq_id)) rfq_name 
		,a.rfq_description ,  a.contact_id ,j.assigned_sourcingadvisor  
		,rfq_status_id [rfqstatus]
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
    INTO #tmp_mfg_rfq_exists     
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
    WHERE    a.rfq_id in   
		(SELECT [RFQ Number] FROM DataSync_MarketplaceHubSpot.dbo.hubspotrfqs(NOLOCK) WHERE synctype = 1 )    
	
	END

	/* Update HubSpotRFQs data */
	UPDATE hb
	SET hb.[rfq name]           =  mfg.rfq_name  
	  ,hb.[rfq description] 	=  mfg.rfq_description  
	  ,hb.[buyer name] 		    =  mfg.buyer_name  
	  ,hb.[rfq buyer status id] =  mfg.rfqstatus  
      ,hb.[region] 				=  mfg.rfq_pref_manufacturing_location_id  
      ,hb.[part count] 			=  mfg.rfq_part_count  
      ,hb.[number of quotes] 	=  mfg.rfq_number_of_quotes  
      ,hb.[rfq close date] 		=  mfg.closedate  
      ,hb.[rfq release date] 	=  mfg.release_date  
      ,hb.[assigned engineer] 	=  mfg.assigned_sourcingadvisor  
      ,hb.[mfg discipline]    	=  mfg.discipline_level0  
      ,hb.[mfg 1st discipline]  =  mfg.discipline_level1  
      ,hb.[mfg 2nd discipline]  =  mfg.discipline_level2 
	  ,hb.[Modified Date]       =  @ModifiedDate  
	  ,hb.[buyer id]            = mfg.contact_id   ---- Added on 16-Mar-2023
	 FROM #tmp_mfg_rfq_exists mfg 
	 LEFT JOIN DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs(NOLOCK) hb ON mfg.rfq_id = hb.[Rfq Number]
	 WHERE hb.[synctype] = 1   
	 AND
	 (
	 isnull(hb.[rfq name],'')               != mfg.rfq_name  
	 OR isnull(hb.[rfq description],'')		!= mfg.rfq_description  
	 OR isnull(hb.[buyer name],'')		    != mfg.buyer_name  
	 OR isnull(hb.[rfq buyer status id],'') != mfg.rfqstatus  
     OR isnull(hb.[region],'')				!= mfg.rfq_pref_manufacturing_location_id  
     OR isnull(hb.[part count],'')			!= mfg.rfq_part_count  
     OR isnull(hb.[number of quotes],'')	!= mfg.rfq_number_of_quotes  
     OR isnull(hb.[rfq close date],'')		!= mfg.closedate  
     OR isnull(hb.[rfq release date],''  )	!= mfg.release_date  
     OR isnull(hb.[assigned engineer],'')	!= mfg.assigned_sourcingadvisor  
     OR isnull(hb.[mfg discipline],'')		!= mfg.discipline_level0  
     OR isnull(hb.[mfg 1st discipline],'')  != mfg.discipline_level1  
     OR isnull(hb.[mfg 2nd discipline],'')  != mfg.discipline_level2  
     OR isnull(hb.[vision link],'')			!= cast(mfg.rfq_guid as nvarchar(200))  
     OR isnull(hb.[mfg legacy rfq id],'')	!= mfg.rfq_id  
     OR isnull(hb.[buyer id],'')			!= mfg.contact_id  
	 )
	
	 ---- reset hubspot records after update records
	 UPDATE DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs
	 SET IsSynced = 0
	 ,IsProcessed = NULL
	 FROM DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs(NOLOCK)
	 WHERE [Modified Date]  =  @ModifiedDate   

	 /* M2-5024  
		Update -> HubSpotRFQs -> [Rfq Reshape Order Link]
	 */
	 
	  
		UPDATE c
		SET c.[Rfq Reshape Order Link] = CONCAT( @RfqRfqQuoteLink, REPLACE(REPLACE( a.RfqEncryptedId ,'+','%2B'),'=','%3D'),'&order=Order') 
		,IsSynced = 0
		,IsProcessed = NULL
		FROM mp_rfq (NOLOCK) a
		LEFT JOIN (
		SELECT  a.Rfq_Id ,a.rfq_status_id ,
		CASE WHEN b.RfqId is null THEN 0 ELSE 1 END AS IsExistsInOrderManagement
		FROM   mp_rfq (NOLOCK) a 
		LEFT JOIN mpordermanagement(NOLOCK) b ON b.RfqId = a.rfq_id
		) b  on b.rfq_id = a.rfq_id
		LEFT JOIN DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs(NOLOCK) c ON c.[Rfq Number] = a.rfq_id
		WHERE b.IsExistsInOrderManagement = 1
		AND b.rfq_status_id = 6
		AND a.RfqEncryptedId IS NOT NULL
		AND c.[Rfq Reshape Order Link] IS NULL
	
		----Update -> HubSpotRFQs -> [Rfq Quote Link]
		UPDATE b
		SET b.[Rfq Quote Link] = CONCAT( @RfqRfqQuoteLink, REPLACE(REPLACE( a.RfqEncryptedId ,'+','%2B'),'=','%3D'),'&quotes=Quotes') 
		,b.IsSynced = 0
		,b.IsProcessed = NULL
		FROM mp_rfq (NOLOCK) a
		JOIN DataSync_MarketplaceHubSpot.dbo.HubSpotRFQs(NOLOCK) b ON b.[Rfq Number] = a.rfq_id
		WHERE a.RfqEncryptedId IS NOT NULL 
	    AND b.[Rfq Quote Link] IS NULL
	 
	 /* */

END
