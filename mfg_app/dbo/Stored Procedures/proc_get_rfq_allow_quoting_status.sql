
/*

EXEC proc_get_rfq_allow_quoting_status  @RFQId = 1189358, @SupplierCompanyId = 1797766
EXEC proc_get_rfq_allow_quoting_status  @RFQId = 1181941, @SupplierCompanyId = 1797766


*/

CREATE PROCEDURE [dbo].[proc_get_rfq_allow_quoting_status]
(
	@RFQId	INT
	,@SupplierCompanyId	INT
)
AS
BEGIN
	
	SET NOCOUNT ON
	-- M2-2739 Stripe - Capabilities selection for gold & platinum subscription - DB


	DECLARE @IsStripeSupplier	BIT = 0
	DECLARE @IsAllowQuoting		BIT = 0
	DECLARE @IsAllowPartialQuoting		BIT = 0
	DECLARE @MatchedPartCount	INT = 0
	DECLARE @RFQPartCount		INT = 0

	SET @IsStripeSupplier =
		(
			CASE	
				WHEN (SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK)  WHERE  company_id =  @SupplierCompanyId AND is_active = 1)> 0 THEN CAST('true' AS BIT) 
				ELSE CAST('false' AS BIT) 
			END 
		)

	SELECT 
		@MatchedPartCount	= COUNT(c.part_category_id) ,  
		@RFQPartCount		= COUNT(b.rfq_part_id) 
	FROM mp_rfq					(NOLOCK) a
	LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
	LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompanyId  AND c.is_active = 1
 	WHERE  
		a.rfq_id IN (@RFQId)
	
	
	SET @IsAllowQuoting = (	CASE	WHEN @MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END )
	SET @IsAllowPartialQuoting = (	
									CASE	
										WHEN @MatchedPartCount > 0 THEN
											CASE	
												WHEN	@MatchedPartCount = @RFQPartCount THEN  CAST('false' AS BIT)
												WHEN	@MatchedPartCount < @RFQPartCount THEN  CAST('true' AS BIT)
											END
										ELSE
											CAST('false' AS BIT) 
									END		
								)


	SELECT @IsStripeSupplier AS IsStripeSupplier, @IsAllowQuoting AS IsAllowQuoting , @IsAllowPartialQuoting AS IsAllowPartialQuoting
END
