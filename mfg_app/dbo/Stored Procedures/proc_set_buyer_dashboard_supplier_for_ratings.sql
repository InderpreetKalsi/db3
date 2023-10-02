
/*    

		EXEC proc_set_buyer_dashboard_supplier_for_ratings  
	*/    
	CREATE PROCEDURE [dbo].[proc_set_buyer_dashboard_supplier_for_ratings]  AS  
	BEGIN        
		/*    -- Created : May 28, 2020       : M2-2902 Buyer - Dashboard - New Ratings Module - DB   */          
		--TRUNCATE TABLE mp_buyer_dashboard_supplier_for_ratings       
		
		-- list of non awarded manufacturers for rating     
		INSERT INTO mp_buyer_dashboard_supplier_for_ratings     (RfqId,RfqClosedDate,RfqAwardDate,BuyerId,SupplierId,QuoteDate,AwardedDate)     
		SELECT DISTINCT      
			a.rfq_id AS RfqId      
			,CONVERT(DATE,a.Quotes_needed_by) AS RfqClosedDate      
			,CONVERT(DATE,a.award_date) AS RfqAwardDate      
			,a.contact_id AS RfqBuyerId      
			,b.contact_id AS RfqSupplierId      
			,CONVERT(DATE,quote_date) AS SupplierQuotedOn      
			,NULL AS SupplierAwardedOn       
			--,CONVERT(DATE,awarded_date) AS SupplierAwardedOn1     
		FROM mp_rfq a (NOLOCK)      
		JOIN mp_rfq_quote_supplierquote b (NOLOCK)       
			ON	a.rfq_id = b.rfq_id        
				--AND a.rfq_status_id = 5       
				AND b.is_rfq_resubmitted = 0       
				AND is_quote_submitted = 1       
				--AND a.contact_id = 1337826       
				AND DATEADD(DAY,1,CONVERT(DATE,a.Quotes_needed_by)) = CONVERT(DATE,GETUTCDATE())       
				--AND YEAR(a.Quotes_needed_by) = 2020     
		LEFT JOIN mp_rfq_quote_items c (NOLOCK)       
			ON b.rfq_quote_supplierquote_id = c.rfq_quote_supplierquote_id     
		WHERE c.awarded_date IS NULL     
		ORDER BY RfqBuyerId  , RfqId , RfqSupplierId       
		
		-- list of awarded manufacturers for rating     
		INSERT INTO mp_buyer_dashboard_supplier_for_ratings     (RfqId,RfqClosedDate,RfqAwardDate,BuyerId,SupplierId,QuoteDate,AwardedDate)     
		SELECT DISTINCT      
			a.rfq_id AS RfqId      
			,CONVERT(DATE,a.Quotes_needed_by) AS RfqClosedDate      
			,CONVERT(DATE,a.award_date) AS RfqAwardDate      
			,a.contact_id AS RfqBuyerId      
			,b.contact_id AS RfqSupplierId      
			,CONVERT(DATE,quote_date) AS SupplierQuotedOn      
			,CONVERT(DATE,c.awarded_date) AS SupplierAwardedOn     
		FROM mp_rfq a (NOLOCK)      
		JOIN mp_rfq_quote_supplierquote b (NOLOCK)       
			ON	a.rfq_id = b.rfq_id        
				--AND a.rfq_status_id = 6       
				AND b.is_rfq_resubmitted = 0       
				AND is_quote_submitted = 1       
				--AND a.contact_id = 1337826     
		LEFT JOIN mp_rfq_quote_items c (NOLOCK)       
			ON b.rfq_quote_supplierquote_id = c.rfq_quote_supplierquote_id     
		WHERE       
			c.is_awrded = 1      
			AND DATEADD(DAY,8,CONVERT(DATE,c.awarded_date) ) = CONVERT(DATE,GETUTCDATE())      
			--AND YEAR(a.Quotes_needed_by) = 2020     
		ORDER BY RfqBuyerId  , RfqId , RfqSupplierId         

END
