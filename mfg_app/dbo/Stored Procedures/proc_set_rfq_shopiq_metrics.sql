
/*

EXEC [proc_set_rfq_shopiq_metrics]

select * from mp_rfq_shopiq_metrics

*/
CREATE PROCEDURE [dbo].[proc_set_rfq_shopiq_metrics]
as
begin

	/*
		created :	apr 18,2019
		purpose :	M2-1450 Shop IQ at the RFQ level - Database
					The Shop IQ tab on the Supplier's RFQ details page will display the RFQ and Part level quoting statistic breakdown.
					This will be just like the existing platform except we will not have the Awards by Company Size or Awards by Certification
					Display Shop IQ 7 days after the Award date
					We will only show the following:
					Buyer information
					RFQ roll up award price info
					Part and award info
					Display the Market Price always and don’t show
					Always show based on Quantity 1 when not awarded
					Display the awarded quantity if awarded
	*/
	/*
		modified :	May 31,2023
		purpose :	M2-5003 M - Shop IQ - Include tooling, misc, and shipping costs into the per unit cost - DB
					Currently it appears the Shop IQ per unit cost omits other quote costs such as tooling, miscellaneous, and shipping. 
					These should be calculated into the Shop IQ per unit costs. Ex. price per unit + ((tooling + miscellaneous + shipping) / # of units)) = Shop IQ per unit. 
	*/
	
	--TRUNCATE TABLE mp_rfq_shopiq_metrics

	--DROP TABLE IF EXISTS #tmp_list_of_rfqs_for_shopiq
	IF OBJECT_ID('tempdb..#tmp_list_of_rfqs_for_shopiq') IS NOT NULL  
    DROP TABLE #tmp_list_of_rfqs_for_shopiq

	DROP TABLE IF EXISTS #tmp_rfq_supplier_quoted_count
	DROP TABLE IF EXISTS #tmp_rfq_part_quantity_per_unit_price
	DROP TABLE IF EXISTS #tmp_rfq_awarded_parts_per_unit_price
	DROP TABLE IF EXISTS #tmp_rfq_part_quantity_low_high_price
	---- Fetch such RFQs which are fall in "Other" awarded 
	DROP TABLE IF EXISTS #tmp_list_of_rfqs_for_shopiq_other ---- M2-5022

	CREATE TABLE #tmp_list_of_rfqs_for_shopiq (rfq_id INT)
	CREATE TABLE #tmp_rfq_supplier_quoted_count (rfq_id int,supplier_quoted INT)
	CREATE TABLE #tmp_rfq_part_quantity_per_unit_price (rfq_id INT,rfq_part_quantity_id INT,per_unit_price NUMERIC(18,4))
	CREATE TABLE #tmp_rfq_part_quantity_low_high_price(rfq_id INT,rfq_part_quantity_id INT,low_unit_price NUMERIC(18,4),high_unit_price NUMERIC(18,4))
	CREATE TABLE #tmp_list_of_rfqs_for_shopiq_other (rfq_id INT,rfq_part_id INT,is_awrded BIT, unit NUMERIC(9,2),price NUMERIC(9,2),rfq_part_quantity_id INT) ----M2-5022
	
 
	---- generating and hold list of rfq's for shopiq
	INSERT INTO #tmp_list_of_rfqs_for_shopiq
	SELECT rfq_id  --INTO #tmp_list_of_rfqs_for_shopiq
	FROM mp_rfq (NOLOCK)
	WHERE rfq_status_id IN (5,6,16,17,20)
	AND CONVERT(DATE,award_date+1)  = CONVERT(DATE,GETUTCDATE()) ----M2-4634 Changed the day #
	----AND CONVERT(DATE,award_date)  = CONVERT(DATE,GETUTCDATE()) ----- for testing puepose change commented above code  
	
	---- generating data for such RFQs which are fall in "Other" awarded   
	/* M2-5022 M - Add custom quantity and awarded price as another row in Shop IQ - DB */
	INSERT INTO #tmp_list_of_rfqs_for_shopiq_other
	SELECT a.rfq_id ,b.rfq_part_id,b.is_awrded,b.unit,b.price,b.rfq_part_quantity_id
	FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
	join mp_rfq_quote_items(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
	where a.rfq_id in (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq) 
	and b.is_awrded = 1
	and b.status_id = 6
	and b.unit > 0
	/* */

	
	/* M2-4272 M - Update Shop IQ data if the award price is updated - DB */

	---- delete such rfq id from mp_rfq_shopiq_metrics, which are already exists
	DELETE FROM mp_rfq_shopiq_metrics WHERE rfq_id in
	(
		SELECT rfq_id  --INTO #tmp_list_of_rfqs_for_shopiq
		FROM mp_rfq (NOLOCK)
		WHERE rfq_status_id IN (5,6,16,17,20)
		AND CONVERT(DATE,RegenerateShopIQOn)  = CONVERT(DATE,GETUTCDATE()-1) 
		----AND CONVERT(DATE,RegenerateShopIQOn)  = CONVERT(DATE,GETUTCDATE()) ----- for testing puepose change commented above code 
		and  CONVERT(DATE,award_date)  <= CONVERT(DATE,GETUTCDATE())       
		and RegenerateShopIQOn is not null
	)
	

	---- insert such rfq into temp table
	INSERT INTO #tmp_list_of_rfqs_for_shopiq
	SELECT rfq_id  
	FROM mp_rfq (NOLOCK)
	WHERE rfq_status_id IN (5,6,16,17,20)
	AND CONVERT(DATE,RegenerateShopIQOn)  = CONVERT(DATE,GETUTCDATE()-1)  
	and CONVERT(DATE,award_date)  <= CONVERT(DATE,GETUTCDATE())        
	and RegenerateShopIQOn is not null

	/* End: M2-4272 M - Update Shop IQ data if the award price is updated - DB */
	IF ((SELECT COUNT(1) FROM #tmp_list_of_rfqs_for_shopiq) > 0)
	BEGIN
		-- getting quotes count for rfq's
		INSERT INTO #tmp_rfq_supplier_quoted_count
		SELECT rfq_id , SUM (supplier_quoted) AS supplier_quoted   
		FROM (
				SELECT a.rfq_id , count(distinct b.contact_id) supplier_quoted  
				FROM mp_rfq	 a	(NOLOCK)
				LEFT JOIN mp_rfq_quote_supplierquote (NOLOCK)  b ON a.rfq_id = b.rfq_id 
				AND is_quote_submitted = 1 AND is_rfq_resubmitted =0 
				WHERE EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)
				GROUP BY a.rfq_id
			
				UNION ALL
		
				----M2-4428 : here fetching data for decline quote
				SELECT a.rfq_id , count(distinct b.contact_id) supplier_quoted  
				FROM mp_rfq	 a	(NOLOCK)
				LEFT JOIN mp_rfq_quote_supplierquote (NOLOCK)  b ON a.rfq_id = b.rfq_id 
				and is_quote_submitted = 1 and is_rfq_resubmitted =1 and is_quote_declined = 1 
				WHERE EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)
				GROUP BY a.rfq_id
			)  rfq_supplier_quoted_count
		GROUP BY  rfq_id


		-- getting sum of per unit price for rfq's for each quantity level
		INSERT INTO #tmp_rfq_part_quantity_per_unit_price
		SELECT rfq_id ,rfq_part_quantity_id ,SUM(per_unit_price) AS per_unit_price  
		FROM (
				SELECT a.rfq_id , b.rfq_part_quantity_id 
				----, SUM(b.per_unit_price) per_unit_price
				, SUM(  CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
					 ) AS [per_unit_price]
				FROM mp_rfq_quote_supplierquote (NOLOCK) a
				JOIN mp_rfq_quote_items			(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
					AND is_quote_submitted = 1 AND is_rfq_resubmitted =0
				WHERE  EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)
				GROUP BY  a.rfq_id , b.rfq_part_quantity_id 
				
				UNION ALL 
				----M2-4428 : here fetching data for decline quote
				SELECT a.rfq_id , b.rfq_part_quantity_id 
				----, SUM(b.per_unit_price) per_unit_price
				, SUM(  CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
					 ) AS [per_unit_price]
				FROM mp_rfq_quote_supplierquote (NOLOCK) a
				JOIN mp_rfq_quote_items			(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
					AND is_quote_submitted = 1 AND is_rfq_resubmitted =1 and is_quote_declined = 1
				WHERE  EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)
				GROUP BY  a.rfq_id , b.rfq_part_quantity_id 
			 ) rfq_part_quantity_per_unit_price
		GROUP BY rfq_id ,rfq_part_quantity_id

	

		-- getting min and max price of rfq's for each quantity level
		/* M2-3721 M - Add the Low and High price to all Quantities in Shop IQ- DB */
		INSERT INTO  #tmp_rfq_part_quantity_low_high_price
		SELECT rfq_id,rfq_part_quantity_id,MIN(low_unit_price) AS low_unit_price, MAX(high_unit_price) AS high_unit_price 
		FROM (
			SELECT a.rfq_id , b.rfq_part_quantity_id 
			----, b.per_unit_price  AS low_unit_price 
			----, b.per_unit_price AS high_unit_price
			, CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
				 AS [low_unit_price]
			, CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
				 AS [high_unit_price]
			FROM mp_rfq_quote_supplierquote (NOLOCK) a
			JOIN mp_rfq_quote_items			(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				AND is_quote_submitted = 1 AND is_rfq_resubmitted =0
			WHERE  EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)
			
			UNION ALL
			----M2-4428 : here fetching data for decline quote
			SELECT a.rfq_id , b.rfq_part_quantity_id 
			----, b.per_unit_price  AS low_unit_price 
			----, b.per_unit_price AS high_unit_price
			, CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
				 AS [low_unit_price]
			, CONVERT(DECIMAL(16,4),
						b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty)) 
				 AS [high_unit_price]
			FROM mp_rfq_quote_supplierquote (NOLOCK) a
			JOIN mp_rfq_quote_items			(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				AND is_quote_submitted = 1 AND is_rfq_resubmitted =1 and is_quote_declined = 1
			WHERE  EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id)

			) rfq_part_quantity_low_high_price
		GROUP BY  rfq_id,rfq_part_quantity_id
		/**/
			 
		-- getting per unit price for awarded rfq's at quantity level
		SELECT a.rfq_id , b.rfq_part_id , b.rfq_part_quantity_id 
		--, b.per_unit_price 
		---- added with M2-5003
		,CONVERT(DECIMAL(16,4),
		b.per_unit_price + (( ISNULL(b.tooling_amount,0) + ISNULL(b.miscellaneous_amount,0) + ISNULL(b.shipping_amount,0)) /  b.awarded_qty ) 
		) AS [per_unit_price]
		, b.awarded_qty ,b.is_awrded
		, CASE WHEN (b.status_id = 6 and b.unit > 0)  THEN 1 ELSE 0 END AS IsOtherAwarded
		INTO #tmp_rfq_awarded_parts_per_unit_price
		FROM mp_rfq_quote_supplierquote (NOLOCK) a
		JOIN mp_rfq_quote_items			(NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			AND is_quote_submitted = 1 AND is_rfq_resubmitted =0
		WHERE  EXISTS (SELECT rfq_id FROM #tmp_list_of_rfqs_for_shopiq WHERE rfq_id = a.rfq_id )
		AND  is_awrded = 1  
		AND  b.awarded_qty > 0
		/*
			select * from #tmp_rfq_supplier_quoted_count
			select * from #tmp_rfq_part_quantity_per_unit_price where rfq_id = 1163809
			select * from #tmp_rfq_part_quantity_low_high_price  where rfq_id = 1163809
			select * from #tmp_rfq_awarded_parts_per_unit_price  where rfq_id = 1163809
	    */

		-- generating shopiq metric and inserting it into relavent table
		INSERT INTO mp_rfq_shopiq_metrics
		(rfq_id ,rfq_part_id ,rfq_part_quantity_id ,quantity ,is_awarded ,avg_marketprice ,awarded_price ,award_date ,part_name ,process ,material, LowPrice , HighPrice,IsAwardedToOtherQty)
		SELECT 
				a.rfq_id 
				, b.rfq_part_id
				, f.rfq_part_quantity_id
				, (CONVERT(VARCHAR(150),f.part_qty ) +' ' + g.value) quantity 
				, 
				(
					CASE	
						WHEN (
								(SELECT COUNT(is_awrded) FROM mp_rfq_quote_items (NOLOCK) WHERE rfq_part_quantity_id = f.rfq_part_quantity_id AND is_awrded = 1 ) > 0
							 ) 
						THEN CASE WHEN j.IsOtherAwarded = 1 THEN 0 ELSE  1 END  
						ELSE 0 
					END
				  ) AS is_awrded
				,CONVERT
				 (
					DECIMAL(18,2),
					 CASE 
						WHEN h.supplier_quoted =  0 THEN 0 
						ELSE
							(
								ISNULL(i.per_unit_price,0) / h.supplier_quoted 
					
							)
					END 
				) AS avg_market_price
				, 
				(
					CASE 
						WHEN a.rfq_status_id IN (16,17,20) THEN
						(SELECT DISTINCT price FROM mp_rfq_quote_items a1 WHERE  b.rfq_part_id = a1.rfq_part_id AND f.rfq_part_quantity_id = a1.rfq_part_quantity_id and price is not null and price > 0)
						ELSE ISNULL(j.per_unit_price,0) 
					END
				)
				
				--, ISNULL(j.per_unit_price,0) -- CASE WHEN a.rfq_status_id IN (5,6) THEN ISNULL(j.per_unit_price,0) ELSE 0 END awarded_price
				, a.award_date
				, c.part_name
				, e.discipline_name as process
				, d.material_name_en  as material 
		/* M2-3721 M - Add the Low and High price to all Quantities in Shop IQ- DB */
				, ISNULL(k.low_unit_price,0)
				, ISNULL(k.high_unit_price,0)
		/**/
				, 0 AS IsAwardedToOtherQty
		FROM mp_rfq			a	(NOLOCK)
		JOIN mp_rfq_parts	b	(NOLOCK) ON a.rfq_id = b.rfq_id
		JOIN mp_parts		c	(NOLOCK) ON b.part_id = c.part_id
		LEFT JOIN mp_mst_materials		d	(NOLOCK) ON c.material_id = d.material_id 
		LEFT JOIN mp_mst_part_category	e	(NOLOCK) ON c.part_category_id = e.part_category_id
		LEFT JOIN mp_rfq_part_quantity	f	(NOLOCK) ON b.rfq_part_id = f.rfq_part_id and f.is_deleted = 0
		LEFT JOIN mp_system_parameters	g	(NOLOCK) ON c.part_qty_unit_id = g.id and g.sys_key = '@UNIT2_LIST' 
		JOIN #tmp_rfq_supplier_quoted_count h ON a.rfq_id = h.rfq_id 
		LEFT JOIN #tmp_rfq_part_quantity_per_unit_price i ON a.rfq_id = i.rfq_id AND f.rfq_part_quantity_id = i.rfq_part_quantity_id
		LEFT JOIN #tmp_rfq_awarded_parts_per_unit_price j ON a.rfq_id = j.rfq_id AND f.rfq_part_quantity_id = j.rfq_part_quantity_id
		/* M2-3721 M - Add the Low and High price to all Quantities in Shop IQ- DB */
		LEFT JOIN #tmp_rfq_part_quantity_low_high_price k ON a.rfq_id = k.rfq_id AND f.rfq_part_quantity_id = k.rfq_part_quantity_id
		/**/
		ORDER BY a.rfq_id 
				, b.rfq_part_id
				, f.rfq_part_quantity_id
				
		/* M2-5022 M - Add custom quantity and awarded price as another row in Shop IQ - DB */
	 	INSERT INTO mp_rfq_shopiq_metrics
		(rfq_id ,rfq_part_id ,rfq_part_quantity_id ,quantity ,is_awarded ,avg_marketprice ,awarded_price ,award_date ,part_name ,process ,material, LowPrice , HighPrice,IsAwardedToOtherQty)
		SELECT 
				a.rfq_id 
				, b.rfq_part_id
				, f.rfq_part_quantity_id
				, h.unit AS quantity 
				, h.is_awrded is_awrded
				,NULL AS avg_market_price
				, h.price AS awarded_price
				
				--, ISNULL(j.per_unit_price,0) -- CASE WHEN a.rfq_status_id IN (5,6) THEN ISNULL(j.per_unit_price,0) ELSE 0 END awarded_price
				, a.award_date
				, c.part_name
				, e.discipline_name as process
				, d.material_name_en  as material 
				, NULL AS LowPrice 
				, NULL AS HighPrice
				, 1 AS IsAwardedToOtherQty
		/**/
		FROM mp_rfq			a	(NOLOCK)
		JOIN mp_rfq_parts	b	(NOLOCK) ON a.rfq_id = b.rfq_id
		JOIN mp_parts		c	(NOLOCK) ON b.part_id = c.part_id
		LEFT JOIN mp_mst_materials		d	(NOLOCK) ON c.material_id = d.material_id 
		LEFT JOIN mp_mst_part_category	e	(NOLOCK) ON c.part_category_id = e.part_category_id
		LEFT JOIN mp_rfq_part_quantity	f	(NOLOCK) ON b.rfq_part_id = f.rfq_part_id and f.is_deleted = 0
		LEFT JOIN mp_system_parameters	g	(NOLOCK) ON c.part_qty_unit_id = g.id and g.sys_key = '@UNIT2_LIST' 
		--JOIN #tmp_rfq_supplier_quoted_count h ON a.rfq_id = h.rfq_id  --select * from #tmp_rfq_supplier_quoted_count 
		JOIN #tmp_list_of_rfqs_for_shopiq_other h ON a.rfq_id = h.rfq_id and h.rfq_part_id = b.rfq_part_id
		  AND f.rfq_part_quantity_id = h.rfq_part_quantity_id
		--LEFT JOIN #tmp_rfq_part_quantity_per_unit_price i ON a.rfq_id = i.rfq_id AND f.rfq_part_quantity_id = i.rfq_part_quantity_id
		--LEFT JOIN #tmp_rfq_awarded_parts_per_unit_price j ON a.rfq_id = j.rfq_id AND f.rfq_part_quantity_id = j.rfq_part_quantity_id
		/* M2-3721 M - Add the Low and High price to all Quantities in Shop IQ- DB */
		--LEFT JOIN #tmp_rfq_part_quantity_low_high_price k ON a.rfq_id = k.rfq_id AND f.rfq_part_quantity_id = k.rfq_part_quantity_id
		/**/
		
		ORDER BY a.rfq_id 
				, b.rfq_part_id
				, f.rfq_part_quantity_id

		/* */
	
	END


	DELETE FROM mp_rfq_shopiq_metrics WHERE rfq_part_quantity_id is null

	;WITH DuplicateShopIq AS   
	(  
		SELECT 
			  rfq_shopiq_id 
			, rfq_id 
			, rfq_part_id 
			, rfq_part_quantity_id 
			, ROW_NUMBER() OVER (PARTITION BY rfq_id ,rfq_part_id ,rfq_part_quantity_id  ,IsAwardedToOtherQty ORDER BY rfq_id ,rfq_part_id ,rfq_part_quantity_id ,rfq_shopiq_id ,IsAwardedToOtherQty) AS rn 
			, IsAwardedToOtherQty
		FROM mp_rfq_shopiq_metrics 
	)  
	DELETE FROM DuplicateShopIq WHERE rn >1 	
	AND IsAwardedToOtherQty = 0 ---- M2-5022
	
	/*  M2-5022 : IF below records are duplicated then delete such records*/
	;WITH DuplicateShopIq AS   
	(  
		SELECT 
			  rfq_shopiq_id 
			, rfq_id 
			, rfq_part_id 
			, rfq_part_quantity_id 
			, ROW_NUMBER() OVER (PARTITION BY rfq_id ,rfq_part_id ,rfq_part_quantity_id ,IsAwardedToOtherQty ORDER BY rfq_id ,rfq_part_id ,rfq_part_quantity_id ,rfq_shopiq_id ,IsAwardedToOtherQty ) AS rn 
			, IsAwardedToOtherQty
		FROM mp_rfq_shopiq_metrics 
	)  
	DELETE FROM DuplicateShopIq WHERE  rn >1 
	AND IsAwardedToOtherQty = 1 
	/* */


END
