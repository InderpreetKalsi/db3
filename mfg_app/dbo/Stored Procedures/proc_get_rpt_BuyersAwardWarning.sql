-- EXEC proc_get_rpt_BuyerswithPartFiles @parStartDate = '2020-01-01', @parEndDate = '2020-12-31'
CREATE PROCEDURE [dbo].[proc_get_rpt_BuyersAwardWarning]
AS
BEGIN

	SET NOCOUNT ON

		SELECT 
			a.contact_id
			,d.email 
			, COUNT( DISTINCT a.rfq_id ) AS total_rfqs
			, COUNT( DISTINCT b.contact_id ) AS total_supplier_quoted
			, DATEDIFF(DAY, CONVERT(DATE,c.last_login_on) , GETUTCDATE()) days_last_login
			, CASE WHEN COUNT( DISTINCT a.rfq_id ) > 5 AND  DATEDIFF(DAY, CONVERT(DATE,c.last_login_on) , GETUTCDATE()) > 30 Then 'Yes' ELSE 'No' END show_banner
		FROM mp_rfq (NOLOCK) a
		JOIN mp_rfq_quote_SupplierQuote (NOLOCK) b ON a.rfq_id = b.rfq_id AND b.is_quote_submitted = 1 AND b.is_rfq_resubmitted = 0
		JOIN mp_contacts (NOLOCK) c ON a.contact_id = c.contact_id
		JOIN AspNetUsers (NOLOCK) d ON c.user_id = d.id
		WHERE
			a.rfq_status_id = 5
			AND DATEDIFF(DAY, CONVERT(DATE,a.award_date),CONVERT(DATE,GETUTCDATE())) >= 7
			AND CONVERT(DATE,a.rfq_created_on) > = '2020-08-01'
		GROUP BY a.contact_id,d.email , DATEDIFF(DAY, CONVERT(DATE,c.last_login_on) , GETUTCDATE())
		ORDER BY days_last_login
END

