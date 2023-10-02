﻿
/*
declare @default_Value int

exec proc_get_qms_additional_shipping_methods
@supplier_company_id	=1768056
,@supplier_id			=1337894
,@defaultValue =  @default_Value  output

select @default_Value 


*/

CREATE procedure [dbo].[proc_get_qms_additional_shipping_methods]
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

	select id QMSShippingMethodId , value QMSPaymentTerms , cast('true' as bit)  as IsDefault ,  cast('false' as bit)  as IsRemovable  from mp_system_parameters where sys_key = '@QMS_SHIPPING_TERMS' and  active = 1
	union 
	select qms_additional_shipping_method_id , shipping_methods , cast('false' as bit)  as IsDefault   
	,  case 
			when ((select count(1) from mp_qms_quotes (nolock) where  created_by = @supplier_id and shipping_method_id  = a.qms_additional_shipping_method_id) = 0) then cast('true' as bit) 
			else cast('false' as bit) 
		end as IsRemovable
	from mp_mst_qms_additional_shipping_methods a 
	where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
	order by QMSShippingMethodId

	set @defaultValue =  
	(		
		select default_value 
		from mp_qms_user_quote_settings (nolock)
		where contact_id = @supplier_id and qms_quote_setting_id = 6
	)


end
