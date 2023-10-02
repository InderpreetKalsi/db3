

/*
	SELECT DISTINCT B.company_id , D.EMAIL , COUNT(DISTINCT RFQ_ID) 
	FROM mp_contacts		(NOLOCK) b 
	JOIN mp_rfq_quote_SupplierQuote (NOLOCK) c on b.contact_id = c.contact_id 
		AND c.is_rfq_resubmitted = 0
		AND c.is_quote_submitted = 1
	JOIN ASPNETUSERS (NOLOCK) D ON B.USER_ID = D.ID
	GROUP BY B.company_id , D.EMAIL 
	ORDER BY B.company_id 
	

EXEC  [proc_get_ListOfQuotedRfqsForCommunity] @Email = 'supplierqa@yopmail.com' , @PageNo = 1 , @PageSize = 2500
EXEC  [proc_get_ListOfQuotedRfqsForCommunity] @Email = 'cjones@mfg.com', @PageNo = 1 , @PageSize = 1000



*/

CREATE PROCEDURE [dbo].[proc_get_ListOfQuotedRfqsForCommunity]
	 @Email VARCHAR(100)	
	 ,@PageNo INT = 1
	 ,@PageSize INT = 25
	
AS
	
BEGIN
	-- M2-3818 API - New API for RFQ's quoted by M's for the directory profile- DB
	SET NOCOUNT ON
	
	DECLARE @RfqThumbnail VARCHAR(MAX) = ''
	DECLARE @CompanyId INT
	
	IF @PageNo IS NULL 
		SET @PageNo = 1

	IF @PageSize IS NULL 
		SET @PageSize = 25
	
	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'			
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
	END

	SET @CompanyId = 	
	(
		SELECT DISTINCT TOP 1 a.company_id 
		FROM mp_contacts (NOLOCK) a
		JOIN aspnetusers (NOLOCK) b ON a.user_id = b.id
		WHERE b.Email = @Email AND a.is_buyer = 0
	)


	SELECT 
		d.rfq_id						AS [RfqId]
		, d.rfq_name					AS [RFQName]
		, CASE WHEN CHARINDEX('.zip',j.[file_name]) > 0 THEN '' ELSE COALESCE(@RfqThumbnail+j.[file_name],'')	END AS [RfqThumbnail]	
		, h.discipline_name				AS [Process]
		, i.material_name_en			AS [Material]
		, (
			SELECT MIN(part_qty) 
			FROM mp_rfq_parts (NOLOCK) a
			JOIN mp_rfq_part_quantity  (NOLOCK) b ON a.rfq_part_id = b.rfq_part_id AND b.is_deleted = 0
			WHERE a.rfq_id = d.rfq_id
		  ) AS [MinQuantity]
		, (
			SELECT MAX(part_qty) 
			FROM mp_rfq_parts (NOLOCK) a
			JOIN mp_rfq_part_quantity  (NOLOCK) b ON a.rfq_part_id = b.rfq_part_id AND b.is_deleted = 0
			WHERE a.rfq_id = d.rfq_id
		  ) AS [MaxQuantity]
		, (SELECT COUNT(1) FROM mp_rfq_parts (NOLOCK) WHERE rfq_id = d.rfq_id) AS [NoofParts]
		, CAST(c.quote_date AS DATE) AS [QuoteDate]
		, COUNT(1) OVER() AS TotalCount
	FROM mp_contacts		(NOLOCK) b 
	JOIN mp_rfq_quote_SupplierQuote (NOLOCK) c on b.contact_id = c.contact_id 
		AND c.is_rfq_resubmitted = 0
		AND c.is_quote_submitted = 1
		AND b.company_id = @CompanyId
	JOIN mp_rfq				(NOLOCK) d ON c.rfq_id = d.rfq_id --AND d.rfq_status_id in  (3 , 5, 6 ,16, 17 ,18 ,20) 
	JOIN mp_rfq_parts 		(NOLOCK) e ON d.rfq_id = e.rfq_id AND e.is_rfq_part_default =  1
	LEFT JOIN mp_mst_part_category (NOLOCK) g ON e.part_category_id = g.part_category_id
	LEFT JOIN mp_mst_part_category (NOLOCK) h ON g.parent_part_category_id = h.part_category_id
	LEFT JOIN mp_mst_materials	   (NOLOCK) i ON e.material_id = i.material_id
	LEFT JOIN mp_special_files	   (NOLOCK) j ON d.[file_id] = j.[file_id]
	--JOIN mp_contacts			   (NOLOCK) k ON d.contact_id = k.contact_id AND k.IsTestAccount = 0
	ORDER BY [QuoteDate] DESC
	OFFSET @PageSize * (@PageNo - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY

END


