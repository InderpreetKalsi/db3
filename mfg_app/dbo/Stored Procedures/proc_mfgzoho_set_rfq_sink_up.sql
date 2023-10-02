CREATE procedure [dbo].[proc_mfgzoho_set_rfq_sink_up]
as
begin
/*
	created on	: nov 15, 2018
	M2-452 Create SQL jobs to Import and Export data for RFQ Module
*/

	declare @todays_date as datetime = getdate()

	-- 1. rfq details
	drop table if exists #tmp_mfg_rfq_details
	
	
		/* fetching mfg rfq details which are not in zoho into tmp table */
		select
			 distinct rfq_id, isnull(rfq_name,'') rfq_name , rfq_description into #tmp_mfg_rfq_details
		from mp_rfq (nolock) a
		where a.rfq_id not in 
		(
			select distinct mfglegacyrfqid from zoho.dbo.zoho_rfq where synctype = 1
		)
		and rfq_zoho_id is null
		
		/* inserting into zoho rfq table using above tmp table */
		insert into zoho.dbo.zoho_rfq
		(rfq_name, rfq_description, mfglegacyrfqid, created_time, synctype, issync)
		select rfq_name, rfq_description,  rfq_id, @todays_date, 1 , 0 from #tmp_mfg_rfq_details 

end