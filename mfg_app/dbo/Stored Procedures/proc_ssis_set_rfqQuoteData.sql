CREATE PROCEDURE [dbo].[proc_ssis_set_rfqQuoteData]
AS
-- =============================================
-- Author:		dp-sb
-- Create date:  30/11/2018
-- Description:	Stored procedure to set the legacy RFQ Quote data. This procedure in call in SSIS package.
-- Modification:
-- Example: [proc_ssis_set_rfqQuoteData]  
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN
	--print 'test'

	--select top 10 * from mp_rfq
	
	
	--select top 10 * from mp_rfq_part_quantity
	--select * from mp_rfq_quote_supplierquote where rfq_id = 308032
	--select top 10 * from mp_rfq_quote_items
	--select top 10 * from mp_rfq_quote_suplierStatuses
	--select top 10 * from mp_rfq_supplier_nda_accepted
	--select top 10 * from mp_rfq_part_quantity where rfq_part_id = 79838
	
	--delete from  mp_rfq_quote_items where rfq_quote_SupplierQuote_id in (select rfq_quote_SupplierQuote_id from mp_rfq_quote_supplierquote where contact_id = 1251140 )
	--delete from  mp_rfq_supplier_nda_accepted where rfq_id in (select rfqid from tmp_SSIS_RFQ_Quote_data_1 )
	--delete from  mp_rfq_quote_suplierStatuses where rfq_id in (select rfqid from tmp_SSIS_RFQ_Quote_data_1 )
	--delete from  mp_rfq_quote_supplierquote where contact_id = 1251140 
	
					 
	--select  * from  tmp_SSIS_RFQ_Quote_data_1 nolock where  rfqid = 1083605 and supplier_contact_id = 1251140
	--select top 10 * from mp_parts where part_id = 428433
	--select top 10 * from mp_rfq_parts where rfq_id = 1084198
	--select top 10 * from mp_rfq_part_quantity  where rfq_part_id in (95695)
	-- select top 10 * from mp_rfq_quote_supplierquote where  contact_id = 1251140 
	-- select top 10 * from mp_rfq_quote_items where rfq_part_id  = 95695
	-- select * from  mp_rfq_quote_suplierStatuses  where rfq_id = 1083605
	-- select * from  mp_rfq_supplier_nda_accepted  where rfq_id = 1083605

	-- select top 10 * from mp_rfq_parts where rfq_id = 1086537
	-- select * from mp_rfq_part_quantity where rfq_part_id in (98593)
	-- select max(quantity_level) from mp_rfq_part_quantity where  select min(quantity_level) from mp_rfq_part_quantity 
	-- update mp_rfq_part_quantity  set quantity_level = quantity_level-1 where quantity_level!= 0

	--select  min(quantity_level) 
	---- update a set a.quantity_level = a.quantity_level-1
	--from mp_rfq_part_quantity  a
	--join mp_rfq_parts  b on a.rfq_part_id = b.rfq_part_id
	--where b.rfq_id in (select  distinct rfqid from  tmp_SSIS_RFQ_Quote_data_1 nolock)

	--select top 10 * from mp_rfq_part_quantity  where rfq_part_id = 90955
	/*

	 DECLARE @TableName nvarchar(100) = 'mp_contacts'
	
	DECLARE @tmpFKRef TABLE (
	PKTABLE_QUALIFIER	varchar(200)
	, PKTABLE_OWNER	varchar(200)
	, PKTABLE_NAME	varchar(200)
	, PKCOLUMN_NAME	varchar(200)
	, FKTABLE_QUALIFIER	varchar(200)
	, FKTABLE_OWNER	varchar(200)
	, FKTABLE_NAME	varchar(200)
	, FKCOLUMN_NAME	varchar(200)
	, KEY_SEQ	int
	, UPDATE_RULE	int
	, DELETE_RULE	int
	, FK_NAME	varchar(200)
	, PK_NAME	varchar(200)
	, DEFERRABILITY	int
	)
 
	insert into @tmpFKRef
	EXEC sp_fkeys @TableName
 
	DECLARE @SQLCmd nvarchar(2000)
	DECLARE C1 cursor for    
	SELECT  ' ALTER TABLE ' + FKTABLE_OWNER + '.' + FKTABLE_NAME + ' NOCHECK CONSTRAINT ' +FK_NAME + ';' FROM @tmpFKRef
	OPEN C1
	FETCH from C1 into @SQLCmd
	WHILE @@FETCH_STATUS =0
	BEGIN	
		PRINT @SQLCmd
		EXEC SP_ExecuteSQL @SQLCmd
		FETCH from C1 into @SQLCmd
	END
	CLOSE C1
	DEALLOCATE C1

	delete from mp_rfq
	delete from  mp_rfq_parts
	delete from   mp_rfq_quote_items
	delete from   mp_rfq_quote_supplierquote
	delete from   mp_rfq_quote_suplierStatuses
	delete from   mp_rfq_supplier_nda_accepted
	delete from	  mp_rfq_part_quantity

	-- truncate table tmp_SSIS_RFQ_Quote_data_1

	select * from mp_rfq_parts
	select * from mp_rfq_part_quantity
	select * from mp_rfq_quote_supplierquote
	select * from mp_rfq_quote_items
	select * from mp_rfq_quote_suplierStatuses
	select * from mp_rfq_supplier_nda_accepted



	*/
		
	drop table if exists  tmp_ssis_legacy_qouted_rfq
	
	

	create table  tmp_ssis_legacy_qouted_rfq
	(
		[RFQID] [nvarchar](1000) NOT NULL,
		[Supplier_Contact_id] [nvarchar](1000) NOT NULL,
		[Supplier_company_id] [nvarchar](1000) NOT NULL,
		[is_prefered_nda_type_accepted] [nvarchar](1000) NOT NULL,
		[prefered_nda_type_accepted_date] [nvarchar](1000) NOT NULL,
		[payment_terms] [nvarchar](1000) NOT NULL,
		[is_payterm_accepted] [nvarchar](1000) NOT NULL,
		[QuoteReferenceNumber] [nvarchar](1000) NOT NULL,
		[IsSubmittedQuote] [nvarchar](1000) NOT NULL,
		[QuoteCreationDate] [nvarchar](1000) NOT NULL,
		[QuoteExpirationDate] [nvarchar](1000) NOT NULL,
		[PMS_ITEM_ID] [nvarchar](1000) NOT NULL,
		[grid_article] [nvarchar](1000) NOT NULL,
		[per_unit_price] [nvarchar](1000) NOT NULL,
		[tooling_amount] [nvarchar](1000) NOT NULL,
		[miscellaneous_amount] [nvarchar](1000) NOT NULL,
		[shipping_amount] [nvarchar](1000) NOT NULL,
		[is_awarded] [nvarchar](1000) NOT NULL,
		[QUANTITY_REF] [nvarchar](1000) NOT NULL,
		[is_award_accepted] [nvarchar](1000) NOT NULL,
		[AwardAcceptanceStatusDate] [nvarchar](1000) NOT NULL,
		is_created_mp_rfq_quote_supplierquote bit default 0,
		is_created_mp_rfq_quote_items bit default 0,
		is_created_mp_rfq_supplier_nda_accepted bit default 0,
		is_created_mp_rfq_quote_suplierStatuses bit default 0
	)

	create nonclustered index nc_index_tmp_ssis_legacy_qouted_rfq_rfq_id on tmp_ssis_legacy_qouted_rfq (rfqid)

	-- qouted rfq with part
	insert into  tmp_ssis_legacy_qouted_rfq
	(RFQID,Supplier_Contact_id,Supplier_company_id,is_prefered_nda_type_accepted,prefered_nda_type_accepted_date,payment_terms,is_payterm_accepted
	,QuoteReferenceNumber,IsSubmittedQuote,QuoteCreationDate,QuoteExpirationDate,PMS_ITEM_ID,grid_article,per_unit_price,tooling_amount,miscellaneous_amount
	,shipping_amount,is_awarded,QUANTITY_REF,is_award_accepted,AwardAcceptanceStatusDate)
	select  
		RFQID,Supplier_Contact_id,Supplier_company_id,is_prefered_nda_type_accepted,prefered_nda_type_accepted_date,payment_terms,is_payterm_accepted
		,QuoteReferenceNumber,IsSubmittedQuote,QuoteCreationDate,QuoteExpirationDate,PMS_ITEM_ID,grid_article,per_unit_price,tooling_amount,miscellaneous_amount
		,shipping_amount,is_awarded,QUANTITY_REF,is_award_accepted,AwardAcceptanceStatusDate
	from tmp_SSIS_RFQ_Quote_data nolock 
	where 
		--supplier_contact_id = 1251140  and 
		rfqid not  in (select rfq_id from mp_rfq_quote_supplierquote)
	order by rfqid
	
	
	-- insert into mp_rfq_quote_supplierquote
	insert into  mp_rfq_quote_supplierquote
	(rfq_id,contact_id,payment_terms,is_payterm_accepted,quote_reference_number,is_quote_submitted,quote_date,quote_expiry_date)
	select 
		distinct 
		RFQID,Supplier_Contact_id
		, case when payment_terms = 'null' then null else payment_terms end payment_terms
		, case when is_payterm_accepted = 'null' then null else is_payterm_accepted end is_payterm_accepted 
		, case when QuoteReferenceNumber = 'null' then null else QuoteReferenceNumber end QuoteReferenceNumber 
		, case when IsSubmittedQuote = 'null' then null else IsSubmittedQuote end IsSubmittedQuote 
		, case when QuoteCreationDate = 'null' then null else cast(cast(QuoteCreationDate as varchar(23)) as datetime) end QuoteCreationDate 
		, case when QuoteExpirationDate = 'null' then null else cast(cast(QuoteExpirationDate as varchar(23)) as datetime) end QuoteExpirationDate 
	from tmp_ssis_legacy_qouted_rfq
	where pms_item_id != 'null'
	and (case when QuoteExpirationDate = 'null' then null else cast(cast(QuoteExpirationDate as varchar(23)) as datetime) end) is not null
	and rfqid in  (select rfq_id from  mp_rfq)
	order by rfqid

	-- update tmp table for is_created_mp_rfq_quote_supplierquote = 1
	update a set is_created_mp_rfq_quote_supplierquote = 1
	from 
		 tmp_ssis_legacy_qouted_rfq a
		join  mp_rfq_quote_supplierquote b on a.rfqid = b.rfq_id and a.Supplier_Contact_id = b.contact_id

	
	--select * from mp_rfq_part_quantity
	insert into  mp_rfq_quote_items
	(rfq_quote_SupplierQuote_id ,rfq_part_id ,per_unit_price,tooling_amount,miscellaneous_amount,shipping_amount,rfq_part_quantity_id,is_awrded,
	is_award_accepted,award_accepted_Or_decline_date , awarded_date ,awarded_qty)
	select 
		 b.rfq_quote_SupplierQuote_id
		, c.rfq_part_id 
		, per_unit_price 
		, tooling_amount
		, miscellaneous_amount
		, shipping_amount
		, d.rfq_part_quantity_id
		, is_awarded
		, is_award_accepted
		, case when AwardAcceptanceStatusDate = 'null' then null else cast(cast(AwardAcceptanceStatusDate as varchar(23)) as datetime) end  AwardAcceptanceStatusDate
		, case when AwardAcceptanceStatusDate = 'null' then null else cast(cast(AwardAcceptanceStatusDate as varchar(23)) as datetime) end  awarded_date
		, d.part_qty
		
	from  tmp_ssis_legacy_qouted_rfq a
	join  mp_rfq_parts c on a.rfqid = c.rfq_id and a.pms_item_id = c.part_id
	join  mp_rfq_quote_supplierquote b on a.rfqid = b.rfq_id and a.Supplier_Contact_id = b.contact_id  and a.pms_item_id = c.part_id
	join  mp_rfq_part_quantity d on c.rfq_part_id  = d.rfq_part_id 
		 and (a.grid_article-1) = d.quantity_level  -- we are storing quantity leve data like 0,1,2...  
		--and (a.grid_article) = d.quantity_level
	where is_created_mp_rfq_quote_supplierquote = 1 -- and  b.rfq_quote_SupplierQuote_id is not null
	order by RFQID ,rfq_quote_SupplierQuote_id ,c.rfq_part_id


	update d set is_created_mp_rfq_quote_items = 1
	from 
		 mp_rfq_quote_items a
		join  mp_rfq_quote_supplierquote b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
		join  mp_rfq_parts c on a.rfq_part_id = c.rfq_part_id
		join  tmp_ssis_legacy_qouted_rfq d on c.rfq_id = d.rfqid and  convert(varchar(100),c.part_id) = d.PMS_ITEM_ID and  b.contact_id =d.Supplier_Contact_id and  b.rfq_id = d.rfqid
		join   mp_rfq_part_quantity e on a.rfq_part_quantity_id = e.rfq_part_quantity_id and d.grid_article = e.quantity_level
	where is_created_mp_rfq_quote_supplierquote = 1


	-- insert into mp_rfq_supplier_nda_accepted
	insert into  mp_rfq_supplier_nda_accepted
	(rfq_id,contact_id,is_prefered_nda_type_accepted,prefered_nda_type_accepted_date)
	select 
		distinct rfqid , Supplier_Contact_id , is_prefered_nda_type_accepted , cast(cast(prefered_nda_type_accepted_date as varchar(23)) as datetime) 
	from  tmp_ssis_legacy_qouted_rfq where prefered_nda_type_accepted_date != 'null' and rfqid in  (select rfq_id from mp_rfq)

	update a set is_created_mp_rfq_supplier_nda_accepted = 1
	from 
		 tmp_ssis_legacy_qouted_rfq a
		join  mp_rfq_supplier_nda_accepted b on a.rfqid = b.rfq_id and a.Supplier_Contact_id = b.contact_id


	-- insert into mp_rfq_quote_suplierStatuses
	insert into  mp_rfq_quote_suplierStatuses
	(rfq_id,contact_id,rfq_userStatus_id,creation_date,is_legacy_data)
	select 
		distinct rfqid , Supplier_Contact_id ,  2 ,cast(cast(QuoteCreationDate as varchar(23)) as datetime)   , 1
	from  tmp_ssis_legacy_qouted_rfq
	where QuoteCreationDate != 'null'  and rfqid in  (select rfq_id from mp_rfq)
	
	insert into  mp_rfq_quote_suplierStatuses
	(rfq_id,contact_id,rfq_userStatus_id,creation_date,is_legacy_data)
	select distinct rfqid , Supplier_Contact_id ,  1 ,'1900-01-01'   , 1 
	from  tmp_ssis_legacy_qouted_rfq a
	left join mp_rfq_quote_suplierStatuses  b on a.rfqid = b.rfq_id and a.Supplier_Contact_id = b.contact_id
	where QuoteCreationDate = 'null'  and rfqid in  (select rfq_id from mp_rfq)  and b.rfq_id is null and  b.contact_id is null

	--select top 100 * from  tmp_ssis_legacy_qouted_rfq where QuoteCreationDate = 'null' and supplier_contact_id = 1251140

	
	update a set is_created_mp_rfq_quote_suplierStatuses = 1
	from 
		 tmp_ssis_legacy_qouted_rfq a
		join  mp_rfq_quote_suplierStatuses b on a.rfqid = b.rfq_id and a.Supplier_Contact_id = b.contact_id

	--select * from mp_rfq_parts where rfq_id = 996672
	--select * from mp_rfq_quote_supplierquote  where rfq_quote_SupplierQuote_id = 797 
	--select * from mp_rfq_quote_items where  rfq_quote_SupplierQuote_id = 797 
	--select * from mp_rfq_part_quantity where rfq_part_id = 87250
	--select * from tmp_ssis_legacy_qouted_rfq where  rfqid = 1000070  and Supplier_Contact_id = 987008
	--select top 10 * from mp_rfq_part_quantity where rfq_part_id = 79838

	
	--SET IDENTITY_INSERT mp_rfq  ON
	--insert into mp_rfq
	--(rfq_id,rfq_name,rfq_description,contact_id,rfq_created_on,rfq_status_id,is_special_certifications_by_manufacturer,is_special_instruction_to_manufacturer,special_instruction_to_manufacturer,importance_price,importance_speed,importance_quality,Quotes_needed_by,award_date,is_partial_quoting_allowed,Who_Pays_for_Shipping
	--,ship_to,is_register_supplier_quote_the_RFQ,pref_NDA_Type,Post_Production_Process_id,Imported_Data,sourcing_advisor_id,rfq_zoho_id,file_id)
	--select rfq_id,rfq_name,rfq_description,contact_id,rfq_created_on,rfq_status_id,is_special_certifications_by_manufacturer,is_special_instruction_to_manufacturer,special_instruction_to_manufacturer,importance_price,importance_speed,importance_quality,Quotes_needed_by,award_date,is_partial_quoting_allowed,Who_Pays_for_Shipping
	--,ship_to,is_register_supplier_quote_the_RFQ,pref_NDA_Type,Post_Production_Process_id,Imported_Data,sourcing_advisor_id,rfq_zoho_id,file_id 
	--from mp_rfq --where rfq_id in  (select distinct rfqid  from tmp_ssis_legacy_qouted_rfq -- where is_created_mp_rfq_quote_supplierquote = 1 
	-- --)
	--SET IDENTITY_INSERT mp_rfq  OFF
	
	
	--SET IDENTITY_INSERT mp_rfq_parts  ON
	--insert into mp_rfq_parts
	--(rfq_part_id,part_id,rfq_id,delivery_date,quantity_unit_id,status_id,part_category_id,created_date,modification_date,Post_Production_Process_id,Is_Rfq_Part_Default)
	--select rfq_part_id,part_id,rfq_id,delivery_date,quantity_unit_id,status_id,part_category_id,created_date,modification_date,Post_Production_Process_id,Is_Rfq_Part_Default from mp_rfq_parts --where rfq_id in  (select distinct rfqid  from tmp_ssis_legacy_qouted_rfq -- where is_created_mp_rfq_quote_supplierquote = 1 
	-- --)
	--SET IDENTITY_INSERT mp_rfq_parts  OFF

	
	--insert into mp_rfq_part_quantity
	--( rfq_part_id,part_qty,quantity_level)
	--select rfq_part_id,part_qty,quantity_level
	--from mp_rfq_part_quantity -- where rfq_part_id in  (select distinct rfq_part_id  from mp_rfq_parts -- where is_created_mp_rfq_quote_supplierquote = 1 
	-- --)
	



	
	--SET IDENTITY_INSERT mp_mst_rfq_UserStatus  ON
	--insert into mp_mst_rfq_UserStatus
	--(rfq_userStatus_id ,rfq_userstatus_Li_key,rfq_userstatus_description)
	--select rfq_userStatus_id ,rfq_userstatus_Li_key,rfq_userstatus_description from mp_mst_rfq_UserStatus 
	--SET IDENTITY_INSERT mp_mst_rfq_UserStatus  OFF
	


	-- select * from mp_rfq_quote_supplierquote where rfq_id = 1000018
END 


--select * from mp_rfq where  rfq_id = 1104075  

--select * from mp_rfq_parts where rfq_id = 1104075 
--select * from mp_parts where part_id  in (436494,436495)
--select * from mp_rfq_part_quantity where rfq_part_id in (102923,102924,102925)
--select * from mp_rfq_quote_supplierquote  where rfq_id = 1104075 
--select * from mp_rfq_quote_suplierStatuses where rfq_id = 1104075 and 	contact_id = 1256005
	

--select * from mp_parts where part_id  in (436494,436495)



--select rfq_id , part_id , count(*) from mp_rfq_parts
--group by  rfq_id , part_id having count(*) > 1





------ data verification
	--select * from mp_contacts where contact_id in  (1251140 , 1253444)
	--select * from aspnetusers where id in  ('{ABF43C80-6254-4F35-B435-6BBD661F5969}' , '{CDF7DEF9-B90B-4963-883A-4DCE615FE9F7}', '66dc8ac4-8ded-4d6e-9f0f-88c9be58c9b6','c2c413a0-1e1a-4daa-bb88-97e74d657b2f')
	

	--select top 1000 * from mp_rfq where contact_id = 1253444 order by rfq_created_on desc
	--select  * from tmp_SSIS_RFQ_Quote_data_1 
	--where 
	--	rfqid in (select rfq_id from mp_rfq where contact_id = 1253444 )
	--	and supplier_contact_id = 1251140
	--	and QuoteCreationDate != 'null' order by supplier_contact_id
	--select * from mp_rfq_parts where rfq_id = 1014294
	--select * from mp_rfq_quote_supplierquote  where rfq_id = 1084781 order by contact_id
	--select * from mp_rfq_part_quantity where rfq_part_id = 81004
	--select * from mp_rfq_quote_items where  rfq_part_id =  81004
	

	--select  * from tmp_SSIS_RFQ_Quote_data_1
	--order by rfqid
	--OFFSET 10001 ROWS
	--FETCH NEXT 20 ROWS ONLY

	
	--select count(*) is_created_mp_rfq_quote_supplierquote from tmp_ssis_legacy_qouted_rfq  where is_created_mp_rfq_quote_supplierquote = 1
	--select *  from tmp_ssis_legacy_qouted_rfq  where is_created_mp_rfq_quote_items = 1
	--select *  from tmp_ssis_legacy_qouted_rfq  where rfqid = 1088989
	--select count(*) is_created_mp_rfq_quote_suplierStatuses from tmp_ssis_legacy_qouted_rfq  where is_created_mp_rfq_quote_suplierStatuses = 1
	--is_created_mp_rfq_supplier_nda_accepted


--	tmp_SSIS_RFQ_Quote_data_1 *complete data*
--	mp_rfq_quote_supplierquote
--	mp_rfq_quote_items
--	mp_rfq_quote_suplierStatuses
--	mp_rfq_supplier_nda_accepted
