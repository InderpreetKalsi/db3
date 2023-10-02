/*

declare @default_value int 
exec [proc_get_qms_currency_decimals] 
@supplier_company_id = 1768056  
,@supplier_id =  1337894 
, @defaultValue = @default_value output
select @default_value

*/
CREATE procedure [dbo].[proc_get_qms_currency_decimals]
(
	@supplier_company_id	int
	,@supplier_id			int
	,@defaultValue			int output
	
)
as
begin

	/*  M2-2585 M - QMS Settings - Add Decimal Places to Display - DB */

	set nocount on

	select qms_currency_decimal_id QMSCurrencyDecimalId,qms_currency_decimal as QMSCurrencyDecimal , cast('false' as bit) as IsRemovable 
	from mp_mst_qms_currency_decimals
	order by sort_order

	set @defaultValue =  
	(		
			select default_value 
			from mp_qms_user_quote_settings (nolock)
			where contact_id = @supplier_id and qms_quote_setting_id = 8
	)

	if @defaultValue is null
		set @defaultValue = 104


end
