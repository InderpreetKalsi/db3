
---- EXEC proc_get_GrowthPackageProductCapabilityMapping   
CREATE PROCEDURE [dbo].[proc_get_GrowthPackageProductCapabilityMapping]  
 
AS  
BEGIN  
 SET NOCOUNT ON   

 ----M2-4645 M - Integrate Stripe API for Growth package - DB

	SELECT c.ProductPriceAPIId ProcessAPIId , e.discipline_name  Process 
	FROM [mp_gateway_subscription_account_upgrades] (NOLOCK) a
	JOIN [mp_gateway_subscription_account_upgrade_product_mappings] (NOLOCK)  b 
		ON a.id = b.upgrade_id
	JOIN [mp_gateway_subscription_products] (NOLOCK) c 
		ON b.product_id = c.id
	JOIN [mp_gateway_subscription_product_process_mappings] (NOLOCK) d
		ON b.product_id = d.[ProductId]
	JOIN mp_mst_part_category  (NOLOCK) e ON d.PartCategoryId = e.part_category_id 
	WHERE 
		a.upgrade_title = 'Growth Package' 
		AND a.is_active = 1
		AND c.is_enable = 1
		AND c.is_active = 1
	ORDER BY Process
     
   
END
