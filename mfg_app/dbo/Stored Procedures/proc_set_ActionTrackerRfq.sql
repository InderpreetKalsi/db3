

/*
EXEC proc_set_ActionTrackerRfq
*/
CREATE PROCEDURE [dbo].[proc_set_ActionTrackerRfq]
AS
BEGIN

	-- M2-3378 Vision - RFQ Tracker - page data -DB

	DECLARE @RfqThumbnails			VARCHAR(1000) 
	DECLARE @RfqDefaultThumbnails	VARCHAR(1000) 

	DROP TABLE IF EXISTS #setActionTrackerRfq
	DROP TABLE IF EXISTS #setActionTrackerRfqUpdate

	
	SET @RfqDefaultThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/3-d-big.png'

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
	END


	SELECT DISTINCT
		A.RFQ_ID
		,A.RFQ_NAME
		,CASE	WHEN A.RFQ_QUALITY = 126 THEN 5
				WHEN A.RFQ_QUALITY = 127 THEN 4
				WHEN A.RFQ_QUALITY = 128 THEN 3
				WHEN A.RFQ_QUALITY = 129 THEN 2
				WHEN A.RFQ_QUALITY = 130 THEN 1
				ELSE NULL
		 END RFQ_QUALITY
		,I.PARENT_RFQ_ID AS ParentRfqId
		,A.CONTACT_ID AS BuyerId
		,B.FIRST_NAME +' '+B.LAST_NAME AS Buyer
		,H.EMAIL AS BuyerEmail
		,C.NAME AS BUYERCOMPANY
		,ISNULL(E.TERRITORY_CLASSIFICATION_NAME,'') AS [LOCATION]
		,F.DESCRIPTION AS [STATUS]
		,A.QUOTES_NEEDED_BY AS RfqCloseDate
		,G.ReleaseDate AS RfqReleaseDate
		,ISNULL(@RfqThumbnails+J.FILE_NAME,@RfqDefaultThumbnails) AS RfqThumbnails
	INTO #setActionTrackerRfq
	FROM MP_RFQ			A (NOLOCK)
	JOIN MP_CONTACTS	B (NOLOCK) ON A.CONTACT_ID = B.CONTACT_ID  AND A.IsMfgCommunityRfq = 0 -- AND B.IsTestAccount = 0
	JOIN MP_COMPANIES	C (NOLOCK) ON B.COMPANY_ID = C.COMPANY_ID
	LEFT JOIN 
	(
		SELECT DISTINCT RFQ_ID , 4  RFQ_PREF_MANUFACTURING_LOCATION_ID 
		FROM MP_RFQ_PREFERENCES (NOLOCK) A WHERE RFQ_ID IN (SELECT RFQ_ID FROM MP_RFQ_PREFERENCES (NOLOCK) GROUP BY RFQ_ID HAVING COUNT(1) > 1)
		UNION 
		SELECT RFQ_ID ,  RFQ_PREF_MANUFACTURING_LOCATION_ID 
		FROM MP_RFQ_PREFERENCES (NOLOCK) A WHERE RFQ_ID IN (SELECT RFQ_ID FROM MP_RFQ_PREFERENCES (NOLOCK) GROUP BY RFQ_ID HAVING COUNT(1) = 1)
	
	) D  ON A.RFQ_ID= D.RFQ_ID
	LEFT JOIN MP_MST_TERRITORY_CLASSIFICATION E (NOLOCK) ON D.RFQ_PREF_MANUFACTURING_LOCATION_ID = E.TERRITORY_CLASSIFICATION_ID
	LEFT JOIN MP_MST_RFQ_BUYERSTATUS F (NOLOCK) ON A.RFQ_STATUS_ID = F.RFQ_BUYERSTATUS_ID
	LEFT JOIN (SELECT RFQ_ID , MAX(STATUS_DATE) ReleaseDate FROM MP_RFQ_RELEASE_HISTORY (NOLOCK) GROUP BY RFQ_ID) G ON A.RFQ_ID= G.RFQ_ID
	JOIN ASPNETUSERS				H (NOLOCK) ON B.USER_ID = H.ID
	LEFT JOIN MP_RFQ_CLONED_LOGS	I (NOLOCK) ON A.RFQ_ID = I.CLONED_RFQ_ID
	LEFT JOIN MP_SPECIAL_FILES		J (NOLOCK) ON A.file_id = J.file_id
	ORDER BY A.RFQ_ID


	-- INSERT & UPDATE RFQ BASIC DETAILS 
	MERGE ActionTrackerRFQ AS TARGET
    USING #setActionTrackerRfq AS SOURCE ON
    (TARGET.RfqId = SOURCE.RFQ_ID)
    WHEN MATCHED
    AND (
            ISNULL(TARGET.RfqName,'')				!= ISNULL(SOURCE.RFQ_NAME,'') 
			OR ISNULL(TARGET.Rating,'')				!= ISNULL(SOURCE.RFQ_QUALITY,'') 
			OR ISNULL(TARGET.BuyerCompany,'')		!= ISNULL(SOURCE.BUYERCOMPANY,'') 
			OR ISNULL(TARGET.[Location],'')         != ISNULL(SOURCE.[LOCATION],'') 
			OR ISNULL(TARGET.[Status],'')           != ISNULL(SOURCE.[STATUS],'')
			OR ISNULL(TARGET.[RfqCloseDate],'')     != ISNULL(SOURCE.[RfqCloseDate],'')
			OR ISNULL(TARGET.[RfqReleaseDate],'')   != ISNULL(SOURCE.[RfqReleaseDate],'') 
			OR ISNULL(TARGET.Buyer,'')				!= ISNULL(SOURCE.Buyer,'') 
			OR ISNULL(TARGET.BuyerEmail,'')			!= ISNULL(SOURCE.BuyerEmail,'') 
			OR ISNULL(TARGET.ParentRfqId,'')		!= ISNULL(SOURCE.ParentRfqId,'') 
			OR ISNULL(TARGET.RfqThumbnails,'')		!= ISNULL(SOURCE.RfqThumbnails,'') 
			OR ISNULL(TARGET.BuyerId,'')			!= ISNULL(SOURCE.BuyerId ,'')	
		)
	THEN
		UPDATE SET
			TARGET.RfqName				= ISNULL(SOURCE.RFQ_NAME,'') 
			,TARGET.Rating				= SOURCE.RFQ_QUALITY 
			,TARGET.BuyerCompany		= ISNULL(SOURCE.BUYERCOMPANY,'') 
			,TARGET.[Location]			= ISNULL(SOURCE.[LOCATION],'') 
			,TARGET.[Status]			= ISNULL(SOURCE.[STATUS],'') 
			,TARGET.[RfqCloseDate]		= ISNULL(SOURCE.[RfqCloseDate],'')
			,TARGET.[RfqReleaseDate]	= ISNULL(SOURCE.[RfqReleaseDate],'') 
			,TARGET.BuyerId				= SOURCE.BuyerId
			,TARGET.Buyer				= ISNULL(SOURCE.Buyer,'') 
			,TARGET.BuyerEmail			= ISNULL(SOURCE.BuyerEmail,'') 
			,TARGET.ParentRfqId			= ISNULL(SOURCE.ParentRfqId,'') 
			,TARGET.RfqThumbnails		= ISNULL(SOURCE.RfqThumbnails,'') 

	WHEN NOT MATCHED BY TARGET 
	THEN 
	INSERT (RfqId,RfqName,Rating,BuyerCompany,[Location],[Status],[RfqCloseDate],[RfqReleaseDate],BuyerId,ParentRfqId ,RfqThumbnails)
	VALUES (SOURCE.RFQ_ID,ISNULL(SOURCE.RFQ_NAME,''),SOURCE.RFQ_QUALITY,ISNULL(SOURCE.BUYERCOMPANY,''),ISNULL(SOURCE.[LOCATION],'') ,ISNULL(SOURCE.[STATUS],'') , ISNULL(SOURCE.[RfqCloseDate],''),ISNULL(SOURCE.[RfqReleaseDate],'') , SOURCE.BuyerId,SOURCE.ParentRfqId ,SOURCE.RfqThumbnails)   ;    


	SELECT 
		a.RfqId 
		, (SELECT COUNT(DISTINCT supplier_id ) FROM mp_rfq_supplier_read (NOLOCK) WHERE rfq_id = a.RfqId ) AS Reviewed
		, (SELECT COUNT(DISTINCT company_id ) FROM mp_rfq_supplier_likes (NOLOCK) WHERE rfq_id = a.RfqId ) AS Liked
		, (SELECT COUNT(DISTINCT contact_id ) FROM mp_rfq_quote_suplierstatuses (NOLOCK) WHERE rfq_id = a.RfqId AND rfq_userStatus_id = 2 ) AS Marked 
		, 
		(
		  SELECT SUM (contact_id) FROM
		  (
			SELECT COUNT(DISTINCT contact_id ) AS contact_id FROM mp_rfq_quote_supplierquote (NOLOCK) WHERE rfq_id = a.RfqId AND is_quote_submitted = 1 AND is_rfq_resubmitted = 0
			UNION ----M2-4428 : here fetching data for decline quote
			SELECT COUNT(DISTINCT contact_id ) AS contact_id FROM mp_rfq_quote_supplierquote (NOLOCK) WHERE rfq_id = a.RfqId AND is_quote_submitted = 1 AND is_rfq_resubmitted = 1 AND is_quote_declined = 1 
		  ) QuotesCnt
		) AS Quotes 
	INTO #setActionTrackerRfqUpdate
	FROM ActionTrackerRFQ  (NOLOCK) A
	WHERE [Status] IN ('Quoting','Closed','Awarded','Not Awarded')


	-- UPDATE RFQ - Viewed ,Liked ,Marked ,Quoted INFO
	MERGE ActionTrackerRFQ AS TARGET
    USING #setActionTrackerRfqUpdate AS SOURCE ON
    (TARGET.RfqId = SOURCE.RfqId)
    WHEN MATCHED
    AND (
            TARGET.Reviewed				!= SOURCE.Reviewed 
			OR TARGET.Liked				!= SOURCE.Liked 
			OR TARGET.Marked			!= SOURCE.Marked 
			OR TARGET.Quotes			!= SOURCE.Quotes 
		)
	THEN
		UPDATE SET
            TARGET.Reviewed			= SOURCE.Reviewed 
			, TARGET.Liked			= SOURCE.Liked 
			, TARGET.Marked			= SOURCE.Marked 
			, TARGET.Quotes			= SOURCE.Quotes ;

	---- if duplicate RFQ id inserted into ActionTrackerRFQ then Job failed SQLJob_Set_ActionTracker_Rfq_Data
	---- so prevent this below code is written to remove dupicate RFQs
	; WITH cteDuplicateRFQ AS
	(
		SELECT   RfqId 
		FROM ActionTrackerRFQ (NOLOCK) 	
		GROUP BY RfqId	 
		HAVING COUNT(1) > 1		
	) 
	DELETE FROM ActionTrackerRFQ WHERE id in 
	(
		SELECT id FROM  
		(	SELECT b.id , b.rfqid,ROW_NUMBER() OVER( PARTITION BY b.rfqid ORDER BY id DESC) rn
			FROM cteDuplicateRFQ a 
			JOIN ActionTrackerRFQ(NOLOCK) b on a.rfqid = b.RfqId
		) deleteATR 
		WHERE rn > 1
	)

END
