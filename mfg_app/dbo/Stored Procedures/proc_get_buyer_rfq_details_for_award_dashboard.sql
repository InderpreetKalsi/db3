

CREATE PROCEDURE  [dbo].[proc_get_buyer_rfq_details_for_award_dashboard]--<Procedure_Name, sysname, ProcedureName> 
@RfqId int,
@PreferredLocation int
AS
BEGIN
	    select   a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, case when category.discipline_name = pcategory.discipline_name 
				   then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, mmtc.territory_classification_name as RfqPreferredLocation		
			 ,(SELECT count(1) from mp_rfq_quote_SupplierQuote (nolock) WHERE rfq_id = @RfqId and is_quote_submitted = 1 and is_rfq_resubmitted = 0) AS QuotesCount
		from  mp_rfq								 a		(nolock)
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		join 
		(
			select 
				distinct
				rfq_id 
				, case
					when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
					else rfq_pref_manufacturing_location_id
				end rfq_pref_manufacturing_location_id
				from 
				mp_rfq_preferences a (nolock)
		) mrp  on a.rfq_id = mrp.rfq_id
		join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
		where a.rfq_id = @RfqId
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @PreferredLocation = 0 THEN mrp.rfq_pref_manufacturing_location_id  
														   ELSE @PreferredLocation END) 

END
