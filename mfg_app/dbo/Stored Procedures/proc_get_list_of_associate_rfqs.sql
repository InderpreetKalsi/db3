
/*

exec proc_get_list_of_associate_rfqs @contact_id =  1055986 ,  @buyer_id = null
exec proc_get_list_of_associate_rfqs @contact_id =  1337795 ,  @buyer_id = 1335855

*/

CREATE procedure [dbo].[proc_get_list_of_associate_rfqs]
(
	@contact_id				int	
	,@buyer_id				int = null
)
as
begin

	/*
		 =============================================
		 Create date: Nov 04,2019
		 Description: M2-2259 Buyer and M - Add a Move To button on the Messages action button to associate a message with an RFQ - DB
		 Modification:
		 =================================================================
	*/
	
	set nocount on
	
	declare @is_buyer bit

	set @is_buyer =  (select is_buyer from mp_contacts (nolock) where contact_id = @contact_id)
	
	if @is_buyer = 1 
	begin

		select 
			distinct 
			a.rfq_id as RFQId  
			, convert(varchar(150),a.rfq_id) + ' - '+ case when len(a.rfq_name) > 15 then substring(a.rfq_name,0,15) + '...'  else rfq_name end as RFQName 
		from mp_rfq (nolock) a
		join mp_rfq_release_history (nolock) b on a.rfq_id = b.rfq_id
		where contact_id = @contact_id
		order by RFQId desc


	end
	else if @is_buyer = 0 and @buyer_id is not null 
	begin
	
		Select 
			RFQId 
			, convert(varchar(150),a.RFQId) + ' - '+ case when len(rfq_name) > 15 then substring(rfq_name,0,15) + '...'  else rfq_name end as RFQName
		from
		(
			select distinct rfq_id as RFQId  from mp_rfq_quote_suplierStatuses (nolock) where contact_id = @contact_id and  rfq_userStatus_id in (1, 2)
			union
			select rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @contact_id and is_rfq_resubmitted = 0 and is_quote_submitted = 1
		) a
		join mp_rfq (nolock) b on a.RFQId = b.rfq_id and b.contact_id = @buyer_id
		order by RFQId desc

	end
	else if @is_buyer = 0 and @buyer_id is  null 
	begin
	
		Select 
			RFQId 
			, convert(varchar(150),a.RFQId) + ' - '+ case when len(rfq_name) > 15 then substring(rfq_name,0,15) + '...'  else rfq_name end as RFQName
		from
		(
			select distinct rfq_id as RFQId  from mp_rfq_quote_suplierStatuses (nolock) where contact_id = @contact_id and  rfq_userStatus_id in (1, 2)
			union
			select rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @contact_id and is_rfq_resubmitted = 0 and is_quote_submitted = 1
		) a
		join mp_rfq (nolock) b on a.RFQId = b.rfq_id 
		order by RFQId desc

	end
end
