CREATE proc [dbo].[proc_get_profileview_monthlyreport]
as
select distinct a.company_id,'https://app.mfg.com/#/Public/profile/'+b.CompanyURL as CompanyURL, sum(Case when a.lead_from_contact> 0 then 1 else 0 end) InternalCount,
sum(Case when a.lead_from_contact= 0 then 1 else 0 end)ExternalCount  from mp_lead(nolock) a 
inner join mp_Companies(nolock) b on a.company_id=b.company_id
inner join mp_contacts (nolock) c on c.company_id = a.company_id and c.is_buyer=0
where a.lead_source_id=1 and DATEPART(m, lead_date) = DATEPART(m, DATEADD(m, -1, getdate()))
AND DATEPART(yyyy, lead_date) = DATEPART(yyyy, DATEADD(m, -1, getdate()))  and a.company_id > 0  
group by a.company_id,b.CompanyURL
order by a.company_id


