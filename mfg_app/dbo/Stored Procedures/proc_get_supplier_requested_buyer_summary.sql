/*
select * from mp_contacts where contact_id in ( 915381,915382) or company_id = 1767999
exec proc_get_supplier_requested_buyer_summary @buyer_id = 1337826 , @supplier_id = 915381
*/
CREATE proc proc_get_supplier_requested_buyer_summary
(
	@buyer_id int
	,@supplier_id int
)
as
begin
	
	/*	M2-2031 M - Buyer Profile - Add the number of RFQ's the buyer has 
		open to the profile and make a clickable link - DB
	*/

	set nocount on


	select 
		a.contact_id	as	BuyerID 
		,b.company_id	as	CompanyId
		,b.name			as	Companyname 
		,(select top 1 file_name from mp_special_files (nolock) where  b.company_id = comp_id and filetype_id = 6 ) as CompanyLogoUrl 
		,a.first_name +' '+a.last_name as ContactPersonName 
		,c.no_of_stars	as	Rating  
		,a.created_on	as	JoinedOn 
		,d.email		as	EmailAddress 
		,case when e.company_id is null then cast('false' as bit) else cast('true' as bit) end  as IsFollowed 
		,MyRate
		,LastRatedOn
	from mp_contacts	(nolock) a
	join mp_companies	(nolock) b on a.company_id = b.company_id
	left join mp_star_rating (nolock) c on b.company_id = c.company_id
	join aspnetusers 	(nolock) d on a.user_id = d.id 
	left join 
	(
		select distinct mbd.company_id from 
		mp_book_details mbd			(nolock)
		join mp_books  mb			(nolock)	on mbd.book_id =mb.book_id
		join mp_mst_book_type mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
			and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
			and mb.contact_id = @supplier_id

	) e on e.company_id = b.company_id 
	left join 
	(

		select 
		@buyer_id as buyer_id, 
		score as MyRate , created_date  as LastRatedOn 
		from mp_rating_responses (nolock) 
		where response_id in 
		(		
			select max(response_id) 
			from mp_rating_responses (nolock) 
			where from_id = @supplier_id
		)

	) f on a.contact_id = f.buyer_id
	where a.contact_id = @buyer_id

	
end
