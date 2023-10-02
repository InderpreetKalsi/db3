

/*

EXEC proc_get_buyer_award_warning
@BuyerId = 1408671

*/
CREATE PROCEDURE [dbo].[proc_get_buyer_award_warning]
(
	@BuyerId	INT
)
AS
BEGIN

	SET NOCOUNT ON

	/*	M2-3326 Buyer - Warning drop down - DB */

	/*	Soel Yesterday at 10:20 PM (Aug 07, 2022)
		@Inderpreet Singh Kalsi
		can you disable the RFQ blocker for the supplychain@shapeways.com account.  They want to be able to post more RFQs without having to complete the award status requirements
	*/
	IF @BuyerId = 1408670
	BEGIN
		SELECT 
			COUNT( DISTINCT a.rfq_id ) AS TotalRFQs
			, COUNT( DISTINCT b.contact_id ) AS TotalSuppliersQuoted 
		FROM mp_rfq (NOLOCK) a
		JOIN mp_rfq_quote_SupplierQuote (NOLOCK) b ON a.rfq_id = b.rfq_id AND b.is_quote_submitted = 1 AND b.is_rfq_resubmitted = 0
		WHERE
			a.contact_id = 1
			AND a.rfq_status_id = 5
			AND DATEDIFF(DAY, CONVERT(DATE,a.award_date),CONVERT(DATE,GETUTCDATE())) >= 7
			AND CONVERT(DATE,a.rfq_created_on) > = '2020-08-01'
		GROUP BY a.contact_id HAVING COUNT( DISTINCT a.rfq_id )  >= 5 
		
	END
	/**/
	ELSE
	BEGIN
		SELECT 
			COUNT( DISTINCT a.rfq_id ) AS TotalRFQs
			, COUNT( DISTINCT b.contact_id ) AS TotalSuppliersQuoted
		FROM mp_rfq (NOLOCK) a
		JOIN mp_rfq_quote_SupplierQuote (NOLOCK) b ON a.rfq_id = b.rfq_id AND b.is_quote_submitted = 1 AND b.is_rfq_resubmitted = 0
		JOIN mp_contacts (NOLOCK) c ON a.contact_id = c.contact_id
		WHERE
			a.contact_id = @BuyerId
			AND 
			a.rfq_status_id = 5
			AND DATEDIFF(DAY, CONVERT(DATE,a.award_date),CONVERT(DATE,GETUTCDATE())) >= 7
			AND CONVERT(DATE,a.rfq_created_on) > = '2020-08-01'
			/* Soel - Dec 21, 2022 hey so it seems some legacy buyers are coming back to post RFQs but are being blocked by our RFQ Award limit.   Is there a way to do a report for buyers who have 5 or more RFQs that need to be set for award status and the buyer has logged in the last 30 days so we can handle that for them so we aren't blocking buyers?
			*/
			AND CONVERT(DATE,c.last_login_on) <= CONVERT(DATE,DATEADD(DAY,-30,GETUTCDATE()))
			/**/	
		GROUP BY a.contact_id ,CONVERT(DATE,c.last_login_on) HAVING COUNT( DISTINCT a.rfq_id )  >= 5
		
	END

END
