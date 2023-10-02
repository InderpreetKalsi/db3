/*
declare @default_Value int

exec proc_get_qms_custom_cost
@supplier_company_id	=1768056
,@supplier_id			=1337894
,@defaultValue =  @default_Value  output

select @default_Value 


*/


CREATE procedure [dbo].[proc_get_qms_custom_cost]
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

	
	select 
		qms_fee_type_id as Id ,fee_type as Costname  , cast('true' as bit)  as IsDefault  ,  cast('false' as bit)  as IsRemovable
	from mp_mst_qms_fee_types (nolock) where qms_fee_type_id <> 1
	union
	select 
		qms_dynamic_fee_type_id as Id	,fee_type as Costname, cast('false' as bit)  as IsDefault   
		,  
		case 
			when ((select count(1) from mp_qms_quote_feetype_mapping (nolock) where  qms_dynamic_fee_type_id = a.qms_dynamic_fee_type_id) = 0) then cast('true' as bit) 
			else cast('false' as bit) 
		end as IsRemovable

	from mp_mst_qms_dynamic_fee_types (nolock) a 
	where supplier_company_id = @supplier_company_id and is_active = 1
	order by Id
	
	set @defaultValue =  
	(		
		select default_value 
		from mp_qms_user_quote_settings (nolock)
		where contact_id = @supplier_id and qms_quote_setting_id = 5
	)
	
end
