/*
-- exec  proc_get_qms_fee_types @supplier_company_id = 1768956 , @qms_quote_id = 66

select * from mp_qms_quote_feetype_mapping
select * from mp_qms_quote_parts where qms_quote_id = 55
drop table if exists mp_qms_quote_feetype_mapping

create table mp_qms_quote_feetype_mapping
(
qms_quote_feetype_mapping_id	int identity(1,1),
qms_quote_id	int  ,
qms_quote_part_id	int,
qms_dynamic_fee_type_id	int ,
primary key (qms_quote_feetype_mapping_id,qms_quote_id)
)

insert into mp_qms_quote_feetype_mapping
(qms_quote_id,qms_quote_part_id,qms_dynamic_fee_type_id)
select  55 , 68 , 1118

select * from mp_mst_qms_dynamic_fee_types
select * from mp_contacts where contact_id = 1337827


exec proc_get_qms_quote_invoice_fee_types
@supplier_company_id = 1767999
,@qms_quote_id = 2152
,@qms_quote_part_id = 4259
,@qty_level  = 1

*/
CREATE procedure [dbo].[proc_get_qms_quote_invoice_fee_types]
(
	@supplier_company_id int	
	,@qms_quote_id int	
	,@qms_quote_part_id int
	,@qty_level smallint
)
as
begin

	set nocount on
	/* M2-2045 M - QMS Step 2 - Add an Other selection to the Price list and allow the user to add their own label - DB*/
	

	--select * from mp_qms_quotes where qms_quote_id = 2152
	--select * from mp_qms_quote_parts where  qms_quote_id = 2152
	--select * from mp_qms_quote_part_quantities where  qms_quote_part_id in (select qms_quote_part_id from mp_qms_quote_parts where  qms_quote_id = 2152)
	--select * from mp_qms_quote_part_qty_fee_types where qms_quote_part_qty_id in ( 	select qms_quote_part_qty_id from mp_qms_quote_part_quantities where  qms_quote_part_id in (select qms_quote_part_id from mp_qms_quote_parts where  qms_quote_id = 2152))

	
	select a.* , b.value as UnitPrice
	from
	(
		select 
			qms_fee_type_id as QMSFeeTypeId 
			,fee_type as FeeType 
			, null IsDefault  
		from mp_mst_qms_fee_types (nolock) 
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
	
	) a
	left join 
	(
	
		select 
			d.fee_type_id , d.value 	
		from mp_qms_quotes						a (nolock)
		join mp_qms_quote_parts					b (nolock)  on  a.qms_quote_id = b.qms_quote_id
		join mp_qms_quote_part_quantities		c (nolock)  on   b.qms_quote_part_id =  c.qms_quote_part_id and c.is_deleted = 0
		join mp_qms_quote_part_qty_fee_types	d (nolock) on c.qms_quote_part_qty_id = d.qms_quote_part_qty_id
		where a.qms_quote_id = @qms_quote_id 
		and b.qms_quote_part_id = @qms_quote_part_id
		and c.qty_level =  @qty_level
	
	) b on a.QMSFeeTypeId = b.fee_type_id

end
