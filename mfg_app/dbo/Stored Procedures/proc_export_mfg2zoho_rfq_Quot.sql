  
  CREATE PROCEDURE [dbo].[proc_export_mfg2zoho_rfq_Quot](@DestinationDBName varchar(100)='zoho')  
AS  
-- =============================================  
-- Author:  dp-sb.  
-- Create date:  19/11/2018  
-- Description: Stored procedure to export rfq Quot data  
-- Modification:  
-- Example: [proc_export_mfg2zoho_rfq_Quot] 'zoho'  
-- =================================================================  
--Version No – Change Date – Modified By      – CR No – Note  
-- =================================================================  
BEGIN  
 --DECLARE @DestinationDBName varchar(100)  
 --SELECT @DestinationDBName ='zoho'  
 DECLARE @DynamicSQL nvarchar(max) =''  
  
 IF OBJECT_ID('tempdb..#zoho_Mfg_Rfq_Quotes') IS NOT NULL  
  DROP TABLE #zoho_Mfg_Rfq_Quotes  

 IF OBJECT_ID('tempdb..#Zoho_Mfg_RfqItems_Quotes') IS NOT NULL  
  DROP TABLE #Zoho_Mfg_RfqItems_Quotes  
  

  
 CREATE TABLE #zoho_Mfg_Rfq_Quotes (  
 rfq_id int Not Null  
 ,rfq_name nvarchar(200) Null  
 ,quote_expiry_date datetime Null  
 ,company_id int Not Null  
 ,CompanyName nvarchar(300) Null  
 ,Grand_Total numeric(18,3) Null  
 ,quote_reference_number varchar(100) Null  
 ,Billing_Street nvarchar(3064) Not Null  
 ,Billing_City nvarchar(1020) Null  
 ,Billing_State nvarchar(400) Not Null  
 ,Billing_Country nvarchar(100) Not Null  
 ,Billing_Code varchar(50) Not Null  
 , isInsertable bit not null)  
  
  

 CREATE TABLE #Zoho_Mfg_RfqItems_Quotes(  
 rfq_id int Not Null  
 ,rfq_name nvarchar(200) Null  
 ,company_id int Not Null  
 ,CompanyName nvarchar(300) Null  
 ,part_number nvarchar(900) Null  
 ,part_name nvarchar(900) Null  
 ,part_id bigint Not Null  
 ,rfq_quote_items_id int Not Null  
 ,rfq_part_quantity_id int Null  
 ,awarded_qty numeric(9) Null  
 ,total_after_discount numeric(17) Null  
 ,per_unit_price numeric(9) Not Null  
 ,part_description nvarchar(max) Null  
 , isInsertable bit not null)  
  
 ---RFQ Quot   
 INSERT INTO #zoho_Mfg_Rfq_Quotes(rfq_id  
 , rfq_name  
 , quote_expiry_date  
 , company_id  
 , CompanyName  
 , Grand_Total  
 , quote_reference_number  
 , Billing_Street  
 , Billing_City  
 , Billing_State  
 , Billing_Country  
 , Billing_Code  
 , isInsertable  
 )  
 SELECT   
   mr.rfq_id  
  , mr.rfq_name  
  , mrq.quote_expiry_date  
  , mcm.company_id  
  , mcm.name as CompanyName   
  , isnull(sum(per_unit_price*awarded_qty) ,0)  
   + isnull(sum(tooling_amount),0)  
   + isnull(sum(miscellaneous_amount),0)  
   + isnull(sum(shipping_amount),0) as Grand_Total  
  , mrq.quote_reference_number  
  
  , isnull(ma.address1 + ' ','') + isnull(ma.address2 + ' ', '') + isnull(ma.address3,'') as Billing_Street  
  , ma.address4 as Billing_City  
  , mmr.REGION_NAME as Billing_State  
  , mmc.country_name as  Billing_Country  
  , '' as Billing_Code  
  , 1  
 FROM mp_rfq mr  
 JOIN mp_rfq_quote_SupplierQuote mrq on mr.rfq_id = mrq.rfq_id  
 JOIN mp_contacts mc on mc.contact_id = mrq.contact_id   
 JOIN mp_companies mcm on mc.company_id = mcm.company_id  
 JOIN mp_rfq_quote_items mrqi on mrqi.rfq_quote_SupplierQuote_id = mrq.rfq_quote_SupplierQuote_id  
 JOIN mp_addresses ma on ma.address_id = mc.address_id   
 JOIN mp_mst_region mmr on mmr.REGION_ID = ma.region_id  
 JOIN mp_mst_country  mmc on mmc.country_id = ma.country_id  
 --WHERE mr.rfq_status_id not in (5, 13)  
 GROUP BY   
  mr.rfq_id   
  , mr.rfq_name  
  , mrq.quote_expiry_date  
  , mcm.name   
  , mrq.quote_reference_number  
  , isnull(ma.address1 + ' ','') + isnull(ma.address2 + ' ', '') + isnull(ma.address3,'')   
  , ma.address4   
  , mmr.REGION_NAME   
  , mmc.country_name  
  , mcm.company_id  
  
 ---RFQ Quot Items  
 INSERT INTO #Zoho_Mfg_RfqItems_Quotes(  
 rfq_id  
 , rfq_name  
 , company_id  
 , CompanyName  
 , part_number  
 , part_name  
 , part_id  
 , rfq_quote_items_id  
 , rfq_part_quantity_id  
 , awarded_qty  
 , total_after_discount  
 , per_unit_price  
 , part_description  
 , isInsertable  
 )  
 SELECT   
  mr.rfq_id  
  , mr.rfq_name  
  , mcm.company_id  
  , mcm.name as CompanyName   
  , mp.part_number  
  , mp.part_name  
  , mp.part_id  
  , mrqi.rfq_quote_items_id  
  , mrqi.rfq_part_quantity_id  
  , mrqi.awarded_qty   
  , isnull((per_unit_price*awarded_qty) ,0)  
   + isnull((tooling_amount),0)  
   + isnull((miscellaneous_amount),0)  
   + isnull((shipping_amount),0) as total_after_discount  
  , mrqi.per_unit_price  
  , mp.part_description  
  , 1  
 from mp_rfq mr  
 JOIN mp_rfq_quote_SupplierQuote mrq on mr.rfq_id = mrq.rfq_id  
 JOIN mp_contacts mc on mc.contact_id = mrq.contact_id   
 JOIN mp_companies mcm on mc.company_id = mcm.company_id  
 JOIN mp_rfq_quote_items mrqi on mrqi.rfq_quote_SupplierQuote_id = mrq.rfq_quote_SupplierQuote_id  
 JOIN mp_rfq_parts mrp on mrp.rfq_part_id = mrqi.rfq_part_id  
 JOIN mp_parts mp on mp.part_id = mrp.part_id  
 --WHERE mr.rfq_status_id not in (5, 13)  
 ORDER BY  mr.rfq_name, mcm.name , mp.part_name, mrqi.rfq_part_quantity_id  
   
 ---Set Flag to inser the data to Zoho db  
  BEGIN  
   SET @DynamicSQL = N'UPDATE SourceTbl SET SourceTbl.isInsertable = 0  
   FROM #zoho_Mfg_Rfq_Quotes as SourceTbl  
   JOIN ' + @DestinationDBName + '.[dbo].[zoho_mfg_rfq_quotes] as DestTble  
   ON SourceTbl.rfq_id = DestTble.rfq_id   
   and SourceTbl.company_id = DestTble.company_id '  
  -- print @DynamicSQL  
   exec sp_executesql @DynamicSQL  
  
   SET @DynamicSQL = ''  
   SET @DynamicSQL = N'UPDATE SourceTbl SET SourceTbl.isInsertable = 0  
   FROM #Zoho_Mfg_RfqItems_Quotes as SourceTbl  
   JOIN ' + @DestinationDBName + '.[dbo].[zoho_mfg_rfqitems_quotes] as DestTble  
   ON SourceTbl.rfq_id = DestTble.rfq_id   
   and SourceTbl.company_id = DestTble.company_id   
   and SourceTbl.part_id = DestTble.part_id   
   and isnull(SourceTbl.rfq_part_quantity_id,0) = isnull(DestTble.rfq_part_quantity_id,0) '  
  -- print @DynamicSQL  
   exec sp_executesql @DynamicSQL  
  END   
   
  --SELECT * FROM #zoho_Mfg_Rfq_Quotes  
  --SELECT * FROM #Zoho_Mfg_RfqItems_Quotes  
  
  ---Inserting Rfq_Quotes data  
  BEGIN  
    SET @DynamicSQL = N'INSERT INTO ' + @DestinationDBName + '.[dbo].zoho_Mfg_Rfq_Quotes(rfq_id  
   , rfq_name  
   , quote_expiry_date  
   , company_id  
   , CompanyName  
   , Grand_Total  
   , quote_reference_number  
   , Billing_Street  
   , Billing_City  
   , Billing_State  
   , Billing_Country  
   , Billing_Code  
   )  
   SELECT rfq_id  
   , rfq_name  
   , quote_expiry_date  
   , company_id  
   , CompanyName  
   , Grand_Total  
   , quote_reference_number  
   , Billing_Street  
   , Billing_City  
   , Billing_State  
   , Billing_Country  
   , Billing_Code  
   from #zoho_Mfg_Rfq_Quotes where isInsertable = 1'  
    EXEC sp_executesql @DynamicSQL  
  END  
    
   ---Inserting RfqItems_Quotes data  
  BEGIN  
   SET @DynamicSQL = N'INSERT INTO ' + @DestinationDBName + '.[dbo].Zoho_Mfg_RfqItems_Quotes(rfq_id  
   , rfq_name  
   , company_id  
   , CompanyName  
   , part_number  
   , part_name  
   , part_id  
   , rfq_quote_items_id  
   , rfq_part_quantity_id  
   , awarded_qty  
   , total_after_discount  
   , per_unit_price  
   , part_description  
   )  
   SELECT rfq_id  
   , rfq_name  
   , company_id  
   , CompanyName  
   , part_number  
   , part_name  
   , part_id  
   , rfq_quote_items_id  
   , rfq_part_quantity_id  
   , awarded_qty  
   , total_after_discount  
   , per_unit_price  
   , part_description  
    from #Zoho_Mfg_RfqItems_Quotes where isInsertable = 1'  
   EXEC sp_executesql @DynamicSQL  
  END  
  
 IF OBJECT_ID('tempdb..#zoho_Mfg_Rfq_Quotes') IS NOT NULL  
  DROP TABLE #zoho_Mfg_Rfq_Quotes  

 IF OBJECT_ID('tempdb..#Zoho_Mfg_RfqItems_Quotes') IS NOT NULL  
  DROP TABLE #Zoho_Mfg_RfqItems_Quotes  

END