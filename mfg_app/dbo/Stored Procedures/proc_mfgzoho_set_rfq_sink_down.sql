CREATE procedure [dbo].[proc_mfgzoho_set_rfq_sink_down]
as
begin
/*
	created on	: nov 15, 2018
	M2-452 Create SQL jobs to Import and Export data for RFQ Module
*/

	--declare @todays_date as datetime = getdate()

	-- 1. rfq details
	drop table if exists #tmp_zoho_rfq_details
	
	
		/* fetching zoho rfq details which are not in mfg into tmp table */
		select *
		into #tmp_zoho_rfq_details
		from zoho.dbo.zoho_rfq (nolock) a
		where  a.synctype = 2 and a.issync = 0

		insert into mp_rfq
		(	rfq_name,rfq_description,is_special_certifications_by_manufacturer,is_special_instruction_to_manufacturer,
			is_partial_quoting_allowed,is_register_supplier_quote_the_RFQ,rfq_zoho_id
		)
		select rfq_name, rfq_description, 0, 0, 0, 0 , id from #tmp_zoho_rfq_details

		update zoho.dbo.zoho_rfq set issync = 1 , modified_time = getdate()
		where rfq_id in (select distinct rfq_id  from #tmp_zoho_rfq_details)

end