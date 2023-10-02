

/*


EXEC [proc_get_Vision_ActionTrackerRfq_ManufacturerInfo]
@RfqId = 1169217
,@Type = 'Quotes' -- Reviewed , Liked  , Marked , Quotes
,@Search = NULL

SELECT * FROM mp_special_files (NOLOCK) WHERE COMP_ID = 363503 AND FILETYPE_ID = 6

UPDATE mp_special_files SET IS_DELETED = 1
WHERE FILE_ID IN
(
314249,
314251,
314255,
314259,
314261,
314265
)
AND  COMP_ID = 363503 AND FILETYPE_ID = 6
*/
CREATE PROCEDURE [dbo].[proc_get_Vision_ActionTrackerRfq_ManufacturerInfo]
(
	@RfqId		INT
	,@Type		VARCHAR(150)
	,@Search	VARCHAR(500) = NULL
)
AS
 -- declare @RfqId		INT = 1157304
	--,@Type		VARCHAR(150) = 'Quotes'
	--,@Search	VARCHAR(500) = NULL

BEGIN

	-- M2-3379 Vision - RFQ Tracker - M drawer list with message capabilities-DB

	SET NOCOUNT ON

	DECLARE @CompanyLogo			VARCHAR(4000)


	DROP TABLE IF EXISTS #ActionTrackerRfq_ManufacturerInfo
	DROP TABLE IF EXISTS #ActionTrackerRfq_ManufacturerCapabilities

	CREATE TABLE #ActionTrackerRfq_ManufacturerInfo (CompanyId INT)


	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
	END
	
	IF @Search IS NULL 
		SET @Search =''

	IF @Type = 'Reviewed'
	BEGIN

		INSERT INTO #ActionTrackerRfq_ManufacturerInfo (CompanyId)
		SELECT DISTINCT b.company_id AS CompanyId 
		FROM mp_rfq_supplier_read	(NOLOCK) a
		JOIN mp_contacts			(NOLOCK) b ON a.supplier_id = b.contact_id
		WHERE a.rfq_id = @RfqId
	
	END

	IF @Type = 'Liked'
	BEGIN

		INSERT INTO #ActionTrackerRfq_ManufacturerInfo (CompanyId)
		SELECT DISTINCT  a.company_id AS CompanyId 
		FROM mp_rfq_supplier_likes	(NOLOCK) a
		WHERE a.rfq_id = @RfqId

	END

	IF @Type = 'Marked'
	BEGIN

		INSERT INTO #ActionTrackerRfq_ManufacturerInfo (CompanyId)		
		SELECT DISTINCT  b.company_id AS CompanyId 
		FROM mp_rfq_quote_suplierstatuses	(NOLOCK) a
		JOIN mp_contacts					(NOLOCK) b ON a.contact_id = b.contact_id
		WHERE a.rfq_id = @RfqId AND a.rfq_userStatus_id = 2

	END

	IF @Type = 'Quotes'
	BEGIN

		INSERT INTO #ActionTrackerRfq_ManufacturerInfo (CompanyId)	
		SELECT DISTINCT  b.company_id AS CompanyId 
		FROM mp_rfq_quote_supplierquote	(NOLOCK) a
		JOIN mp_contacts					(NOLOCK) b ON a.contact_id = b.contact_id
		WHERE a.rfq_id = @RfqId AND a.is_quote_submitted = 1 AND a.is_rfq_resubmitted = 0
		UNION
		----M2-4428 : here fetching data for decline quote
		SELECT DISTINCT  b.company_id AS CompanyId 
		FROM mp_rfq_quote_supplierquote	(NOLOCK) a
		JOIN mp_contacts					(NOLOCK) b ON a.contact_id = b.contact_id
		WHERE a.rfq_id = @RfqId AND a.is_quote_submitted = 1 AND a.is_rfq_resubmitted = 1 AND a.is_quote_declined = 1
	
	END

	SELECT DISTINCT
		b.company_id AS CompanyId , a1.discipline_name AS Capabilities 
	INTO #ActionTrackerRfq_ManufacturerCapabilities
	FROM mp_mst_part_category (NOLOCK) a
	JOIN mp_mst_part_category (NOLOCK) a1 ON a.parent_part_category_id = a1.part_category_id
	JOIN
	(
		SELECT company_id, part_category_id FROM mp_company_processes (NOLOCK) WHERE company_id IN (SELECT * FROM #ActionTrackerRfq_ManufacturerInfo)
		UNION
		SELECT company_id, part_category_id FROM mp_gateway_subscription_company_processes (NOLOCK) WHERE company_id IN (SELECT * FROM #ActionTrackerRfq_ManufacturerInfo)
	) b ON a.part_category_id = b.part_category_id
	WHERE a.status_id = 2 

	SELECT 
		a.CompanyId
		,b.name AS Company 
		,c.contact_id AS SupplierId
		,c.supplier AS Supplier
		,CASE WHEN h.file_name IS NULL THEN ' ' WHEN h.file_name ='' THEN ' ' ELSE ISNULL(@CompanyLogo + h.file_name,'') END 		as [CompanyLogo] 
		,d.Capabilities
	FROM #ActionTrackerRfq_ManufacturerInfo a
	JOIN mp_companies (NOLOCK) b ON a.CompanyId = b.company_id
	JOIN 
	(
		SELECT 
			ROW_NUMBER() OVER(PARTITION BY company_id  ORDER BY company_id , is_admin DESC, contact_id)  as rn
			, contact_id 
			, company_id 
			, is_admin 
			, first_name +' '+last_name AS supplier
		FROM mp_contacts (NOLOCK)
	) c ON a.CompanyId = c.company_id AND c.rn =1
	LEFT JOIN mp_special_files	(NOLOCK) h ON b.company_id = h.COMP_ID AND FILETYPE_ID = 6 AND IS_DELETED = 0
	LEFT JOIN
	(
		SELECT DISTINCT
			CompanyId
			,STUFF
			(
			 (
				SELECT ',' + b.Capabilities
				FROM #ActionTrackerRfq_ManufacturerCapabilities b
				WHERE a.CompanyId = b.CompanyId
				FOR XML PATH ('')
			 ), 1, 1, '')  AS Capabilities
		FROM #ActionTrackerRfq_ManufacturerCapabilities a
	) d ON a.CompanyId = d.CompanyId
	WHERE a.CompanyId  <> 0 
	AND b.name LIKE '%'+@Search+'%'
	ORDER BY Company 

END
