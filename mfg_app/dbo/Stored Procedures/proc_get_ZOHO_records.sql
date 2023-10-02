-- =============================================
-- Author:		dp-Sh. B.
-- Create date: 24-10-2018
-- Description:	Stored procedure to get ZOHO records
-- Modification:
-- Example: [proc_get_ZOHO_records] 
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================








CREATE PROCEDURE [dbo].[proc_get_ZOHO_records]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	SELECT  distinct top 200 comp.company_id as MFGLegacyACCTID,comp.name as Account_Name, 'Null' as Account_Type,'Null' as Rating,
	 'Null' as Website1, 2 as Employee_Count,'Null' as VisionACCTID,'Manufacturing' as Industry,
	  'Null' as Record_Image,commun.communication_value as Phone,'Null' as Fax,comp.duns_number as DUNS, 
	  addr.address1 as Billing_Street,addr.address2 as Billing_Street_2,addr.address4 as Billing_City,
	  'Maharashtra' as Billing_State,'India' as Billing_Country,addr.address3 as Billing_Code,
	   addr.address1 as Shipping_Street,addr.address2 as Shipping_Street_2,addr.address4 as Shipping_City,
	  'Maharashtra' as Shipping_State,'India' as Shipping_Country,addr.address3 as Shipping_Code
	      FROM mp_contacts cont 
	JOIN mp_companies comp on cont.company_id=comp.company_id
	JOIN mp_communication_details commun on cont.contact_id=commun.contact_id
	JOIN mp_addresses addr on cont.address_id=addr.address_id
	JOIN mp_company_shipping_site shipping on cont.company_id=shipping.comp_id
	WHERE cont.is_active=1 and shipping.default_site=1

	
END

--select * from mp_communication_details
--select * from mp_company_shipping_site
--select top 10 * from mp_companies
--select top 10 * from Mp_Mst_Industries
--select top 10 * from Mp_Mst_IndustryBranches where 
--IndustryBranches_name_EN='Healthcare and Medical'
--select * from mp_addresses
