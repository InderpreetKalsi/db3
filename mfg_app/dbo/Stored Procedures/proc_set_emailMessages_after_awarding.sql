CREATE PROCEDURE [dbo].[proc_set_emailMessages_after_awarding]
AS
BEGIN

	/* FEB 26, 2020 M2-2518  Buyer - Awarding bugs - DB */
	
	
	DROP TABLE IF EXISTS #tmp_part_awarded
	DROP TABLE IF EXISTS #tmp_awarded_rfqs
	DROP TABLE IF EXISTS #list_of_contacts


	SELECT 
		rfq_id, from_cont, to_cont 
	INTO #tmp_awarded_rfqs
	FROM 
	mp_messages (NOLOCK)
	WHERE 
		message_type_id = 7
		AND CONVERT(DATE,message_date+7)  =  CONVERT(DATE, GETUTCDATE())

	SELECT DISTINCT 
		a.rfq_id , a.rfq_name , a.contact_id buyer_id, b.contact_id supplier_id,
		e.part_name + ' ' +  CONVERT(VARCHAR(50) ,c.awarded_qty) + ' ' + f.value   parts_awarded
	INTO #tmp_part_awarded
	FROM mp_rfq						a (NOLOCK)
	JOIN mp_rfq_quote_SupplierQuote b (NOLOCK) ON a.rfq_id = b.rfq_id  AND  is_rfq_resubmitted = 0
	JOIN mp_rfq_quote_items			c (NOLOCK) ON b.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
	JOIN mp_rfq_parts				d (NOLOCK) ON c.rfq_part_id = d.rfq_part_id 
	JOIN mp_parts					e (NOLOCK) ON d.part_id = e.part_id 
	JOIN mp_system_parameters		f (NOLOCK) ON e.part_qty_unit_id = f.id
	WHERE 
		is_awrded =1 
		AND a.rfq_id IN (SELECT DISTINCT rfq_id FROM #tmp_awarded_rfqs)

	SELECT 
		a.company_id, a.contact_id ,   b.email AS  email_id
		,a.first_name + ' ' + a.last_name AS username
		,c.name AS company
		,1 AS is_buyer
		,a.is_notify_by_email  /* M2-4789*/
	INTO #list_of_contacts
	FROM mp_contacts		a (NOLOCK) 
	LEFT JOIN aspnetusers	b (NOLOCK) ON a.user_id = b.id
	LEFT JOIN mp_companies  c (NOLOCK) ON a.company_id = c.company_id
	WHERE a.contact_id IN (SELECT DISTINCT from_cont FROM #tmp_awarded_rfqs)
	UNION
	SELECT 
		a.company_id, a.contact_id ,   b.email AS  email_id
		,a.first_name + ' ' + a.last_name AS username
		,c.name AS company
		,0 AS is_buyer
		,a.is_notify_by_email  /* M2-4789*/
	FROM mp_contacts		a (NOLOCK) 
	LEFT JOIN aspnetusers	b (NOLOCK) ON a.user_id = b.id
	LEFT JOIN mp_companies  c (NOLOCK) ON a.company_id = c.company_id
	WHERE a.contact_id IN (SELECT DISTINCT to_cont FROM #tmp_awarded_rfqs)

	--SELECT * FROM #tmp_awarded_rfqs
	--SELECT * FROM #tmp_part_awarded
	--SELECT * FROM #list_of_contacts


	INSERT INTO mp_messages
	( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
	SELECT DISTINCT
		a.rfq_id 	
		,	CASE 
				WHEN  message_type_name = 'BUYER_NPS_RATING' THEN e.message_type_id						
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN e.message_type_id						
			END  AS  message_type_id 
		, message_subject_template  AS message_subject 
		, CASE 
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN
						REPLACE(REPLACE(message_body_template, '#Buyer_Name#', b.username) , '#Manufacturer_company_name#' ,c.company) 
				WHEN  message_type_name = 'BUYER_NPS_RATING' THEN
					REPLACE(REPLACE(message_body_template, '#Manufacturer_Contact_name#', c.username)  , '#Company_Name#',b.company)
		  END  AS message_descr	
		, GETUTCDATE() AS message_date	
		, CASE 
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN c.contact_id				
				WHEN  message_type_name = 'BUYER_NPS_RATING'	THEN	b.contact_id   					
		  END AS from_contact_id 
		, CASE 			
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN b.contact_id 			
				WHEN  message_type_name = 'BUYER_NPS_RATING'	THEN  	c.contact_id			
		  END AS to_contact_id 
		, 0 AS message_sent
		, 0 AS message_read
		, 0 AS trash
		, 0 AS from_trash
		, 0 AS real_from_cont_id
		, 0 AS is_last_message
		, 0 AS message_status_id_recipient
		, 0 AS message_status_id_author
	FROM 
	#tmp_part_awarded a
	JOIN #list_of_contacts b ON a.buyer_id = b.contact_id
	JOIN #list_of_contacts c ON a.supplier_id = c.contact_id 
	JOIN  
	(
		SELECT distinct  a.rfq_id, a.supplier_id  , REPLACE((SELECT parts = stuff(( SELECT ','+  parts_awarded	
		FROM  #tmp_part_awarded WHERE supplier_id = a.supplier_id	FOR XML PATH('') ), 1, 1, '')) ,',' , ', ') AS parts
		FROM #tmp_part_awarded a	
	) d ON a.rfq_id = d.rfq_id AND a.supplier_id = d.supplier_id
	CROSS APPLY
	(
		SELECT 
			a.message_type_id
			,a.message_type_name 
			,message_subject_template
			,message_body_template
			,email_body_template
			,email_subject_template 
		FROM 
		mp_mst_message_types  a
		JOIN mp_mst_email_template b ON a.message_type_id = b.message_type_id
		WHERE a.message_type_name IN 
		('SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING'
		)
	) e 	

	INSERT INTO mp_email_messages
	( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
	,from_cont ,to_cont, to_email, message_sent,message_read )
	SELECT DISTINCT
		a.rfq_id 	
		,	CASE 
				WHEN  message_type_name = 'BUYER_NPS_RATING' THEN e.message_type_id						
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN e.message_type_id						
			END  AS  message_type_id 
		, email_subject_template  AS email_msg_subject 
		, CASE 
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN
					REPLACE(REPLACE(REPLACE(email_body_template, '#Buyer_Name#', b.username) , '#Manufacturer_company_name#' ,c.company) ,'#Message_Link#','')
				when  message_type_name = 'BUYER_NPS_RATING' THEN
						REPLACE(REPLACE(REPLACE(email_body_template, '#Manufacturer_Contact_name#',  c.username)  , '#Company_Name#',b.company),'#Message_Link#','')
		  END   email_msg_body
		, GETUTCDATE() AS message_date	
		, CASE 
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN c.contact_id				
				WHEN  message_type_name = 'BUYER_NPS_RATING'	THEN b.contact_id   					
		  END AS from_contact_id 
		, CASE 			
				WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN b.contact_id 			
				WHEN  message_type_name = 'BUYER_NPS_RATING'	THEN c.contact_id			
		  END AS to_contact_id 
		, CASE WHEN  message_type_name = 'SUPPLIER_NPS_RATING' THEN  b.email_id ELSE c.email_id END AS to_email_id
		, 0 AS message_sent
		, 0 AS message_read
	FROM 
	#tmp_part_awarded a
	JOIN #list_of_contacts b ON a.buyer_id = b.contact_id
	JOIN #list_of_contacts c ON a.supplier_id = c.contact_id 
	AND c.is_notify_by_email = 1 /* M2-4789*/
	JOIN  
	(
		SELECT distinct  a.rfq_id, a.supplier_id  , REPLACE((SELECT parts = STUFF(( SELECT ','+  parts_awarded	
		FROM  #tmp_part_awarded WHERE supplier_id = a.supplier_id	FOR XML PATH('') ), 1, 1, '')) ,',' , ', ') AS parts
		FROM #tmp_part_awarded a	
	) d ON a.rfq_id = d.rfq_id AND a.supplier_id = d.supplier_id
	CROSS APPLY
	(
		SELECT 
			a.message_type_id
			,a.message_type_name 
			,message_subject_template
			,message_body_template
			,email_body_template
			,email_subject_template 
		FROM 
		mp_mst_message_types  a
		JOIN mp_mst_email_template b ON a.message_type_id = b.message_type_id
		WHERE a.message_type_name IN 
		('SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING'
		)
	) e 	

END

