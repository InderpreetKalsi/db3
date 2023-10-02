
CREATE proc [dbo].[proc_get_leadstream_monthlyreport]
as
select a.company_id AS CompanyId,[name] as [CompanyName], c.first_name AS FirstName, c.last_name AS LastName,d.Email  from mp_lead a 
inner join mp_companies b on a.company_id=b.company_id 
inner join mp_contacts c on b.company_id=c.company_id
inner join AspNetUsers d on d.Id =c.user_id
WHERE DATEPART(m, lead_date) = DATEPART(m, DATEADD(m, -1, getdate()))
AND DATEPART(yyyy, lead_date) = DATEPART(yyyy, DATEADD(m, -1, getdate())) and a.company_id<>0
group by a.company_id,b.name,c.first_name , c.last_name,d.Email
order by a.company_id
