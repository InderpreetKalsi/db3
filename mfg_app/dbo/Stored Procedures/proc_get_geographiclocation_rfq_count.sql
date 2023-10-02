-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--EXEC proc_get_geographiclocation_rfq_count 1274280,'2018-01-01','2018-12-31'
--EXEC proc_get_geographiclocation_rfq_count 1272585,'2018-01-01','2018-12-31'
CREATE PROCEDURE proc_get_geographiclocation_rfq_count
	@companyid int,
	@fromdate datetime,
	@todate datetime
AS
BEGIN
	--SELECT COUNT(R.rfq_id) RFQCount,T.territory_classification_name 
	--FROM mp_rfq R 
	--LEFT JOIN Mp_Rfq_Preferences P ON(R.rfq_id = P.rfq_id)
	--LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
	--WHERE R.contact_id=@contactid AND R.award_date BETWEEN @fromdate AND @todate
	--GROUP BY T.territory_classification_name
	--ORDER BY T.territory_classification_name

	SELECT COUNT(R.rfq_id) RFQCount,T.territory_classification_name 
	FROM mp_contacts C JOIN
	mp_rfq R ON(C.contact_id = R.contact_id)
	LEFT JOIN Mp_Rfq_Preferences P ON(R.rfq_id = P.rfq_id)
	LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
	WHERE C.company_id=@companyid AND R.award_date BETWEEN @fromdate AND @todate AND T.territory_classification_name IS NOT NULL
	GROUP BY T.territory_classification_name
	 ORDER BY T.territory_classification_name

END
