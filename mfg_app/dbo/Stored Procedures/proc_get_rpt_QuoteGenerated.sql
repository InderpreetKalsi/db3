/*
    By Soel
	could I get a report document that I can enter start date / end date and it returns all suppliers who generated a quote in that period and the company name
	Example:
	XYZ Company -- 100
	ABC company --2

*/
 
---- exec [dbo].[proc_get_rpt_QuoteGenerated] '2022-12-01'  , '2023-04-30'
CREATE PROCEDURE [dbo].[proc_get_rpt_QuoteGenerated] 
(
	@StartDate DATE = null
	,@EndDate   DATE = null
)
AS
BEGIN

	SELECT c.company_id , d.name, COUNT(DISTINCT a.rfq_id) [GeneratedQuote]
	FROM mp_rfq (NOLOCK) a
	JOIN mp_rfq_quote_SupplierQuote(NOLOCK) b ON a.rfq_id = b.rfq_id
	JOIN mp_contacts(NOLOCK) c ON c.contact_id = b.contact_id
	JOIN mp_companies (NOLOCK) d ON d.company_id = c.company_id
	WHERE CAST(b.quote_date AS DATE) BETWEEN   ISNULL(@StartDate,b.quote_date)  AND  ISNULL(@EndDate  ,b.quote_date)
	AND b.is_quote_submitted = 1 AND b.is_rfq_resubmitted = 0
	AND C.IsTestAccount = 0
	--@StartDate  AND  @EndDate  
	GROUP BY c.company_id,d.name
	ORDER BY [GeneratedQuote] desc, c.company_id
END