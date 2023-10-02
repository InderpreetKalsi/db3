
/*

exec proc_get_VisionBuyers
 @pagenumber					 = 1,
 @pagesize						 = 20,
 @searchtext					 = '1372902',	 
 @orderbydesc					 = 1,
 @unvalidated					 = 0,
 @validated						 = 0,
 @active						 = 0,
 @activewithpendingrfq			 = 0,
 @activewithincompleterfq		 = 0,
 @buyerwithinprogressrfq		 = 0,
 @noquoterfq					 = 0,
 @buyernotlogged30days			 = 0,
 @buyernotlogged60days			 = 0,
 @buyernotlogged90days			 = 0,
 @noofrfqs						 = 0

*/

CREATE procedure [dbo].[proc_get_VisionBuyers]	 

 @pagenumber					int = 1,
 @pagesize						int = 25,
 @searchtext					varchar(100) = null,	 
 @orderbydesc					bit = 1,
 @unvalidated					bit = 0,
 @validated						bit = 0,
 @active						bit = 0,
 @activewithpendingrfq			bit = 0,
 @activewithincompleterfq		bit = 0,
 @buyerwithinprogressrfq		bit = 0,
 @noquoterfq					bit = 0,
 @buyernotlogged30days			bit = 0,
 @buyernotlogged60days			bit = 0,
 @buyernotlogged90days			bit = 0,
 @noofrfqs						int = 0
as
begin  	 
	/*
		created		:	apr 26, 2019

		modified	:	jun 11 ,2019
		M2-1520 Performance optimization for Vision list - Database side
	*/
	set nocount on

	--SELECT @pagenumber=1,@pagesize=20--,@searchtext='default',
	--,@orderbydesc=1,@unvalidated=0,@validated=0,@active=0,@activewithpendingrfq=0,@activewithincompleterfq=0,@buyerwithinprogressrfq=0,@noquoterfq=0,@buyernotlogged30days=0,@buyernotlogged60days=0,@buyernotlogged90days=0,@noofrfqs=0
	
	declare @sql_query nvarchar(max),
			@where_query nvarchar(max),
			@search_query nvarchar(max),
			@orderBy_query nvarchar(max)	 

	if charindex('''',@searchtext) > 0
		set @searchtext = replace(@searchtext,'''','''''')


	set @where_query =   
		case	when @unvalidated  = 1 then '[contact].[company_id] is not null and ( contact.is_validated_buyer = 0)' else '' end 
		+ case	when @validated  = 1 then '[contact].[company_id] is not null and ( contact.is_validated_buyer = 1)' else '' end 
		+ case when @active  = 1 then '[contact].[company_id] is not null and ( contact.contact_id in ( select contact_id from mp_rfq (nolock) where (mp_rfq.rfq_status_id > 2 and mp_rfq.rfq_status_id not in (5,13)  ) and format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') >= format(getutcdate(),''yyyyMMdd'') ))' else '' end 
		+ case when @activewithpendingrfq  = 1 then '[contact].[company_id] is not null and ( contact.contact_id in ( select contact_id from mp_rfq (nolock) where (mp_rfq.rfq_status_id = 2 and format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') >= format(getutcdate(),''yyyyMMdd'') )))' else '' end 
		+ case when @activewithincompleterfq  = 1 then '[contact].[company_id] is not null and ( contact.contact_id in ( select contact_id from mp_rfq (nolock) where (mp_rfq.rfq_status_id = 14 and format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') >= format(getutcdate(),''yyyyMMdd'') )))' else '' end
		+ case when @buyerwithinprogressrfq  = 1 then '[contact].[company_id] is null and ( contact.contact_id in ( select contact_id from mp_rfq (nolock) where (mp_rfq.rfq_status_id = 1 )))' else '' end  
		+ case when @noquoterfq  = 1 then '[contact].[company_id] is not null and ( contact.contact_id in ( select contact_id from mp_rfq (nolock) where  not exists (select 1 from mp_rfq_quote_supplierquote as [x] (nolock)  where x.rfq_id = mp_rfq.rfq_id) ))' else '' end  
		+ case when @buyernotlogged30days  = 1 then '[contact].[company_id] is not null and ( datediff(day,contact.last_login_on,getutcdate()) > 30)' else '' end  
		+ case when @buyernotlogged60days  = 1 then '[contact].[company_id] is not null and ( datediff(day,contact.last_login_on,getutcdate()) > 60)' else '' end  
		+ case when @buyernotlogged90days  = 1 then '[contact].[company_id] is not null and ( datediff(day,contact.last_login_on,getutcdate()) > 90)' else '' end  
		/* M2-3808 Vision - Sort the buyer list by number of RFQs sourced-DB */
		+ case	when @noofrfqs  = 5 then ' isnull(a.noofrfqs,0) between 1 and 5 ' else '' end 
		+ case	when @noofrfqs  = 10 then ' isnull(a.noofrfqs,0) between 5 and 10 ' else '' end 
		+ case	when @noofrfqs  = 20 then ' isnull(a.noofrfqs,0) between 11 and 20 ' else '' end 
		+ case	when @noofrfqs  = 50 then ' isnull(a.noofrfqs,0) between 21 and 50 ' else '' end 
		+ case	when @noofrfqs  = 51 then ' isnull(a.noofrfqs,0) > 50 ' else '' end 
		/* */
		+ case when @searchtext  is not null or @searchtext != '' then ' and [contact].[company_id] is '+case when @buyerwithinprogressrfq  = 1 then '' else ' not ' end+' null and (( charindex ('''+@searchtext+''' ,contact.contact_id) > 0  or charindex('''+@searchtext+''' ,contact.company_id) > 0 or charindex('''+@searchtext+''' ,[users].email) > 0 or charindex('''+@searchtext+''' ,contact.first_name) > 0 or charindex('''+@searchtext+''' ,contact.last_name) > 0  or charindex('''+@searchtext+''' ,contact.first_name +'' ''+contact.last_name) > 0 or charindex('''+@searchtext+''' ,[companies].[name]) > 0 )) ' else '' end  
	

	if left(@where_query,4) = ' and'
		set @where_query = ' where ' + substring(@where_query,5,len(@where_query))
	else if len(@where_query) >0
		set @where_query = ' where ' + @where_query
	else if len(@where_query) = 0
		set @where_query = ''

	
	set @search_query = 
	'	;WITH CTE
	AS
	(
		SELECT [user_id],is_admin,ROW_NUMBER() OVER(PARTITION BY company_id ,is_admin ORDER BY  company_id ,contact_id  ,is_admin DESC ) ContactRn
		FROM mp_contacts WHERE [is_buyer] = 1
	)
	select  
		[users].[Id] AS [UserId]
		, (select top 1 [logo].FILE_NAME from [mp_special_files] as [logo] (nolock) where [logo].[filetype_id] = cast(6 as smallint) and contact.[contact_id] = [logo].[cont_id] ) AS [Minilogo]
		, [companies].[name] AS [CompanyName]
		, COALESCE([contact].[first_name], N'''') AS [FirstName]
		, COALESCE([contact].[last_name], N'''') AS [LastName]
		, [users].[Email] AS [EmailAddress]
		, (select top 1 [communicationdetails].communication_value from [mp_communication_details] as [communicationdetails] (nolock) where [communicationdetails].[communication_type_id] = cast(1 as smallint) and [contact].[contact_id] = [communicationdetails].[contact_id]) AS [PhoneNumber]
		, CAST(COALESCE([contact].[Is_Validated_Buyer], 0) AS bit) AS [IsValidated]
		, [starRating].[no_of_stars] AS [NoOfStars]
		,[contact].[company_ID] AS [CompanyId]
		, [contact].[contact_id] AS [ContactId]
		, [contact].[last_login_on] AS [LastLogin]
		, [contact].[total_login_count] AS [TotalLoginCount]
		, [contact].[created_on] AS [CreatedOn]
		, [address].[country_id] AS [CountryId]
		, [companies].[Manufacturing_location_id] AS [ManufacturingLocationId]
		, count(1) over () BuyerCount 
		, (	
			select count(1) from mp_rfq a (nolock)  
			join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) b on a.rfq_id = b.rfq_id and a.contact_id = contact.contact_id
		  ) as RFQReleaseCount
        , isnull(a.noofrfqs,0) as [NoOfRfqs]
		,(CASE WHEN CTE.is_admin = 1 AND CTE.ContactRn = 1 THEN ''Primary Admin'' WHEN CTE.is_admin = 1  AND CTE.ContactRn > 1 THEN ''Secondary Admin'' ELSE ''User'' END) AS UserRole
	from [aspnetusers]			as [users]		(nolock)
	join [mp_contacts]			as contact	(nolock)	on [users].[id] = [contact].[user_id] and [contact].[is_buyer] = 1 
	JOIN CTE ON CTE.user_id = [contact].[user_id]
	Left join [mp_companies]	as [companies]	(nolock)	on [contact].[company_id] = [companies].[company_id]
	left join [mp_addresses]	as [address]	(nolock)	on [contact].[address_id] = [address].[address_id]
	left join [mp_star_rating]	as [starRating]	(nolock)	on [contact].[company_id] = [starRating].[company_id]
	left join 
	( 
		select contact_id ,  count(1) noofrfqs from mp_rfq (nolock) where rfq_status_id in (3,5,6,16,17,20)  group by contact_id
	) a on [contact].contact_id = a.contact_id 
	'+@where_query+'
	order by  
		CASE  WHEN @orderbydesc1 =  1 THEN   [contact].[company_ID] END DESC  
		,CASE  WHEN @orderbydesc1 =  1 THEN  CASE WHEN CTE.is_admin = 1 AND CTE.ContactRn = 1 THEN ''Primary Admin'' WHEN CTE.is_admin = 1  AND CTE.ContactRn > 1 THEN ''Secondary Admin'' ELSE ''User'' END END ASC    
		,CASE  WHEN @orderbydesc1 =  1 THEN  CTE.ContactRn END ASC   
		,CASE  WHEN @orderbydesc1 =  0 THEN  [contact].[company_ID] END ASC  
		,CASE  WHEN @orderbydesc1 =  0 THEN  CASE WHEN CTE.is_admin = 1 AND CTE.ContactRn = 1 THEN ''Primary Admin'' WHEN CTE.is_admin = 1  AND CTE.ContactRn > 1 THEN ''Secondary Admin'' ELSE ''User'' END END ASC    
		,CASE  WHEN @orderbydesc1 =  0 THEN  CTE.ContactRn END ASC 
	offset '+convert(varchar(50), @pagesize)+' * ( '+convert(varchar(50), @pagenumber)+' -1) rows	
	fetch next '+convert(varchar(50), @pagesize)+' rows only	
	'
	
	exec sp_executesql @search_query, N'@orderbydesc1  bit', @orderbydesc1  = @orderbydesc
	

end
