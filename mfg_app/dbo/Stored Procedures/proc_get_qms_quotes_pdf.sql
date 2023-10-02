

/*
	exec [proc_get_qms_quotes_pdf] @qms_quote_id=184

*/
CREATE procedure [dbo].[proc_get_qms_quotes_pdf]
(
@qms_quote_id	int
)
as
begin
	set nocount on
	/*
	M2-1900 M - Step 4 Review Quote - PDF preview window - DB
	*/
		declare @listfeetypes nvarchar(max)
		declare @sql_query varchar(max)
		declare @supplier_company_id int

		drop table if exists #tmp_quote_feetypes
		drop table if exists ##tmp_quote_feetypes1


		set @supplier_company_id  = 
			(
				select e.company_id 
				from mp_qms_quotes	(nolock)	a
				join mp_contacts			(nolock)	e on a.created_by = e.contact_id  where qms_quote_id = @qms_quote_id 
			)


		select  a.qms_quote_id , b.qms_quote_part_id , c.qms_quote_part_qty_id , c.part_qty, qty_level , fee_type_id , fee_type , value
		into #tmp_quote_feetypes
		from 
		mp_qms_quotes							(nolock)	a
		join mp_qms_quote_parts					(nolock)	b on a.qms_quote_id = b.qms_quote_id 
		join mp_qms_quote_part_quantities		(nolock)    c on b.qms_quote_part_id = c.qms_quote_part_id and c.is_deleted = 0
		join mp_contacts						(nolock)	e on a.created_by = e.contact_id
		join mp_qms_quote_part_qty_fee_types	(nolock)    d on c.qms_quote_part_qty_id = d.qms_quote_part_qty_id
		left join 
		(
			select qms_fee_type_id  ,fee_type
			from mp_mst_qms_fee_types (nolock) 
			union
			select qms_dynamic_fee_type_id as QMSFeeTypeId,fee_type as FeeType
			from mp_mst_qms_dynamic_fee_types (nolock) a 
			where supplier_company_id = @supplier_company_id 
			
		) f on d.fee_type_id = f.qms_fee_type_id
		where a.qms_quote_id = @qms_quote_id
		order by a.qms_quote_id , b.qms_quote_part_id , c.part_qty , fee_type_id
     
	 --select distinct
		--		qms_quote_id,	qms_quote_part_id	, qms_quote_part_qty_id	, qty_level ,
		--		(
		--			select value 
		--			from #tmp_quote_feetypes 
		--			where 
		--				qms_quote_id= a.qms_quote_id 
		--				and qms_quote_part_id = a.qms_quote_part_id 
		--				and qms_quote_part_qty_id= a.qms_quote_part_qty_id
		--				and qty_level= a.qty_level
		--				and fee_type_id = 1
		--		) per_unit_price
		--		,(
		--			select sum(value)
		--			from #tmp_quote_feetypes 
		--			where 
		--				qms_quote_id= a.qms_quote_id 
		--				and qms_quote_part_id = a.qms_quote_part_id 
		--				and qms_quote_part_qty_id= a.qms_quote_part_qty_id
		--				and qty_level= a.qty_level
		--				and fee_type_id <> 1
		--		) miscellaneous_cost

		--	from   #tmp_quote_feetypes  a




		select 
			a.quote_id
			, a.qms_quote_name as quote_name
			, a.quote_ref_no as quote_ref_no
			, a.created_date as quote_date
			, a.quote_valid_until as quote_valid_until
			, a.probability as probability
			, b.company as customer_company
			, (isnull(b.address,'') +','  +char(13) + char(10)+ isnull(city,'')+',' +char(13) + char(10)+ isnull(b.state,'')+','  +char(13) + char(10)+ isnull(b.zip_code,'')+','+char(13) + char(10)+ isnull(o.iso_code,''))   as customer_company_address
			, isnull(b.first_name,'') +' ' + isnull(b.last_name,'') as customer_name 
			, b.email as customer_email
			, b.phone as customer_phone
			, c.qms_quote_part_id
			, c.part_name
			, c.part_no
			, c.created_date as qms_quote_part_creation_date
			, a.payment_term_id
			, a.shipping_method_id
			, q.value as payment_terms
			, r.value as shipping_terms
			, a.estimated_delivery_date
			, a.notes
			, s.qms_process as process
			, t.qms_post_production as post_production
			, u.qms_material  as material
			, w.FILE_NAME as primary_part_file
			, a.created_by			 
			, case when a.is_active = 0 then cast('false' as bit) when a.is_active = 1 then cast('true' as bit)  end as is_active
			, case when a.is_notified = 0 then cast('false' as bit) when a.is_notified = 1 then cast('true' as bit)  end as is_notified
			, a.qms_contact_id
			, a.status_id
			, c.is_accepted 
			, p.qms_quote_part_id
			, p.part_qty
			, x.value as part_qty_unit
			, p.qms_quote_part_qty_id
			/* M2-2590 M - QMS - Reorder the Quantities on the Review page - DB */
			--, p.qty_level
			, (row_number() over(partition by a.quote_id , c.qms_quote_part_id   order by a.quote_id , c.qms_quote_part_id , p.part_qty , p.qms_quote_part_qty_id) -1)qty_level
			/**/
			, convert(decimal(20,4),(p.part_qty * isnull(y.per_unit_price,0) ) + isnull(y.miscellaneous_cost,0)) as qty_level_sum
			, a.email_status_id
			, c.qms_part_status_id
			, a.who_pays_for_shipping
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		left join mp_mst_country			(nolock) o on b.country_id = o.country_id
		left join mp_qms_quote_parts		(nolock) c on a.qms_quote_id = c.qms_quote_id 
		left join mp_qms_quote_part_files    (nolock) v on c.qms_quote_part_id = v.qms_quote_part_id  and v.is_primary = 1 and v.status_id = 2
		left join mp_special_files				(nolock) w on v.file_id = w.file_id  and w.FILETYPE_ID = 108 and w.IS_DELETED = 0
		left join mp_qms_quote_part_quantities	(nolock) p on c.qms_quote_part_id = p.qms_quote_part_id and p.is_deleted = 0
		left join mp_system_parameters		(nolock) x on p.part_qty_unit_id = x.id and x.sys_key = '@UNIT2_LIST'
		left join 
		(
			select id , value from mp_system_parameters	(nolock) where sys_key = '@QMS_PAYMENT_TERMS' 
			union 
			select qms_additional_payment_term_id, payment_terms from mp_mst_qms_additional_payment_terms	(nolock) where supplier_company_id= @supplier_company_id
		)  q on a.payment_term_id = q.id 
		left join 
		(
			select id , value from mp_system_parameters	(nolock) where sys_key = '@QMS_SHIPPING_TERMS' 
			union 
			select qms_additional_shipping_method_id, shipping_methods from mp_mst_qms_additional_shipping_methods	(nolock) where supplier_company_id= @supplier_company_id
		) r on a.shipping_method_id = r.id 
		left join mp_mst_qms_processes		(nolock) s on c.part_category_id = s.qms_process_id 
		left join mp_mst_qms_post_productions  	(nolock) t on c.post_production_id = t.qms_post_production_id 
		left join mp_mst_qms_materials		(nolock) u on c.material_id = u.qms_material_id 
		--left join mp_mst_region				(nolock) on b.state_id = mp_mst_region.region_id 
		left join 
		(
			select distinct
				qms_quote_id,	qms_quote_part_id	, qms_quote_part_qty_id	,  qty_level ,
				(
					select value 
					from #tmp_quote_feetypes 
					where 
						qms_quote_id= a.qms_quote_id 
						and qms_quote_part_id = a.qms_quote_part_id 
						and qms_quote_part_qty_id= a.qms_quote_part_qty_id
						and qty_level= a.qty_level
						and fee_type_id = 1
				) per_unit_price
				,(
					select sum(value)
					from #tmp_quote_feetypes 
					where 
						qms_quote_id= a.qms_quote_id 
						and qms_quote_part_id = a.qms_quote_part_id 
						and qms_quote_part_qty_id= a.qms_quote_part_qty_id
						and qty_level= a.qty_level
						and fee_type_id <> 1
				) miscellaneous_cost

			from   #tmp_quote_feetypes  a
		) y on 
			a.qms_quote_id= y.qms_quote_id 
			and p.qms_quote_part_id = y.qms_quote_part_id 
			and p.qms_quote_part_qty_id= y.qms_quote_part_qty_id
			and p.qty_level= y.qty_level
		where a.qms_quote_id = @qms_quote_id
		order by a.qms_quote_id, p.qms_quote_part_id ,p.part_qty

		select 
			qms_quote_id	,qms_quote_part_id	,qms_quote_part_qty_id	,part_qty	
			/* M2-2590 M - QMS - Reorder the Quantities on the Review page - DB */
			--,qty_level	
			,(dense_rank() over(partition by qms_quote_id , qms_quote_part_id   order by qms_quote_id , qms_quote_part_id , part_qty , qms_quote_part_qty_id) -1) as qty_level
			--,(dense_rank() over(partition by qms_quote_id,	qms_quote_part_id	 order by qms_quote_id,	qms_quote_part_id	,part_qty ) -1) as qty_level
			/**/
			,fee_type_id	,fee_type	,value
		from #tmp_quote_feetypes  
		

		/* M2-2503 M - QMS Step 2 - Add an independent fee type box with price, no quantity - DB */
		select  a.qms_quote_id QMSQuoteId, b.qms_quote_part_id QMSQuotePartId, fee_type_id SpecialFeeTypeId, fee_type SpecialFeeType , value SpecialFeeTypeValue
		
		from 
		mp_qms_quotes							(nolock)	a
		join mp_qms_quote_parts					(nolock)	b on a.qms_quote_id = b.qms_quote_id 
		join mp_qms_quote_part_special_fees		(nolock)    c on b.qms_quote_part_id = c.qms_quote_part_id and c.is_deleted = 0
		left join 
		(
			select qms_fee_type_id  ,fee_type
			from mp_mst_qms_fee_types (nolock) 
			union
			select qms_dynamic_fee_type_id as QMSFeeTypeId,fee_type as FeeType
			from mp_mst_qms_dynamic_fee_types (nolock) a 
			where supplier_company_id = @supplier_company_id 			
		) f on c.fee_type_id = f.qms_fee_type_id		
		where a.qms_quote_id = @qms_quote_id
		/**/


		/* M2-2503 M - QMS Step 2 - Add an independent fee type box with price, no quantity - DB */
		select  
			a.qms_quote_id QMSQuoteId
			, b.lead_time_id QMSLeadTimeId
			, lead_time as QMSLeadTime
			, lead_time_value as QMSLeadTimeValue
			, lead_time_range as QMSLeadTimeRange
		
		from 
		mp_qms_quotes	(nolock)	a
		join mp_qms_quote_lead_times (nolock)	b on a.qms_quote_id = b.qms_quote_id
		left join 
		(
			select qms_lead_time_id  ,lead_time
			from mp_mst_qms_lead_time (nolock) 
			union
			select qms_additional_lead_time_id ,lead_time 
			from mp_mst_qms_additional_lead_time (nolock) a 
			where supplier_company_id = @supplier_company_id 
			
		) f on b.lead_time_id = f.qms_lead_time_id
		where a.qms_quote_id = @qms_quote_id
		order by qms_quote_lead_time_id 

		/* M2-2505 M - QMS Step 2 part drawer - Add the profile certifications module to the bottom of the part drawer - DB */
		select 
			a.qms_quote_id as QMSQuoteId
			,b.qms_quote_part_id as QMSQuotePartId
			,c.certificate_id as QMSQuotePartCertificateId
			,d.certificate_code as QMSQuotePartCertificates
		from mp_qms_quotes						(nolock)	a
		join mp_qms_quote_parts					(nolock)	b on a.qms_quote_id = b.qms_quote_id 
		join mp_qms_quote_part_certificates		(nolock)	c on b.qms_quote_part_id = c.qms_quote_part_id
		join mp_certificates					(nolock)	d on c.certificate_id = d.certificate_id
		where a.qms_quote_id = @qms_quote_id 
		order by QMSQuoteId , QMSQuotePartId


		drop table if exists #tmp_quote_feetypes
		

end
