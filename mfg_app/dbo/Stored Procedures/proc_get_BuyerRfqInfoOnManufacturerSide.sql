


/*


-- M2-3170 M - Add Buyer RFQ info to the drawer - DB
EXEC proc_get_BuyerRfqInfoOnManufacturerSide
@SupplierCompanyId = 1775055
,@SupplierId = 1344694
,@BuyerId = 691391

*/
CREATE PROCEDURE [dbo].[proc_get_BuyerRfqInfoOnManufacturerSide]
(
	@SupplierCompanyId		INT
	,@SupplierId			INT
	,@BuyerId				INT
)
AS
BEGIN
	-- M2-3170 M - Add Buyer RFQ info to the drawer - DB

	SET NOCOUNT ON

	DECLARE @ManufacturingLocation	INT

	SET @ManufacturingLocation = (SELECT manufacturing_location_id FROM  mp_companies (NOLOCK) WHERE company_id =  @SupplierCompanyId )

	SELECT 
	TOP 5
		a.rfq_id		AS [RfqId]
		,a.rfq_name		AS [RfqName]
		,e.discipline_name	AS [Process]
		,(CASE WHEN d.discipline_name =e.discipline_name THEN NULL ELSE d.discipline_name END)	AS [Technique]
		,MAX(c.part_qty)	AS [MaxQuantity]
		,@ManufacturingLocation AS SupplierManufacturingLocation
		,g.rfq_pref_manufacturing_location_id AS RfqManufacturingLocation
	FROM mp_rfq					(NOLOCK) a
	JOIN mp_rfq_parts			(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.Is_Rfq_Part_Default = 1
	JOIN mp_rfq_part_quantity	(NOLOCK) c ON b.rfq_part_id = c.rfq_part_id AND c.is_deleted = 0
	JOIN mp_mst_part_category	(NOLOCK) d ON b.part_category_id = d.part_category_id AND d.status_id = 2
	JOIN mp_mst_part_category	(NOLOCK) e ON d.parent_part_category_id = e.part_category_id AND e.status_id = 2
	JOIN mp_rfq_supplier		(NOLOCK) f ON a.rfq_id = f.rfq_id  AND f.company_id = -1 
	JOIN mp_rfq_preferences		(NOLOCK) g ON a.rfq_id = g.rfq_id
	WHERE a.rfq_status_id IN (3,5,6,16,17,20)
	AND a.contact_id = @BuyerId
	AND g.rfq_pref_manufacturing_location_id = @ManufacturingLocation
	GROUP BY a.rfq_id,a.rfq_name	,e.discipline_name,d.discipline_name ,g.rfq_pref_manufacturing_location_id 
	ORDER BY a.rfq_id DESC



END