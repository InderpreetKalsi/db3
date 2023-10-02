
-- =============================================
-- Author:		<Author,,Pooja Mishra>
-- Create date: <01/02/2021,,>
-- Description:	<Description,,>
-- =============================================
-- EXEC [proc_get_LeadstreamProfileViewedWeekly]
CREATE    PROCEDURE  [dbo].[proc_get_LeadstreamProfileViewedWeekly]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @RedirectLink VARCHAR(500) 

	DROP TABLE IF EXISTS #tmp_LeadstreamProfileViewedWeekly_mp_lead
	
	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @RedirectLink = 'http://qa.mfg2020.com/#/leadstream'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @RedirectLink = 'https://uatapp.mfg.com/#/leadstream'
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @RedirectLink = 'https://app.mfg.com/#/leadstream'
	END



	SELECT * INTO #tmp_LeadstreamProfileViewedWeekly_mp_lead
	FROM mp_lead a  (NOLOCK)
	WHERE
	a.lead_source_id IN (1,11,16)
	AND CONVERT(DATE,lead_date) BETWEEN DATEADD(DAY, - 7, CONVERT(DATE,GETUTCDATE())) AND CONVERT(DATE,GETUTCDATE())


    -- Insert statements for procedure here
	SELECT distinct
		d.name AS Company
		, c.first_name +' '+c.last_name AS Supplier
		, us.Email
		 , c.contact_id as ContactId
		, COUNT(a.lead_source_id) AS ProfileViewedCount
		, s.first_name+' '+s.last_name As SourcingAdvisorName
		, s.title As SourcingAdvisorDesignation
		, su.PhoneNumber As SourcingAdvisorNo
		, @RedirectLink AS RedirectLink
	FROM #tmp_LeadstreamProfileViewedWeekly_mp_lead a  (NOLOCK)
	JOIN mp_companies d (NOLOCK) ON d.company_id = a.company_id
	JOIN mp_contacts c (NOLOCK) ON d.company_id = c.company_id
	JOIN mp_contacts s (NOLOCK) ON d.Assigned_SourcingAdvisor = s.contact_id
	JOIN AspNetUsers su (NOLOCK) ON su.id = s.user_id
	JOIN AspNetUsers us (NOLOCK) ON us.id = c.user_id
	WHERE
	a.lead_source_id IN (1,11,16)
	AND CONVERT(DATE,lead_date) BETWEEN DATEADD(DAY, - 7, CONVERT(DATE,GETUTCDATE())) AND CONVERT(DATE,GETUTCDATE())
	AND a.company_id  <> 0
	AND c.IsTestAccount = 0 AND c.is_buyer = 0  and c.is_admin = 1 -- and ip_address = '' and lead_from_contact > 0
	GROUP BY d.name ,c.first_name , c.last_name, d.name,us.Email,s.first_name , s.last_name,s.title,su.PhoneNumber,c.contact_id
	/* Ewesterfield-MFG  Feb 26 2021 
	Allwin Lewis Inderpreet Singh Kalsi 
	After talking with Adam, lets keep the IP addresses but only send emails to supplier who have at least 3 profile views 
	so the single bot pings don't go out. We'll try that next Friday and see how it goes.
	*/
	HAVING COUNT(1) > 2
	/**/
	ORDER BY Company

END
