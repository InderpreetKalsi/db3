
/*

TRUNCATE TABLE [XML_MFGPulse]
GO
EXEC proc_get_MFGPulseXML
GO
SELECT * FROM [XML_MFGPulse] ORDER BY [RecordDate] DESC

*/

	CREATE PROCEDURE [dbo].[proc_get_MFGPulseXML]
	AS
	BEGIN
		
		/* M2-3424 API - RFQ and Award info - DB */
		
		SET NOCOUNT ON
		
		DECLARE @MaxDate				DATETIME2
		DECLARE @MaxBuyerDate			DATETIME2
		DECLARE @MaxManufacturerDate	DATETIME2
		DECLARE @MaxRFQReleaseDate		DATETIME2
		DECLARE @Type					VARCHAR(100) = ''
		DECLARE @TodaysDate				DATETIME2 =  GETUTCDATE()
		DECLARE @RfqDeepLink			VARCHAR(1000) 
		DECLARE @RfqThumbnails			VARCHAR(1000) 
		DECLARE @RfqDefaultThumbnails			VARCHAR(1000) 

		--TRUNCATE TABLE [XML_MFGPulse]		


		IF DB_NAME() = 'mp2020_dev'
		BEGIN
			SET @RfqDeepLink = 'http://qa.mfg2020.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
			
		END
		ELSE IF DB_NAME() = 'mp2020_uat'
		BEGIN
			SET @RfqDeepLink = 'https://uatapp.mfg.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
			
		END
		ELSE IF DB_NAME() = 'mp2020_prod'
		BEGIN
			SET @RfqDeepLink = 'https://app.mfg.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
			
		END

	
		SET @RfqDefaultThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/3-d-big.png'
		SET @MaxDate =  ISNULL((SELECT MAX ([CreatedDate]) FROM [XML_MFGPulse] (NOLOCK)) , '2020-12-01 00:00:00.101' )
		SET @MaxDate =  DateAdd(millisecond,1,@MaxDate)

		INSERT INTO [XML_MFGPulse] ([Enclosure] , [Title]	,[Link]	,[Description]	,[RecordDate]	,[CreatedDate])
		-- 'Buyer Registration' 
		SELECT 
			'' AS Enclosure
			, 'Buyer Registration' AS Title 
			, 'https://www.mfg.com/get-leads' AS Link 
			,	'A Buyer in ' 
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' just joined MFG. <a href="https://www.mfg.com/get-leads">Register as a Manufacturer today.</a>' AS [Description] 
			,a.created_on AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM mp_contacts			(NOLOCK) a
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		WHERE a.is_buyer = 1 AND IsTestAccount = 0  
		AND a.created_on  BETWEEN  @MaxDate AND @TodaysDate
		AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- 'Manufacturer Registration'  
		SELECT 
			'' AS Enclosure
			, 'Manufacturer Registration' AS Title 
			, 'https://www.mfg.com/find-mfg' AS Link 
			,	'A Manufacturer in ' 
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' just joined MFG. <a href="https://www.mfg.com/find-mfg">Register as a Buyer today.</a>' AS [Description] 
			,a.created_on AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM mp_contacts			(NOLOCK) a
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		WHERE a.is_buyer = 0 AND IsTestAccount = 0
		AND a.created_on  BETWEEN  @MaxDate AND @TodaysDate		
		AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- 'New RFQ Available in [Marketplace]' 
		SELECT 
			ISNULL(@RfqThumbnails+j.file_name,@RfqDefaultThumbnails) AS Enclosure
			, 'New RFQ Available in '+m.discipline_name AS Title 
			, 'https://www.mfg.com/find-mfg' AS Link 
			,	'A Buyer in ' 
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' just posted ' + CASE WHEN LEFT(m.discipline_name,1) IN ('A','E','I','O','U') THEN 'an ' ELSE 'a ' END + m.discipline_name+' RFQ. <a href="'+@RfqDeepLink+ convert(varchar(500),e.rfq_guid)+'">Start quoting.</a>' AS [Description] 
			,f.status_date  AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM 
		mp_rfq						(NOLOCK) e
		JOIN mp_rfq_release_history	(NOLOCK) f ON e.rfq_id = f.rfq_id
		JOIN mp_contacts			(NOLOCK) a ON e.contact_id = a.contact_id
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		LEFT JOIN mp_special_files	(NOLOCK) j ON e.file_id = j.file_id
		JOIN mp_rfq_parts			(NOLOCK) k ON e.rfq_id = k.rfq_id and k.is_rfq_part_default = 1
		JOIN mp_mst_part_category	(NOLOCK) l ON k.part_category_id = l.part_category_id
		JOIN mp_mst_part_category	(NOLOCK) m ON l.parent_part_category_id = m.part_category_id
		WHERE f.status_date  BETWEEN  @MaxDate AND @TodaysDate
			AND a.IsTestAccount = 0
			AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- 'RFQ Awarded' 
		SELECT 
			RfqThumbnails  AS Enclosure
			, 'RFQ Awarded' AS Title 
			, 'https://www.mfg.com/find-mfg' AS Link 
			,	n.discipline_name+' Buyer in ' 
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' awarded a Manufacturer in ' 
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(k.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) ELSE k.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) END
				--+ CASE WHEN LEN(ISNULL(k.REGION_NAME,'')) = 0 THEN '' ELSE k.REGION_NAME + ', ' END
				--+ CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END
				+ '.'
				AS [Description] 
			,a1.awarded_date  AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM 
		(
			SELECT
			e.rfq_id AS RfqId
			,e.contact_id AS ContactId 
			,f.contact_id SupplierId 
			,g.awarded_date 
			,ROW_NUMBER() OVER (PARTITION BY f.contact_id , g.is_awrded ORDER BY f.contact_id , g.is_awrded , g.awarded_date ) RN
			,ISNULL(@RfqThumbnails+j.file_name,@RfqDefaultThumbnails) AS RfqThumbnails
			FROM 
			mp_rfq							(NOLOCK) e
			JOIN mp_rfq_quote_supplierquote	(NOLOCK) f ON e.rfq_id = f.rfq_id
			JOIN mp_rfq_quote_items			(NOLOCK) g ON f.rfq_quote_supplierquote_id = g.rfq_quote_supplierquote_id
			LEFT JOIN mp_special_files		(NOLOCK) j on e.file_id = j.file_id
			WHERE 
			g.is_awrded = 1 
			AND g.awarded_date BETWEEN  @MaxDate AND @TodaysDate
		) a1
		JOIN mp_contacts			(NOLOCK) a ON a1.ContactId = a.contact_id
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		LEFT JOIN mp_contacts		(NOLOCK) h ON a1.SupplierId = h.contact_id
		LEFT JOIN mp_addresses		(NOLOCK) i ON h.address_id = i.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) j ON i.country_id = j.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) k ON i.region_id = k.region_id AND k.region_id <> 0
		JOIN mp_rfq_parts			(NOLOCK) l ON a1.RfqId = l.rfq_id and l.is_rfq_part_default = 1
		JOIN mp_mst_part_category	(NOLOCK) m ON l.part_category_id = m.part_category_id
		JOIN mp_mst_part_category	(NOLOCK) n ON m.parent_part_category_id = n.part_category_id
		WHERE a1.RN = 1  AND a.IsTestAccount = 0
		AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- Buyer Followed
		SELECT 
			'' AS Enclosure
			, 'Buyer Followed' AS Title 
			, 'https://www.mfg.com/find-mfg' AS Link 
			,	'A Manufacturer in ' 
				--+ CASE WHEN LEN(ISNULL(b.address4,'')) = 0 THEN ''  ELSE b.address4 + ' ,' END
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' is now following a Buyer in ' 
				--+ CASE WHEN LEN(ISNULL(i.address4,'')) = 0 THEN ''  ELSE i.address4 + ' ,' END
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(k.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) ELSE k.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) END
				+ '.'
				AS [Description] 
			,f.creation_date  AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM 
		mp_books					(NOLOCK) e
		JOIN mp_book_details		(NOLOCK) f ON e.book_id = f.book_id AND bk_type = 4 AND f.company_id <> 0
		JOIN mp_contacts			(NOLOCK) a ON e.contact_id = a.contact_id  AND a.is_buyer =0  
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		LEFT JOIN mp_contacts		(NOLOCK) h ON f.company_id = h.company_id AND h.is_buyer = 1 and h.is_admin=1
		LEFT JOIN mp_addresses		(NOLOCK) i ON h.address_id = i.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) j ON i.country_id = j.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) k ON i.region_id = k.region_id AND k.region_id <> 0
		WHERE f.creation_date  BETWEEN  @MaxDate AND @TodaysDate  AND a.IsTestAccount = 0
		AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- Manufacturer Followed
		SELECT 
			'' AS Enclosure
			, 'Manufacturer Followed' AS Title 
			, 'https://www.mfg.com/get-leads' AS Link 
			,	'A Buyer in ' 
				--+ CASE WHEN LEN(ISNULL(b.address4,'')) = 0 THEN ''  ELSE b.address4 + ' ,' END
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(d.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) ELSE d.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(c.country_name,'')) = 0  THEN '' ELSE c.country_name END) END
				+ ' is now following a Manufacturer in ' 
				--+ CASE WHEN LEN(ISNULL(i.address4,'')) = 0 THEN ''  ELSE i.address4 + ' ,' END
				+ CASE WHEN b.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(k.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) ELSE k.REGION_NAME END) ELSE '' END
				+ CASE WHEN b.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) END
				+ '.'
				AS [Description] 
			,f.creation_date  AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM 
		mp_books					(NOLOCK) e
		JOIN mp_book_details		(NOLOCK) f ON e.book_id = f.book_id AND bk_type = 4 AND f.company_id <> 0
		JOIN mp_contacts			(NOLOCK) a ON e.contact_id = a.contact_id  AND a.is_buyer =1  
		LEFT JOIN mp_addresses		(NOLOCK) b ON a.address_id = b.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) c ON b.country_id = c.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
		LEFT JOIN mp_contacts		(NOLOCK) h ON f.company_id = h.company_id AND h.is_buyer = 0 and h.is_admin=1
		LEFT JOIN mp_addresses		(NOLOCK) i ON h.address_id = i.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) j ON i.country_id = j.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) k ON i.region_id = k.region_id AND k.region_id <> 0
		WHERE f.creation_date  BETWEEN  @MaxDate AND @TodaysDate  AND a.IsTestAccount = 0
		AND b.country_id IN (92, 57, 377) AND b.country_id <> 0
		UNION
		-- RFQ Liked
		SELECT 
			ISNULL(@RfqThumbnails+j1.file_name,@RfqDefaultThumbnails) AS Enclosure
			, 'RFQ Liked' AS Title 
			, 'https://www.mfg.com/find-mfg' AS Link 
			,	'A Manufacturer just liked ' + CASE WHEN LEFT(n.discipline_name,1) IN ('A','E','I','O','U') THEN 'an ' ELSE 'a ' END + n.discipline_name+' RFQ posted by a Buyer in ' 
				--+ CASE WHEN LEN(ISNULL(i.address4,'')) = 0 THEN ''  ELSE i.address4 + ' ,' END
				+ CASE WHEN i.country_id IN  (92)  THEN (CASE WHEN LEN(ISNULL(k.REGION_NAME,'')) = 0 THEN (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) ELSE k.REGION_NAME END) ELSE '' END
				+ CASE WHEN i.country_id IN  (92)  THEN '' ELSE (CASE WHEN LEN(ISNULL(j.country_name,'')) = 0  THEN '' ELSE j.country_name END) END
				+ '.'
				AS [Description] 
			,e.like_date  AS RecordDate
			,@TodaysDate AS [CreatedDate]
		FROM 
		mp_rfq_supplier_likes		(NOLOCK) e
		LEFT JOIN mp_rfq			(NOLOCK) g ON e.rfq_id = g.rfq_id
		LEFT JOIN mp_contacts		(NOLOCK) h ON g.contact_id = h.contact_id
		LEFT JOIN mp_addresses		(NOLOCK) i ON h.address_id = i.address_id
		LEFT JOIN mp_mst_country	(NOLOCK) j ON i.country_id = j.country_id
		LEFT JOIN mp_mst_region		(NOLOCK) k ON i.region_id = k.region_id AND k.region_id <> 0
		LEFT JOIN mp_special_files	(NOLOCK) j1 on g.file_id = j1.file_id
		JOIN mp_rfq_parts			(NOLOCK) l ON e.rfq_id = l.rfq_id and l.is_rfq_part_default = 1
		JOIN mp_mst_part_category	(NOLOCK) m ON l.part_category_id = m.part_category_id
		JOIN mp_mst_part_category	(NOLOCK) n ON m.parent_part_category_id = n.part_category_id
		WHERE e.like_date  BETWEEN  @MaxDate AND @TodaysDate  AND h.IsTestAccount = 0
		AND i.country_id IN (92, 57, 377) AND i.country_id <> 0
		ORDER BY RecordDate DESC 

		--SELECT @TodaysDate

		SELECT TOP 25 [Enclosure] ,[Title]	,[Link]	,[Description] 
		FROM [XML_MFGPulse] (NOLOCK)
		--WHERE [CreatedDate]  = @TodaysDate
		ORDER BY RecordDate DESC


	END
