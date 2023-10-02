

/*
	DECLARE @IsAllRFQAwarded1	BIT
	EXEC proc_get_buyer_dashboard_rfq_for_awarding @BuyerId = 72972 , @IsAllRFQAwarded = @IsAllRFQAwarded1 OUTPUT
	SELECT @IsAllRFQAwarded1
*/

CREATE PROCEDURE [dbo].[proc_get_buyer_dashboard_rfq_for_awarding]
(
	@BuyerId INT
	,@IsAllRFQAwarded	BIT OUTPUT
)
AS
BEGIN
	
	SET NOCOUNT ON

	/*
		-- Created	:	May 28, 2020
					:	M2-2900 Buyer - Dashboard - Awarding Module - DB
	*/

	DECLARE @TotalRFQs INT = 0
	DECLARE @TotalAwardedRFQs INT = 0
	

	SELECT @TotalRFQs = COUNT(1) FROM mp_rfq WHERE contact_id =@BuyerId  AND rfq_status_id NOT IN  (1,13)
	SELECT @TotalAwardedRFQs = COUNT(1) FROM mp_rfq WHERE contact_id =@BuyerId  AND rfq_status_id = 6


	SET @IsAllRFQAwarded =
	(
		CASE WHEN @TotalRFQs = @TotalAwardedRFQs THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT)  END
	)

	;WITH RfqForAwarding AS
	(

		SELECT 
			a.rfq_id	AS RfqId
			,a.rfq_name	AS Rfq
			,FORMAT(a.Quotes_needed_by, 'd', 'en-US' ) AS RfqClosedDate
			,FORMAT(a.award_date, 'd', 'en-US' )	AS RfqAwardDate
			,COALESCE(c.File_Name,'') AS RfqThumbnail
			,a.contact_id AS RfqBuyerId
			,CONVERT(VARCHAR(100),COUNT(DISTINCT b.contact_id)) NoOfQuotes
			,SUM(ISNULL(CONVERT(INT,d.is_awrded),0)) AwardCount
		FROM mp_rfq a (NOLOCK) 
		JOIN mp_rfq_quote_supplierquote b (NOLOCK) 
			ON	a.rfq_id = b.rfq_id 
				AND a.rfq_status_id IN (5)
				AND b.is_rfq_resubmitted = 0
				AND is_quote_submitted = 1
				AND a.contact_id = @BuyerId
				--AND CONVERT(DATE, a.award_date) < CONVERT(DATE, GETUTCDATE()) 
				AND a.ExcludeFromDashboardAwardedModule = 0
		JOIN mp_rfq_quote_items d (NOLOCK)  ON b.rfq_quote_SupplierQuote_id= d.rfq_quote_SupplierQuote_id
		LEFT JOIN mp_special_files	c (NOLOCK) 
			ON	c.file_id = a.file_id
		GROUP BY 
			a.rfq_id	
			,a.rfq_name	
			,FORMAT(a.Quotes_needed_by, 'd', 'en-US' ) 
			,FORMAT(a.award_date, 'd', 'en-US' )	
			, COALESCE(c.File_Name,'') 
			, a.contact_id 
		)
		SELECT 
		TOP 2
			a.RfqId
			,Rfq
			,RfqClosedDate
			,RfqAwardDate
			,RfqThumbnail
			,RfqBuyerId
			,NoOfQuotes
			,'You received ['+NoOfQuotes+'] quotes it’s past the Award date. Would you like to award this?' AS RfqAwardMessage
			,AwardCount
			,ClonedRFQs
		FROM RfqForAwarding a
		LEFT JOIN 
		(
			SELECT DISTINCT parent_rfq_id AS RfqId
			,STUFF(
					 (SELECT ', ' + convert(varchar(max), b.cloned_rfq_id)
					  FROM mp_rfq_cloned_logs  b (NOLOCK)
					  where a.parent_rfq_id = b.parent_rfq_id
					  FOR XML PATH (''))
					  , 1, 1, '')  AS ClonedRFQs
			FROM mp_rfq_cloned_logs  a (NOLOCK)
			JOIN mp_rfq c (NOLOCK) ON a.cloned_rfq_id = c.rfq_id AND c.rfq_status_id IN (3,5)
		) b ON a.RfqId = b.RfqId
		WHERE AwardCount = 0
		----ORDER BY RfqAwardDate ASC 
		ORDER BY CAST(RfqClosedDate AS DATE) DESC  ----M2-5208
END
