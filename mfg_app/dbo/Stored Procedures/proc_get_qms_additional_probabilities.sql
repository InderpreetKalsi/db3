

/*
declare @default_Value int

exec [proc_get_qms_additional_probabilities]
@supplier_company_id	=1768056
,@supplier_id			=1337894
,@defaultValue =  @default_Value  output

select @default_Value 


*/

CREATE procedure [dbo].[proc_get_qms_additional_probabilities]
(
	@supplier_company_id	int,
	@supplier_id			int,
	@defaultValue			int output
)
as
begin
	/*
		Jan 27, 2019 - M2-2583 M - QMS Settings - Add Probability and Status as a list that can be added to - DB
	*/
		
	set nocount on


	select qms_status_id QMSProbabilityId , description QMSProbability , cast('true' as bit)  as IsDefault ,  cast('false' as bit)  as IsRemovable  
	from mp_mst_qms_status where  is_active = 1 and sys_key in ( 'PROBABILITY')
	union 
	select mp_mst_qms_additional_probability_id , probability , cast('false' as bit)  as IsDefault   
	,  case 
			when 
				(
					(
						select count(1) from mp_qms_quotes (nolock)  a1
						where  a1.created_by = @supplier_id and a1.probability  = a.mp_mst_qms_additional_probability_id) = 0
				) then cast('true' as bit) 
			else cast('false' as bit) 
		end as IsRemovable
	from mp_mst_qms_additional_probabilities a 
	where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
	order by QMSProbabilityId

	set @defaultValue =  
	(		
		select default_value 
		from mp_qms_user_quote_settings (nolock)
		where contact_id = @supplier_id and qms_quote_setting_id = 9
	)

end
