
CREATE  PROCEDURE [dbo].[proc_get_graph_geographic_location]
	@companyid int,
	@fromdate  datetime,
	@todate    datetime,
	@days      int
AS
BEGIN
 DECLARE @RfqSum NUMERIC(12,2)
IF(@days>0)
	BEGIN

	  
		SELECT @RfqSum = COUNT(R.rfq_id)
		FROM mp_contacts C INNER JOIN mp_rfq R ON(C.contact_id = R.contact_id)
		INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		LEFT JOIN mp_rfq_preferences P ON(R.rfq_id = P.rfq_id)
		LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND  CONVERT(DATE,I.awarded_date,103) BETWEEN @fromdate AND @todate 
			AND T.territory_classification_name IS NOT NULL AND C.is_buyer = 1		

		SELECT COUNT(R.rfq_id) AS rfqCount,T.territory_classification_name AS geographicLocation,
		CAST(ROUND(((COUNT(R.rfq_id)/@RfqSum)*100),0) AS NUMERIC(12,2)) AS rfqPercentage
		FROM mp_contacts C INNER JOIN mp_rfq R ON(C.contact_id = R.contact_id)
			INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		LEFT JOIN mp_rfq_preferences P ON(R.rfq_id = P.rfq_id)
		LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND  CONVERT(DATE,I.awarded_date,103) BETWEEN @fromdate AND @todate 
			AND T.territory_classification_name IS NOT NULL AND C.is_buyer = 1
		GROUP BY T.territory_classification_name


	END
ELSE
	BEGIN
		SELECT @RfqSum = COUNT(R.rfq_id)
		FROM mp_contacts C INNER JOIN mp_rfq R ON(C.contact_id = R.contact_id)
		INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		LEFT JOIN mp_rfq_preferences P ON(R.rfq_id = P.rfq_id)
		LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND I.awarded_date IS NOT NULL AND T.territory_classification_name IS NOT NULL AND C.is_buyer = 1


		SELECT COUNT(R.rfq_id) AS rfqCount,T.territory_classification_name AS geographicLocation,
		CAST(ROUND(((COUNT(R.rfq_id)/@RfqSum)*100),0) AS NUMERIC(12,2)) AS rfqPercentage
		FROM mp_contacts C INNER JOIN mp_rfq R ON(C.contact_id = R.contact_id)
		INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		LEFT JOIN mp_rfq_preferences P ON(R.rfq_id = P.rfq_id)
		LEFT JOIN mp_mst_territory_classification T ON(P.rfq_pref_manufacturing_location_id = T.territory_classification_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND I.awarded_date IS NOT NULL AND T.territory_classification_name IS NOT NULL AND C.is_buyer = 1
		GROUP BY T.territory_classification_name
	END
END
