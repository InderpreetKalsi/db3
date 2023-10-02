
/*

select * from mp_rfq where rfq_id in (1156503,1156504)
select * from mp_messages where rfq_id  in (1156503,1156504)
select * from mp_rfq_supplier_nda_accepted where rfq_id  in (1156503,1156504)
select * from mp_rfq_nda_files where rfq_accepted_nda_id in ()

-- Tab  = 'NDA'
exec proc_get_SupplierNDAStatus 
@RfqId= 1183749
,@ContactId=0  
,@RfqNDAType = 'All'	-- All , Standard , Custom , Declined
,@RfqNDALevel = '2'		-- 2 , 3 (both 1 and 2)
,@RfqNDAStatus = 'All'	-- All , Declined

-- Tab  = 'Standard'
exec proc_get_SupplierNDAStatus 
@RfqId= 0
,@ContactId=1350478
,@RfqNDAType = 'Standard'	-- All , Standard , Custom , Declined
,@RfqNDALevel = '3'			-- 2 , 3 (both 1 and 2)
,@RfqNDAStatus = 'All'		-- All (Viewed and Accepted)  , Declined

-- Tab  = 'Custom'
exec proc_get_SupplierNDAStatus 
@RfqId= 1183749
,@ContactId=0
,@RfqNDAType = 'Custom'		-- All , Standard , Custom , Declined
,@RfqNDALevel = '3'			-- 2 , 3 (both 1 and 2)
,@RfqNDAStatus = 'All'		-- All , Declined

-- Tab  = 'Declined'
exec proc_get_SupplierNDAStatus 
@RfqId= 0
,@ContactId=1350499
,@RfqNDAType = 'Declined'	-- All , Standard , Custom , Declined
,@RfqNDALevel = '3'			-- 2 , 3 (both 1 and 2)
,@RfqNDAStatus = 'Declined'	-- All , Declined

*/
CREATE PROCEDURE [dbo].[proc_get_SupplierNDAStatus]
(
@RfqId int = NULL
,@ContactId int = NULL
,@RfqNDAType varchar(50)   -- All , Standard , Custom , Declined
,@RfqNDALevel int  -- 2 , 3 (both 1 and 2)
,@RfqNDAStatus varchar(50)   -- All , Declined
)
AS
 
-- declare @RfqId int = 0
--,@ContactId int = 1350567
--,@RfqNDAType varchar(50) = 'ALL'   -- All , Standard , Custom , Declined
--,@RfqNDALevel int = 2 -- 2 , 3 (both 1 and 2)
--,@RfqNDAStatus varchar(50) = 'All'  -- All , Declined

-- =============================================
-- Create date: 03 Oct, 2018
-- Description:	Get the data for RFQ NDA status list by Supplier
-- Modification:
-- Example: [proc_get_SupplierNDAStatus] 0,1259577  
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
--			   07 Dec 2018 - dp-Al. L.		  - Made '@RfqId' and '@ContactId' as conditional parameters
-- =================================================================


    /* below code added with M2-4393 */
	drop table if exists #tmp_proc_get_SupplierNDAStatus_RfqNDAType
	create table #tmp_proc_get_SupplierNDAStatus_RfqNDAType (RfqNDAType varchar(50))
	
	drop table if exists #tmp_proc_get_SupplierNDAStatus_RfqNDALevel
	create table #tmp_proc_get_SupplierNDAStatus_RfqNDALevel (RfqNDALevel int)
	
	drop table if exists #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus
	create table #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus (RfqNDAStatus varchar(50))

	drop table if exists #ContactsRfqNDAs
	drop table if exists #RfqNDAs

		   
	if @RfqNDAType = 'All' 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAType values ('Standard'),('Custom')
	else if @RfqNDAType = 'Standard' 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAType values ('Standard')
	else if @RfqNDAType = 'Custom' 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAType values ('Custom')
	else if @RfqNDAType = 'Declined' 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAType values ('Standard'),('Custom')
		
		
	if @RfqNDAType = 'All' and @RfqNDALevel  = 2 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDALevel values (2)
	else if @RfqNDAType in ('Standard' , 'Custom' , 'Declined') and @RfqNDALevel  = 3  
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDALevel values (1), (2)
	 
	
	if @RfqNDAType = 'All' and  @RfqNDAStatus  = 'All'  -- Viewed & Approved 
		--insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus values ('Viewed'),('Accepted')
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus values ('Viewed'), ('undefined') ---- modified 4441
	else if @RfqNDAType in ('Standard' , 'Custom' ) and  @RfqNDAStatus  = 'All' 
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus values ('Viewed'),('Accepted'), ('undefined')  
	else if @RfqNDAType in ('Declined' ) and  @RfqNDAStatus  = 'Declined'  
		insert into #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus values ('Declined')

	/* End with M2-4393 */
	 
BEGIN
 


IF((ISNULL(@RfqId,0) > 0))
--NDA tab On Buyer side
BEGIN


select * into #RfqNDAs
from (
	SELECT
	distinct
	r.rfq_id
	,r.[rfq_name]
	,r.rfq_status_id
	, authorCompany.name as COMP_NAME
	--, r.contact_id as RFQ_CONTACTID
	, authorCont.contact_id
	, authorcont.first_name + ' ' + authorcont.last_name as ContName 
	,mp_star_rating.no_of_stars AS NoOfStars
	,NdaAccepted.prefered_nda_type_accepted_date as NDAAcceptedDate
	, (select top 1 communication_value from mp_communication_details (nolock) d where d.communication_type_id = 1 and d.contact_id = authorcont.contact_id) as Telephone
	, (
		select 
			country.ISO_CODE + ' ' + r.REGION_NAME  as SalesOffice
		from 
			mp_contacts c  (nolock) 
			inner join mp_addresses a   (nolock) 
				on a.address_id = c.ADDRESS_ID 
			left join mp_mst_country country   (nolock) 
				on country.country_id = a.country_id 
			left join mp_mst_region r       (nolock) 
				on r.region_id =a.region_id 
		where 
			c.contact_id = authorcont.contact_id 
	) as SalesOffice
	, m.MESSAGE_STATUS_ID_AUTHOR
	, case when authorStatus.MESSAGE_STATUS_TOKEN = 'undefined' then 'Viewed' else  authorStatus.MESSAGE_STATUS_TOKEN end  MESSAGE_STATUS_TOKEN
	, m.message_date
	--- below columns added with M2-4393
	, r.pref_NDA_Type 
	, case when r.pref_NDA_Type = 1 then 'Single Confirm'  else 'Double Confirm' end AS RfqNDALevel
	, case 
		when r.pref_NDA_Type = 1 then 
			case 
				when mp_rfq_nda_files.file_id is null then 'Standard' 
				else 'Custom' 
			end
		else
			case 
				when mp_rfq_nda_files.file_id is null then 'Standard' 
				else 'Custom' 
			end
	 end AS RfqNDAType 
	from 
	mp_rfq r  (nolock) 
	left join mp_rfq_supplier_nda_accepted NdaAccepted  (nolock)  on r.rfq_id=NdaAccepted.rfq_id --And NdaAccepted.contact_id=@ContactId--

	left join 
	(
	select a.* from mp_messages a  (nolock) 
		join 
		(select RFQ_ID , to_cont, min(message_id)  message_id from mp_messages mess  (nolock)  
		join mp_mst_message_types mmmt  (nolock)  on  mess.MESSAGE_TYPE_ID = mmmt.MESSAGE_TYPE_ID 
		where message_type_name in ('rfqPermissionRequest', 'MESSAGE_TYPE_CONFIDENTIALITY_AGREEMENT', 'RFQ_RELEASED_BY_ENGINEERING','RFQ_EDITED_RESUBMIT_QUOTE') 
		group by RFQ_ID , to_cont  ) b on a.message_id = b.message_id -- add to_contact in group by for proper message status
	
	
	)m 
		on m.RFQ_ID = r.RFQ_ID   
		and NdaAccepted.contact_id = m.to_cont  -- add after adding to_contact in group by 
		--and m.mESSAGE_TYPE_ID in (2, 42,149,155) -- NDA
		and m.mESSAGE_TYPE_ID in (2, 42,203,208,202) -- NDA
	left join mp_mst_message_types mt  (nolock) 
		on mt.MESSAGE_TYPE_ID = m.MESSAGE_TYPE_ID
	inner join mp_contacts authorCont  (nolock) 
	on authorCont.contact_id =NdaAccepted.contact_id
			--on authorCont.contact_id = m.FROM_CONT
    left join mp_star_rating  (nolock)  on authorCont.company_id =mp_star_rating.company_id 
   	inner join mp_companies authorCompany  (nolock) 
		on authorCompany.company_id = authorcont.company_id
	left join mp_mst_message_status authorStatus  (nolock) 
		on authorStatus.MESSAGE_STATUS_ID = m.MESSAGE_STATUS_ID_AUTHOR
	left join mp_mst_message_status recipientStatus  (nolock) 
		on recipientStatus.message_status_id = m.MESSAGE_STATUS_ID_RECIPIENT
	left join mp_messages ndaRevoked  (nolock) 
		on ndaRevoked.MESSAGE_HIERARCHY = m.MESSAGE_ID
		and ndaRevoked.MESSAGE_TYPE_ID = 46 -- revoked
		and ndaRevoked.IS_LAST_MESSAGE = 1
	----- below two join added with M2-4393
	left join mp_rfq_accepted_nda  (nolock) on mp_rfq_accepted_nda.rfq_id = r.rfq_id and mp_rfq_accepted_nda.status_id = 2
	left join mp_rfq_nda_files (nolock) on mp_rfq_nda_files.rfq_accepted_nda_id = mp_rfq_accepted_nda.rfq_accepted_nda_id
	where
		r.rfq_id = @RfqId 
	----AND Quotes_needed_by >= GETDATE()	---M2-4185  commented this condition M2-4532
	AND rfq_status_id !=5 --M2--4532
	and authorcont.is_active = 1 -- Contact still active.
	) RfqNDAs 
where
	 --- below condition added with M2-4393
	 pref_NDA_Type in  (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDALevel) 
	 and  MESSAGE_STATUS_TOKEN in  (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus) 
	 and RfqNDAType in (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDAType)
--order by rfq_id  desc, contact_id 

	if @RfqNDAType in ('Standard' , 'Custom' , 'Declined') and @RfqNDALevel  = 3  
    delete from #RfqNDAs where message_status_token = 'Viewed' and pref_NDA_Type = 2

	---- Final resultset
	select * from #RfqNDAs order by rfq_id desc, contact_id 

END

ELSE IF(ISNULL(@ContactId,0) > 0) --Added for returning the List of RFQs for a Contact Id
-- NDA's to Approve
BEGIN
--Declare @IsApprove int
--select * from mp_rfq_supplier_nda_accepted where contact_id=1350567


select * into #ContactsRfqNDAs
from 
(
	SELECT
		r.rfq_id
		,r.[rfq_name]
		,r.rfq_status_id
		 ,CASE 
		 WHEN NdaAccepted.contact_id>0 THEN 1
		 ELSE 0
		 END AS ISApprove
		, authorCompany.name as COMP_NAME
		--, r.contact_id as RFQ_CONTACTID
		, authorCont.contact_id
		,mp_star_rating.no_of_stars AS NoOfStars
		, authorcont.first_name + ' ' + authorcont.last_name as ContName
		,NdaAccepted.prefered_nda_type_accepted_date as NDAAcceptedDate
		, (select top 1 communication_value from mp_communication_details d  (nolock)  where d.communication_type_id = 1 and d.contact_id = authorcont.contact_id) as Telephone
		, (
			select 
				country.ISO_CODE + ' ' + r.REGION_NAME  as SalesOffice
			from 
				mp_contacts c   (nolock) 
				inner join mp_addresses a   (nolock) 
					on a.address_id = c.ADDRESS_ID 
				left join mp_mst_country country   (nolock) 
					on country.country_id = a.country_id 
				left join mp_mst_region r       (nolock) 
					on r.region_id =a.region_id 
			where 
				c.contact_id = authorcont.contact_id 
		) as SalesOffice
		, m.MESSAGE_STATUS_ID_AUTHOR
		, case when authorStatus.MESSAGE_STATUS_TOKEN = 'undefined' then 'Viewed' else  authorStatus.MESSAGE_STATUS_TOKEN end  MESSAGE_STATUS_TOKEN
		, m.message_date
		--- below columns added with M2-4393
		, r.pref_NDA_Type
		, case when r.pref_NDA_Type = 1 then 'Single Confirm'  else 'Double Confirm' end AS RfqNDALevel
		, case 
			when r.pref_NDA_Type = 1 then 
				case 
					when mp_rfq_nda_files.file_id is null then 'Standard' 
					else 'Custom' 
				end
			else
				case 
					when mp_rfq_nda_files.file_id is null then 'Standard' 
					else 'Custom' 
				end
		 end AS RfqNDAType 
		from
		mp_rfq r  (nolock) 
		left join mp_rfq_supplier_nda_accepted NdaAccepted  (nolock) on r.rfq_id=NdaAccepted.rfq_id --And NdaAccepted.contact_id=@ContactId--
		left join 
		(
		select a.* from mp_messages a  (nolock) 
			join 
			(select RFQ_ID , to_cont, min(message_id)  message_id from mp_messages mess  (nolock)  join mp_mst_message_types mmmt  (nolock)  on  mess.MESSAGE_TYPE_ID = mmmt.MESSAGE_TYPE_ID 
			where message_type_name in ('rfqPermissionRequest', 'MESSAGE_TYPE_CONFIDENTIALITY_AGREEMENT', 'RFQ_RELEASED_BY_ENGINEERING','RFQ_EDITED_RESUBMIT_QUOTE') 
			group by RFQ_ID , to_cont  ) b on a.message_id = b.message_id -- add to_contact in group by for proper message status
	
		)
		 m  --inner
			on m.RFQ_ID = r.RFQ_ID    
			and NdaAccepted.contact_id = m.to_cont  -- add after adding to_contact in group by 
			--and m.mESSAGE_TYPE_ID in (2, 42) -- NDA
			--and m.mESSAGE_TYPE_ID in (2, 42, 149,155) -- NDA
			and m.mESSAGE_TYPE_ID in (2, 42,203,208,202) -- NDA

		left join mp_mst_message_types mt  --inner  (nolock) 
			on mt.MESSAGE_TYPE_ID = m.MESSAGE_TYPE_ID

		----------------inner join mp_contacts authorCont
		----------------	on authorCont.contact_id = m.REAL_FROM_CONT_ID
		--------****Change in Join
			----inner join mp_contacts authorCont
			----on authorCont.contact_id = r.contact_id
			inner join mp_contacts authorCont  (nolock) 
			on authorCont.contact_id = NdaAccepted.contact_id
		left join mp_star_rating  (nolock)  on authorCont.company_id =mp_star_rating.company_id
		inner join mp_companies authorCompany  (nolock) 
			on authorCompany.company_id = authorcont.company_id
		left join mp_mst_message_status authorStatus   (nolock)  --inner  (nolock) 
			on authorStatus.MESSAGE_STATUS_ID = m.MESSAGE_STATUS_ID_AUTHOR
		----------------inner join mp_mst_message_status recipientStatus
		----------------	on recipientStatus.message_status_id = m.MESSAGE_STATUS_ID_RECIPIENT
		left join mp_messages ndaRevoked  (nolock) 
			on ndaRevoked.MESSAGE_HIERARCHY = m.MESSAGE_ID
			and ndaRevoked.MESSAGE_TYPE_ID = 46 -- revoked
			and ndaRevoked.IS_LAST_MESSAGE = 1
		----- below two join added with M2-4393
		left join mp_rfq_accepted_nda  (nolock) on mp_rfq_accepted_nda.rfq_id = r.rfq_id and mp_rfq_accepted_nda.status_id = 2
		left join mp_rfq_nda_files (nolock) on mp_rfq_nda_files.rfq_accepted_nda_id = mp_rfq_accepted_nda.rfq_accepted_nda_id
 
		where
		
		r.contact_id = @ContactId
		AND authorcont.is_active = 1 -- Contact still active.
		AND rfq_status_id !=5 --M2--4532
		
) RfqNDAs 
where
	--- below condition added with M2-4393
	 pref_NDA_Type in  (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDALevel) 
	 and MESSAGE_STATUS_TOKEN in  (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDAStatus) 
	 and RfqNDAType in (select * from #tmp_proc_get_SupplierNDAStatus_RfqNDAType)
	

--order by rfq_id desc, contact_id 

	if @RfqNDAType in ('Standard' , 'Custom' , 'Declined') and @RfqNDALevel  = 3  
    delete from #ContactsRfqNDAs where message_status_token = 'Viewed' and pref_NDA_Type = 2

	---- Final resultset
	select * from #ContactsRfqNDAs order by rfq_id desc, contact_id 
 
END

END
