/*
declare @default_Value int

exec proc_get_qms_additional_lead_time
@supplier_company_id	=1768056
,@supplier_id			=1337894
,@defaultValue =  @default_Value  output

select @default_Value 


*/


CREATE procedure [dbo].[proc_get_qms_additional_lead_time]
(
	@supplier_company_id	int,
	@supplier_id			int,
	@defaultValue			int output
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	set nocount on


	select qms_lead_time_id QMSLeadTimeId , lead_time QMSLeadTime , cast('true' as bit)  as IsDefault ,  cast('false' as bit)  as IsRemovable  
	from mp_mst_qms_lead_time where  is_active = 1
	union 
	select qms_additional_lead_time_id , lead_time , cast('false' as bit)  as IsDefault   
	,  case 
			when 
				(
					(
						select count(1) from mp_qms_quotes (nolock)  a1
						join mp_qms_quote_lead_times (nolock) b on a1.qms_quote_id = b.qms_quote_id
						where  a1.created_by = @supplier_id and b.qms_quote_lead_time_id  = a.qms_additional_lead_time_id) = 0
				) then cast('true' as bit) 
			else cast('false' as bit) 
		end as IsRemovable
	from mp_mst_qms_additional_lead_time a 
	where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
	order by QMSLeadTimeId

	set @defaultValue =  
	(		
		select default_value 
		from mp_qms_user_quote_settings (nolock)
		where contact_id = @supplier_id and qms_quote_setting_id = 7
	)

end


--select * from mp_qms_quotes (nolock) where shipping_method_id in (select qms_additional_shipping_method_id from mp_mst_qms_additional_shipping_methods)
--select * from mp_mst_qms_additional_shipping_methods

--update mp_qms_quotes set  payment_term_id = 2014 where qms_quote_id = 2155
