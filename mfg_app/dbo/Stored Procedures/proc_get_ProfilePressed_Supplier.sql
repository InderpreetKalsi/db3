


CREATE Procedure [dbo].[proc_get_ProfilePressed_Supplier]
(
@CompanyId INT, 
@lead_source_id INT --'Community Profile' 11,'Community Phone' 12,'Community Website' 15
)
As 
BEGIN

	SET NOCOUNT ON
	
	/* M2-4112 M - Email - A buyer just pressed Website on your profile – DB */

	SELECT DISTINCT 
		mp_Companies.Company_Id CompanyId 
	,	mp_Companies.name CompanyName
	,	mp_Companies.CompanyURL CompanyURL
	,	FirstName +' '+ LastName AdvisorName
	,	mp_Contacts.Title Designation
	,	aspnetusers.PhoneNumber ContactNumber
	,	mp_mst_lead_source.lead_Source_Id EventId
	,	Lead_Source EventName
	,	COUNT(distinct Lead_id) [Count]
	FROM			mp_lead					(NOLOCK)
	INNER JOIN		mp_mst_lead_source		(NOLOCK)	ON mp_mst_lead_source.lead_Source_id = mp_lead.lead_Source_id
	INNER JOIN		mp_Companies			(NOLOCK)	ON mp_Companies.Company_id = mp_lead.company_id
	INNER JOIN		mp_Contacts				(NOLOCK)	ON mp_Contacts.Contact_id=mp_Companies.Assigned_SourcingAdvisor
	INNER JOIN		aspnetusers				(NOLOCK)	ON aspnetusers.contact_id = mp_Contacts.Contact_id
	WHERE mp_lead.lead_source_id in (@lead_source_id)
	AND mp_Companies.Company_Id = @CompanyId		
	AND CAST(mp_lead.lead_date as DATE) = CAST(GETUTCDATE() AS DATE)
	GROUP BY FirstName +' '+ LastName,aspnetusers.PhoneNumber, mp_Companies.Company_Id , mp_Companies.name,mp_Companies.CompanyURL,mp_mst_lead_source.lead_Source_Id, Lead_Source, mp_Contacts.Title
	/*  */
	--Created Date, phone no, title/designation from aspnetusers
END
