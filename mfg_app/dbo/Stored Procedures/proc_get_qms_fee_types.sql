/*
exec  proc_get_qms_fee_types @supplier_company_id = 1768956 , @qms_quote_id = 66

*/
CREATE procedure [dbo].[proc_get_qms_fee_types]
(
	@supplier_company_id int	
	,@qms_quote_id int	
)
as
begin

	set nocount on
	/* M2-2045 M - QMS Step 2 - Add an Other selection to the Price list and allow the user to add their own label - DB*/
	
	
	select 
		qms_fee_type_id as QMSFeeTypeId 
		,fee_type as FeeType 
		, null IsDefault  
	from mp_mst_qms_fee_types (nolock) where qms_fee_type_id <> 1
	union
	select 
		qms_dynamic_fee_type_id as QMSFeeTypeId
		,fee_type as FeeType
		, case when is_default = 0 then cast('false' as bit) else cast('true' as bit)  end as IsDefault
	from mp_mst_qms_dynamic_fee_types (nolock) a 
	where supplier_company_id = @supplier_company_id and is_default = 1
	union 
	select distinct
		a.qms_dynamic_fee_type_id as QMSFeeTypeId
		,fee_type as FeeType
		, case when is_default = 0 then cast('false' as bit) else cast('true' as bit)  end as IsDefault
	from mp_mst_qms_dynamic_fee_types (nolock) a 
	join mp_qms_quote_feetype_mapping (nolock) b on 
		a.qms_dynamic_fee_type_id = b.qms_dynamic_fee_type_id 
		and b.qms_quote_id = @qms_quote_id
	where a.supplier_company_id = @supplier_company_id 
	order by qms_fee_type_id

end
