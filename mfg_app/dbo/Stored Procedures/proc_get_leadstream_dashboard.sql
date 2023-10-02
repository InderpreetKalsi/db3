
/*
select * from mp_lead where company_id = 1767917 order by lead_source_id

exec proc_get_leadstream_dashboard @company_id = 1800414 , @uptodays = null
*/

CREATE PROCEDURE [dbo].[proc_get_leadstream_dashboard]
(
	@company_id		int
	, @uptodays		int
	, @pagenumber	int = 1
	, @pagesize		int = 25
	, @datefrom     date = null 
	, @dateto       date = null 
	, @InteractionType INT = 0	 
)
as
begin
	/* M2-1985 M - Leadstream - Add Dashboard roll up data above the leads list - DB*/
	set nocount on

	DECLARE @AccountType INT = 313 ---If user comapny has Starter package then exclude such records from list
	
	if @uptodays is null or @uptodays = 0
		set @uptodays = 30

	if @datefrom is not null
		set @uptodays = datediff(day, @datefrom , getutcdate())

	if @uptodays is not null and @datefrom is null 
	begin
		set @datefrom = '2000-01-01'
		set @dateto = getutcdate()
				
	end	
	
	select 
		a.lead_source_id
		,a.lead_source 
		--, isnull(b.total,0) as  total
		,count(1)  total
	from mp_mst_lead_source (nolock) a
	left join
	(
			select  
				b.lead_source_id
				/* M2-3194 Leadstream - Limit the number of times an IP shows up in leadstream in 24 hour period - DB*/
				,convert(date,a.lead_date) lead_date
				,c.contact_id 
				,b.lead_source_desc
				,a.value
				,row_number() over(partition by convert(date,a.lead_date) , c.contact_id ,b.lead_source_desc , a.value order by convert(date,a.lead_date) asc)  rn
				/**/
			from mp_lead			a (nolock)
			join mp_mst_lead_source b (nolock)	on a.lead_source_id = b.lead_source_id
			left join mp_contacts	c (nolock)	on a.lead_from_contact = c.contact_id and c.is_active=1
			left join mp_companies	d (nolock)	on c.company_id = d.company_id
			where 
				a.company_id = @company_id	
				/* M2-3251	Vision - Flag as a test account and hide the data from reporting - DB */
				and isnull(c.istestaccount,0)= 0
				/**/
				and convert(date,lead_date)> = dateadd(day, - @uptodays, convert(date,getutcdate()))
				and convert(date,lead_date) between @datefrom and @dateto
				 and  
				((@InteractionType  > 0 AND a.lead_source_id = @InteractionType
				  OR
				 (@InteractionType = 0 )))	
				and (CASE WHEN a.lead_source_id in (6,13) AND (a.status_id IS NULL OR a.status_id = 2 OR a.status_id = 0) THEN 0 
				          WHEN a.lead_source_id = 10 AND a.status_id = 2 THEN 0 --change for ticket M2-3172 Leadstream Report Buyer Awards
						  ELSE 1 END) = 1	
				AND @AccountType ! = (SELECT account_type FROM mp_registered_supplier(NOLOCK) WHERE company_id = @company_id) --- M2-5133 
			--group  by b.lead_source_id
	) b on a.lead_source_id = b.lead_source_id
	where 
	/* M2-3194 Leadstream - Limit the number of times an IP shows up in leadstream in 24 hour period - DB*/
	--isnull(b.total,0) <> 0 
	--and 
	rn =1  
	group by a.lead_source_id
		,a.lead_source
	/**/
end
