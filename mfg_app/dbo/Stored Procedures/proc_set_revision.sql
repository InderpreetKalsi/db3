
/*

EXEC [proc_set_revision]
		
*/
CREATE PROCEDURE [dbo].[proc_set_revision]
AS
BEGIN
		
	TRUNCATE TABLE [tmp_trans].revision_data_history
	TRUNCATE TABLE [tmp_trans].revision_data_history_1
	TRUNCATE TABLE [tmp_trans].revision_data_history_2
	TRUNCATE TABLE [tmp_trans].revision_data_history_3
	TRUNCATE TABLE [tmp_trans].revision_data_history_4
	TRUNCATE TABLE [tmp_trans].revision_data_history_5
	TRUNCATE TABLE [tmp_trans].revision_versions 
	TRUNCATE TABLE [tmp_trans].revision_data_history_old_values
	TRUNCATE TABLE [tmp_trans].revision_data_history_new_values 

	
	INSERT INTO [tmp_trans].[revision_data_history] (data_history_id,field,oldvalue,newvalue,creation_date,userid,tablename,is_processed,processed_date)
	SELECT data_history_id,field,oldvalue,newvalue,creation_date,userid,tablename,is_processed,processed_date 
	FROM dbo.mp_data_history (NOLOCK)
	WHERE  tablename in ('mp_rfq', 'mp_rfq_special_certificates','mp_rfq_preferences','mp_rfq_parts', 'mp_rfq_part_quantity','mpOrderManagement')
	and is_processed = 0
	ORDER BY data_history_id

	IF ((SELECT COUNT(1) FROM [tmp_trans].[revision_data_history]) > 0)
	BEGIN


		UPDATE dbo.mp_data_history SET is_processed = 1 , processed_date = GETUTCDATE() 
		WHERE data_history_id IN (SELECT data_history_id FROM [tmp_trans].[revision_data_history]  (NOLOCK))

		
		INSERT INTO [tmp_trans].[revision_data_history_1] 
		(data_history_id,userid,creation_date,tablename,rfq_id,rfq_part_id,rfq_part_qty_id,rfq_special_certificate_id,rfq_preference_id)
		SELECT 
			a.data_history_id, 
			a.userid ,
			a.creation_date ,  
			a.tablename ,
			CASE 
				WHEN JSON_VALUE(field, '$.RfqPartQuantityId') IS NOT NULL THEN c1.rfq_id 
				WHEN JSON_VALUE(field, '$.RfqPartId') IS NOT NULL THEN c.rfq_id 
				WHEN JSON_VALUE(field, '$.RfqSpecialCertificatesId') IS NOT NULL THEN d.rfq_id
				WHEN JSON_VALUE(field, '$.RfqPreferencesId') IS NOT NULL THEN e.rfq_id 
				ELSE JSON_VALUE(field, '$.RfqId') 
			END   rfq_id ,
			CASE WHEN JSON_VALUE(field, '$.RfqPartQuantityId') IS NOT NULL THEN b.rfq_part_id ELSE JSON_VALUE(field, '$.RfqPartId')  END rfq_part_id ,  
			JSON_VALUE(field, '$.RfqPartQuantityId') rfq_part_qty_id  	,
			JSON_VALUE(field, '$.RfqSpecialCertificatesId') rfq_special_certificate_id	,
			JSON_VALUE(field, '$.RfqPreferencesId') rfq_preference_id	
		
		FROM [tmp_trans].revision_data_history a  (NOLOCK)
		LEFT JOIN mp_rfq_part_quantity	b	(NOLOCK) ON JSON_VALUE(a.field, '$.RfqPartQuantityId') = b.rfq_part_quantity_id
		LEFT JOIN mp_rfq_parts			c	(NOLOCK) ON (JSON_VALUE(field, '$.RfqPartId') = c.rfq_part_id)
		LEFT JOIN mp_rfq_parts			c1	(NOLOCK) ON b.rfq_part_id = c1.rfq_part_id
		LEFT JOIN mp_rfq_special_certificates d	(NOLOCK) ON JSON_VALUE(field, '$.RfqSpecialCertificatesId') = d.rfq_special_certificates_id
		LEFT JOIN mp_rfq_preferences	e	(NOLOCK) ON JSON_VALUE(field, '$.RfqPreferencesId') = e.rfq_preferences_id
		

		--SELECT * FROM mp_rfq_special_certificates WHERE rfq_special_certificates_id = 12202			

		DELETE FROM [tmp_trans].[revision_data_history_1]WHERE rfq_id IS NULL

		
		--SELECT * FROM #revision_data_history ORDER BY data_history_id
		--SELECT * FROM #revision_data_history_1 ORDER BY data_history_id
		INSERT INTO [tmp_trans].revision_data_history_old_values 
		(data_history_id,RFQName,PartId,IsRfqPartDefault,MinPartQuantity,MinPartQuantityUnit,IsSpecialCertificationsByManufacture,CertificateId,AwardDate
		,ImportancePrice,ImportanceQuality,ImportanceSpeed,IsRegisterSupplierQuoteTheRfq,IsSpecialInstructionToManufacturer,PrefRfqCommunicationMethod,
		QuotesNeededBy,SpecialInstructionToManufacturer,RfqPrefManufacturingLocationId,PaymentTermId,PrefNdaType,WhoPaysForShipping,RfqStatusId,QuantityLevel,
		PartQty,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus)
		SELECT 
			data_history_id ,
			ISNULL(JSON_VALUE(oldvalue, '$.RfqName'),'') AS RFQName ,
			ISNULL(JSON_VALUE(oldvalue, '$.PartId'),'') AS PartId ,
			ISNULL(JSON_VALUE(oldvalue, '$.IsRfqPartDefault'),'') AS IsRfqPartDefault ,
			ISNULL(JSON_VALUE(oldvalue, '$.MinPartQuantity'),'') AS MinPartQuantity ,
			ISNULL(JSON_VALUE(oldvalue, '$.MinPartQuantityUnit'),'') AS MinPartQuantityUnit ,
			ISNULL(JSON_VALUE(oldvalue, '$.IsSpecialCertificationsByManufacture'),'') AS IsSpecialCertificationsByManufacture ,
			ISNULL(JSON_VALUE(oldvalue, '$.CertificateId'),'') AS CertificateId ,
			ISNULL(CONVERT(VARCHAR(19),JSON_VALUE(oldvalue, '$.AwardDate'),120),'') AS AwardDate ,
			ISNULL(JSON_VALUE(oldvalue, '$.ImportancePrice'),'') AS ImportancePrice ,
			ISNULL(JSON_VALUE(oldvalue, '$.ImportanceQuality'),'') AS ImportanceQuality ,
			ISNULL(JSON_VALUE(oldvalue, '$.ImportanceSpeed'),'') AS ImportanceSpeed ,
			ISNULL(JSON_VALUE(oldvalue, '$.IsRegisterSupplierQuoteTheRfq'),'') AS IsRegisterSupplierQuoteTheRfq ,
			ISNULL(JSON_VALUE(oldvalue, '$.IsSpecialInstructionToManufacturer'),'') AS IsSpecialInstructionToManufacturer ,
			ISNULL(JSON_VALUE(oldvalue, '$.PrefRfqCommunicationMethod'),'') AS PrefRfqCommunicationMethod ,
			ISNULL(CONVERT(VARCHAR(19),JSON_VALUE(oldvalue, '$.QuotesNeededBy'),120),'') AS QuotesNeededBy ,
			ISNULL(JSON_VALUE(oldvalue, '$.SpecialInstructionToManufacturer'),'') AS SpecialInstructionToManufacturer ,
			ISNULL(JSON_VALUE(oldvalue, '$.RfqPrefManufacturingLocationId'),'') AS RfqPrefManufacturingLocationId ,
			ISNULL(JSON_VALUE(oldvalue, '$.PaymentTermId'),'') AS PaymentTermId,
			ISNULL(JSON_VALUE(oldvalue, '$.PrefNdaType'),'') AS PrefNdaType,
			ISNULL(JSON_VALUE(oldvalue, '$.WhoPaysForShipping'),'') AS WhoPaysForShipping,
			ISNULL(JSON_VALUE(oldvalue, '$.RfqStatusId'),'') AS RfqStatusId,
			ISNULL(JSON_VALUE(oldvalue, '$.QuantityLevel'),'') AS QuantityLevel,
			ISNULL(JSON_VALUE(oldvalue, '$.PartQty'),'') AS PartQty,
			ISNULL(JSON_VALUE(oldvalue, '$.IsSpecialCertificationsByManufacturer'),'') AS IsSpecialCertificationsByManufacturer,
			ISNULL(JSON_VALUE(oldvalue, '$.ShipTo'),'') AS ShipTo,
			ISNULL(JSON_VALUE(oldvalue, '$.POCreated'),'') AS POCreated,
			ISNULL(JSON_VALUE(oldvalue, '$.POStatus'),'') AS POStatus,
			ISNULL(JSON_VALUE(oldvalue, '$.POPartStatus'),'') AS POPartStatus
		FROM [tmp_trans].revision_data_history  (NOLOCK)

		INSERT INTO [tmp_trans].revision_data_history_new_values 
		(data_history_id,RFQName,PartId,IsRfqPartDefault,MinPartQuantity,MinPartQuantityUnit,IsSpecialCertificationsByManufacture,CertificateId,AwardDate
		,ImportancePrice,ImportanceQuality,ImportanceSpeed,IsRegisterSupplierQuoteTheRfq,IsSpecialInstructionToManufacturer,PrefRfqCommunicationMethod,
		QuotesNeededBy,SpecialInstructionToManufacturer,RfqPrefManufacturingLocationId,PaymentTermId,PrefNdaType,WhoPaysForShipping,RfqStatusId,QuantityLevel,
		PartQty,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus)
		SELECT 
			data_history_id , 
			ISNULL(JSON_VALUE(newvalue, '$.RfqName'),'') AS RFQName ,
			ISNULL(JSON_VALUE(newvalue, '$.PartId'),'') AS PartId ,
			ISNULL(JSON_VALUE(newvalue, '$.IsRfqPartDefault'),'') AS IsRfqPartDefault ,
			ISNULL(JSON_VALUE(newvalue, '$.MinPartQuantity'),'') AS MinPartQuantity ,
			ISNULL(JSON_VALUE(newvalue, '$.MinPartQuantityUnit'),'') AS MinPartQuantityUnit ,
			ISNULL(JSON_VALUE(newvalue, '$.IsSpecialCertificationsByManufacture'),'') AS IsSpecialCertificationsByManufacture ,
			ISNULL(JSON_VALUE(newvalue, '$.CertificateId'),'') AS CertificateId ,
			ISNULL(CONVERT(VARCHAR(19),JSON_VALUE(newvalue, '$.AwardDate'),120),'') AS AwardDate ,
			ISNULL(JSON_VALUE(newvalue, '$.ImportancePrice'),'') AS ImportancePrice ,
			ISNULL(JSON_VALUE(newvalue, '$.ImportanceQuality'),'') AS ImportanceQuality ,
			ISNULL(JSON_VALUE(newvalue, '$.ImportanceSpeed'),'') AS ImportanceSpeed ,
			ISNULL(JSON_VALUE(newvalue, '$.IsRegisterSupplierQuoteTheRfq'),'') AS IsRegisterSupplierQuoteTheRfq ,
			ISNULL(JSON_VALUE(newvalue, '$.IsSpecialInstructionToManufacturer'),'') AS IsSpecialInstructionToManufacturer ,
			ISNULL(JSON_VALUE(newvalue, '$.PrefRfqCommunicationMethod'),'') AS PrefRfqCommunicationMethod ,
			ISNULL(CONVERT(VARCHAR(19),JSON_VALUE(newvalue, '$.QuotesNeededBy'),120),'') AS QuotesNeededBy ,
			ISNULL(JSON_VALUE(newvalue, '$.SpecialInstructionToManufacturer'),'') AS SpecialInstructionToManufacturer ,
			ISNULL(JSON_VALUE(newvalue, '$.RfqPrefManufacturingLocationId'),'') AS RfqPrefManufacturingLocationId,
			ISNULL(JSON_VALUE(newvalue, '$.PaymentTermId'),'') AS PaymentTermId,
			ISNULL(JSON_VALUE(newvalue, '$.PrefNdaType'),'') AS PrefNdaType,
			ISNULL(JSON_VALUE(newvalue, '$.WhoPaysForShipping'),'') AS WhoPaysForShipping,
			ISNULL(JSON_VALUE(newvalue, '$.RfqStatusId'),'') AS RfqStatusId,
			ISNULL(JSON_VALUE(newvalue, '$.QuantityLevel'),'') AS QuantityLevel,
			ISNULL(JSON_VALUE(newvalue, '$.PartQty'),'') AS PartQty,
			ISNULL(JSON_VALUE(newvalue, '$.IsSpecialCertificationsByManufacturer'),'') AS IsSpecialCertificationsByManufacturer,
			ISNULL(JSON_VALUE(newvalue, '$.ShipTo'),'') AS ShipTo,
			ISNULL(JSON_VALUE(newvalue, '$.POCreated'),'') AS POCreated,
			ISNULL(JSON_VALUE(newvalue, '$.POStatus'),'') AS POStatus,
			ISNULL(JSON_VALUE(newvalue, '$.POPartStatus'),'') AS POPartStatus
		FROM [tmp_trans].revision_data_history  (NOLOCK)


		--SELECT * FROM [tmp_trans].revision_data_history_old_values  ORDER BY data_history_id
		--SELECT * FROM [tmp_trans].revision_data_history_new_values   ORDER BY data_history_id

		INSERT INTO [tmp_trans].revision_data_history_2 (Id, RFQAttributes , Oldvalues)
		SELECT data_history_id AS Id, RFQAttributes, Oldvalues  
		FROM   
		(
			SELECT 
				data_history_id, RFQName,PartId,	IsRfqPartDefault	,MinPartQuantity	,MinPartQuantityUnit	,IsSpecialCertificationsByManufacture	,CertificateId	
				,AwardDate	,ImportancePrice	,ImportanceQuality	,ImportanceSpeed	,IsRegisterSupplierQuoteTheRfq	,IsSpecialInstructionToManufacturer	
				,PrefRfqCommunicationMethod	,QuotesNeededBy	, SpecialInstructionToManufacturer ,RfqPrefManufacturingLocationId, PaymentTermId 
				,PrefNdaType ,WhoPaysForShipping,RfqStatusId,QuantityLevel ,PartQty ,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus
 
			FROM  [tmp_trans].revision_data_history_old_values  (NOLOCK)
		) p  
		UNPIVOT  
		(	Oldvalues FOR RFQAttributes IN   
			(
					RFQName,PartId,	IsRfqPartDefault	,MinPartQuantity	,MinPartQuantityUnit	,IsSpecialCertificationsByManufacture	,CertificateId	
				,AwardDate	,ImportancePrice	,ImportanceQuality	,ImportanceSpeed	,IsRegisterSupplierQuoteTheRfq	,IsSpecialInstructionToManufacturer	
				,PrefRfqCommunicationMethod	,QuotesNeededBy	, SpecialInstructionToManufacturer,RfqPrefManufacturingLocationId, PaymentTermId 
				,PrefNdaType ,WhoPaysForShipping,RfqStatusId,QuantityLevel,PartQty,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus
			)  
		)AS unpvt	; 

	
		UPDATE  a SET a.NewValues = b.Newvalues
		FROM    [tmp_trans].revision_data_history_2 a
		JOIN
		(
			SELECT data_history_id AS Id, RFQAttributes, NewValues  
			FROM   
			(
				SELECT 
					data_history_id, RFQName,PartId,	IsRfqPartDefault	,MinPartQuantity	,MinPartQuantityUnit	,IsSpecialCertificationsByManufacture	,CertificateId	
					,AwardDate	,ImportancePrice	,ImportanceQuality	,ImportanceSpeed	,IsRegisterSupplierQuoteTheRfq	,IsSpecialInstructionToManufacturer	
					,PrefRfqCommunicationMethod	,QuotesNeededBy	, SpecialInstructionToManufacturer,RfqPrefManufacturingLocationId
					,PaymentTermId ,PrefNdaType ,WhoPaysForShipping,RfqStatusId,QuantityLevel,PartQty,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus
 
				FROM  [tmp_trans].revision_data_history_new_values  (NOLOCK)
			) p  
			UNPIVOT  
			(	NewValues FOR RFQAttributes IN   
				(
					 RFQName,PartId,	IsRfqPartDefault	,MinPartQuantity	,MinPartQuantityUnit	,IsSpecialCertificationsByManufacture	,CertificateId	
					,AwardDate	,ImportancePrice	,ImportanceQuality	,ImportanceSpeed	,IsRegisterSupplierQuoteTheRfq	,IsSpecialInstructionToManufacturer	
					,PrefRfqCommunicationMethod	,QuotesNeededBy	, SpecialInstructionToManufacturer,RfqPrefManufacturingLocationId, PaymentTermId ,PrefNdaType 
					,WhoPaysForShipping,RfqStatusId,QuantityLevel,PartQty,IsSpecialCertificationsByManufacturer,ShipTo,POCreated,POStatus,POPartStatus
				)  
			)AS unpvt	
		) b on a.Id = b.Id and a.RFQAttributes = b.RFQAttributes

		--select * from [tmp_trans].revision_data_history_2 

		DELETE [tmp_trans].revision_data_history_2 WHERE ( NewValues = '' AND OldValues= '')

		INSERT INTO [tmp_trans].revision_data_history_3
		(data_history_id	,userid	,creation_date	,tablename	,rfq_id	,rfq_part_id	,rfq_part_qty_id	,rfq_special_certificate_id	
			,rfq_preference_id	,Id	,RFQAttributes	,OldValues	,NewValues	,Field	,oldvalue ,newvalue)
		SELECT 
			data_history_id	,userid	,creation_date	,tablename	,rfq_id	,rfq_part_id	,rfq_part_qty_id	,rfq_special_certificate_id	
			,rfq_preference_id	,Id	,RFQAttributes	,OldValues	,NewValues	,Field	,oldvalue ,newvalue
		FROM
		(
			SELECT a.*  
			, b.* 
			, CASE 
				WHEN  RFQAttributes = 'PartId' THEN 'Part Newly added "'+ISNULL(d.part_name,'')+'"'
				WHEN  RFQAttributes = 'IsRfqPartDefault' THEN '"'+ISNULL(d.part_name,'')+'" - Is Default RFQ Part?'
				WHEN  RFQAttributes = 'QuantityLevel' THEN 'Part Qty Level'
				WHEN  RFQAttributes = 'PartQty' THEN ''
				WHEN  RFQAttributes = 'MinPartQuantity' THEN ISNULL(d.part,'')
				WHEN  RFQAttributes = 'MinPartQuantityUnit' THEN ''
				WHEN  RFQAttributes = 'RFQName' THEN 'Rfq Name'
				WHEN  RFQAttributes = 'AwardDate' THEN 'Award date'
				WHEN  RFQAttributes = 'ImportancePrice' THEN 'Price'
				WHEN  RFQAttributes = 'ImportanceQuality' THEN 'Quality'
				WHEN  RFQAttributes = 'ImportanceSpeed' THEN 'Speed'
				WHEN  RFQAttributes = 'IsRegisterSupplierQuoteTheRfq' THEN 'Is registered Supplier quote the RFQ'
				WHEN  RFQAttributes = 'IsSpecialInstructionToManufacturer' THEN 'Is special instruction to Manufacturer?'
				WHEN  RFQAttributes = 'PrefRfqCommunicationMethod' THEN 'Preferred Communication'
				WHEN  RFQAttributes = 'QuotesNeededBy' THEN 'Quotes needed by'
				WHEN  RFQAttributes = 'SpecialInstructionToManufacturer' THEN 'Special instruction to Manufacturer'
				WHEN  RFQAttributes = 'PaymentTermId' THEN 'Payment Term' 
				WHEN  RFQAttributes = 'PrefNdaType' THEN 'Preferred NDA Type' 
				WHEN  RFQAttributes = 'WhoPaysForShipping' THEN 'Who pays for shipping'
				WHEN  RFQAttributes = 'RfqStatusId' THEN 'RFQ Status'
				WHEN  RFQAttributes = 'RfqPrefManufacturingLocationId' THEN 'RFQ Preferred location'
				WHEN  RFQAttributes = 'CertificateId' THEN 'RFQ Certificate'
				WHEN  RFQAttributes = 'IsSpecialCertificationsByManufacturer' THEN 'Is special certifications by Manufacturer?'
				WHEN  RFQAttributes = 'ShipTo' THEN 'Shipping Address'
				WHEN  RFQAttributes = 'POCreated' THEN 'PO sent to manufacturer' 
				WHEN  RFQAttributes = 'POStatus' THEN 'PO status updated' 
				WHEN  RFQAttributes = 'POPartStatus' THEN 'PO Part status updated - "'+ISNULL(d.part_name,'')+'"'
			END Field
			, CASE 
				WHEN  RFQAttributes = 'PartId' THEN ''
				WHEN  RFQAttributes = 'IsRfqPartDefault' THEN 
					CASE 
						WHEN oldvalues = 'false' THEN 'No'
						WHEN oldvalues = 'true' THEN 'Yes'
						ELSE oldvalues
					 END	
				WHEN  RFQAttributes = 'ImportancePrice' THEN 
					CASE 
						WHEN oldvalues = 1 THEN 'High Importance'
						WHEN oldvalues = 2 THEN 'Middle importance'
						WHEN oldvalues = 3 THEN 'Low importance'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'ImportanceQuality' THEN 
					CASE 
						WHEN oldvalues = 1 THEN 'High Importance'
						WHEN oldvalues = 2 THEN 'Middle importance'
						WHEN oldvalues = 3 THEN 'Low importance'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'ImportanceSpeed' THEN
					CASE 
						WHEN oldvalues = 1 THEN 'High Importance'
						WHEN oldvalues = 2 THEN 'Middle importance'
						WHEN oldvalues = 3 THEN 'Low importance'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'IsRegisterSupplierQuoteTheRfq' THEN 
					CASE 
						WHEN oldvalues = 'false' THEN 'No'
						WHEN oldvalues = 'true' THEN 'Yes'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'IsSpecialInstructionToManufacturer' THEN 
					CASE 
						WHEN oldvalues = 'false' THEN 'No'
						WHEN oldvalues = 'true' THEN 'Yes'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'PrefRfqCommunicationMethod' THEN ISNULL(e.value,'')
				WHEN  RFQAttributes = 'PaymentTermId' THEN ISNULL(f.description,'')
				WHEN  RFQAttributes = 'PrefNdaType' THEN 
					CASE 
						WHEN oldvalues= '' THEN ''
						WHEN oldvalues= 0 THEN 'No NDA'
						WHEN oldvalues= 1 THEN '1st-level NDA'
						WHEN oldvalues= 2 THEN '2nd-level NDA'
						ELSE oldvalues
					 END 
				WHEN  RFQAttributes = 'WhoPaysForShipping' THEN 
					CASE 
						WHEN oldvalues = 1 THEN 'Buyer Pay'
						WHEN oldvalues = 13 THEN 'Supplier Pay'
						ELSE oldvalues
					 END
				WHEN  RFQAttributes = 'RfqStatusId' THEN ISNULL(g.description,'')
				--WHEN  RFQAttributes = 'CertificateId' THEN 'Is special certifications by Manufacturer?'
				WHEN  RFQAttributes = 'RfqPrefManufacturingLocationId' THEN ISNULL(h.territory_classification_name,'')
				WHEN  RFQAttributes = 'CertificateId' THEN ISNULL(i.certificate_code,'')
				WHEN  RFQAttributes = 'ShipTo' THEN ISNULL(j.[address],'')
				WHEN  RFQAttributes = 'POStatus' THEN oldvalues
				WHEN  RFQAttributes = 'IsSpecialCertificationsByManufacturer' THEN 
					CASE 
						WHEN oldvalues = 'false' THEN 'No'
						WHEN oldvalues = 'true' THEN 'Yes'
						ELSE oldvalues
					 END
				ELSE oldvalues
			END oldvalue
			, CASE 
				WHEN  RFQAttributes = 'PartId' THEN ''
				WHEN  RFQAttributes = 'IsRfqPartDefault' THEN 
					CASE 
						WHEN newvalues = 'false' THEN 'No'
						WHEN newvalues = 'true' THEN 'Yes'
						ELSE newvalues
					 END		
				WHEN  RFQAttributes = 'ImportancePrice' THEN 
					CASE 
						WHEN newvalues = 1 THEN 'High Importance'
						WHEN newvalues = 2 THEN 'Middle importance'
						WHEN newvalues = 3 THEN 'Low importance'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'ImportanceQuality' THEN 
					CASE 
						WHEN newvalues = 1 THEN 'High Importance'
						WHEN newvalues = 2 THEN 'Middle importance'
						WHEN newvalues = 3 THEN 'Low importance'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'ImportanceSpeed' THEN
					CASE 
						WHEN newvalues = 1 THEN 'High Importance'
						WHEN newvalues = 2 THEN 'Middle importance'
						WHEN newvalues = 3 THEN 'Low importance'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'IsRegisterSupplierQuoteTheRfq' THEN 
					CASE 
						WHEN newvalues = 'false' THEN 'No'
						WHEN newvalues = 'true' THEN 'Yes'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'IsSpecialInstructionToManufacturer' THEN 
					CASE 
						WHEN newvalues = 'false' THEN 'No'
						WHEN newvalues = 'true' THEN 'Yes'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'PrefRfqCommunicationMethod' THEN e1.value
				WHEN  RFQAttributes = 'PaymentTermId' THEN f1.description
				WHEN  RFQAttributes = 'PrefNdaType' THEN 
					CASE 
						WHEN newvalues= 0 THEN 'No NDA'
						WHEN newvalues= 1 THEN '1st-level NDA'
						WHEN newvalues= 2 THEN '2nd-level NDA'
						ELSE newvalues
					 END 
				WHEN  RFQAttributes = 'WhoPaysForShipping' THEN 
					CASE 
						WHEN newvalues = 1 THEN 'Buyer Pay'
						WHEN newvalues = 13 THEN 'Supplier Pay'
						ELSE newvalues
					 END
				WHEN  RFQAttributes = 'RfqStatusId' THEN g1.description
				--WHEN  RFQAttributes = 'CertificateId' THEN 'Is special certifications by Manufacturer?'
				WHEN  RFQAttributes = 'RfqPrefManufacturingLocationId' THEN ISNULL(h1.territory_classification_name,'')
				WHEN  RFQAttributes = 'ShipTo' THEN ISNULL(j1.[address],'')
				WHEN  RFQAttributes = 'POStatus' THEN newvalues
				WHEN  RFQAttributes = 'CertificateId' THEN ISNULL(i1.certificate_code,'')
				WHEN  RFQAttributes = 'IsSpecialCertificationsByManufacturer' THEN 
					CASE 
						WHEN newvalues = 'false' THEN 'No'
						WHEN newvalues = 'true' THEN 'Yes'
						ELSE newvalues
					 END
				ELSE newvalues
			END newvalue
			FROM [tmp_trans].revision_data_history_1 a  (NOLOCK)
			JOIN [tmp_trans].revision_data_history_2 b  (NOLOCK) ON a.data_history_id = b.Id
			LEFT JOIN 
			(
					SELECT 
						rfq_part_id , part_name , part_id,
						CASE 
							WHEN Id = 1 THEN '1st Part Quantity - "' 
							WHEN Id = 2 THEN '2nd Part Quantity - "' 
							WHEN Id = 3 THEN '3rd Part Quantity - "' 
							WHEN Id = 4 THEN '4th Part Quantity - "' 
							WHEN Id = 5 THEN '5th Part Quantity - "' 
						END + part_name + '"' AS part
					FROM
					(
						SELECT a.rfq_id, b.rfq_part_id, c.part_name, c.part_id ,ROW_NUMBER () OVER (PARTITION BY a.rfq_id ORDER BY a.rfq_id , b.rfq_part_id) Id
						FROM mp_rfq			a (NOLOCK)
						JOIN mp_rfq_parts   b (NOLOCK) ON  a.rfq_id = b.rfq_id and b.status_id = 2
						JOIN mp_parts		c (NOLOCK) ON  b.part_id = c.part_id 
					) a
			) d ON a.rfq_part_id = d.rfq_part_id
			LEFT JOIN mp_system_parameters	e (NOLOCK) on CONVERT(NVARCHAR,b.oldvalues) = CONVERT(NVARCHAR,e.id) AND RFQAttributes = 'PrefRfqCommunicationMethod'
			LEFT JOIN mp_mst_paymentterm	f (NOLOCK) on CONVERT(NVARCHAR,b.oldvalues) = CONVERT(NVARCHAR,f.paymentterm_id) AND RFQAttributes = 'PaymentTermId'
			LEFT JOIN mp_mst_rfq_buyerStatus g (NOLOCK) on CONVERT(NVARCHAR,b.oldvalues) = CONVERT(NVARCHAR,CONVERT(INT,g.rfq_buyerstatus_id)) AND RFQAttributes= 'RfqStatusId'
			LEFT JOIN mp_system_parameters	e1 (NOLOCK) on CONVERT(NVARCHAR,b.newvalues) = CONVERT(NVARCHAR,e1.id) AND RFQAttributes = 'PrefRfqCommunicationMethod'
			LEFT JOIN mp_mst_paymentterm	f1 (NOLOCK) on CONVERT(NVARCHAR,b.newvalues) = CONVERT(NVARCHAR,f1.paymentterm_id) AND RFQAttributes = 'PaymentTermId'
			LEFT JOIN mp_mst_rfq_buyerStatus g1 (NOLOCK) on CONVERT(NVARCHAR,b.newvalues) = CONVERT(NVARCHAR,CONVERT(INT,g1.rfq_buyerstatus_id)) AND RFQAttributes= 'RfqStatusId'
			LEFT JOIN mp_mst_territory_classification h (NOLOCK) on b.oldvalues = CONVERT(NVARCHAR,h.territory_classification_id) AND RFQAttributes= 'RfqPrefManufacturingLocationId'
			LEFT JOIN mp_mst_territory_classification h1 (NOLOCK) on b.newvalues = CONVERT(NVARCHAR,h1.territory_classification_id) AND RFQAttributes= 'RfqPrefManufacturingLocationId'
			LEFT JOIN mp_certificates i (NOLOCK) on b.oldvalues = CONVERT(NVARCHAR,i.certificate_id) AND RFQAttributes= 'CertificateId'
			LEFT JOIN mp_certificates i1 (NOLOCK) on b.newvalues = CONVERT(NVARCHAR,i1.certificate_id) AND RFQAttributes= 'CertificateId'
			LEFT JOIN 
			(
				SELECT site_id ,
					ISNULL(css.site_label + ', ',' ') + ISNULL(ma.address1 +', ',' ') + ISNULL(ma.address2 +', ',' ') + ISNULL(ma.address3 +', ',' ') 
					+ ISNULL(ma.address4 +', ',' ') + ISNULL(ma.address5 + ', ',' ')+ISNULL(country_name,' ')  AS address
				FROM mp_company_shipping_site	css (NOLOCK)
				JOIN mp_addresses				ma (NOLOCK)		on css.address_id = ma.address_id
				JOIN mp_mst_country				mms (NOLOCK)	on mms.country_id = ma.country_id
				WHERE site_id <>0
			) j ON b.oldvalues  =  CONVERT(NVARCHAR,j.site_id)    AND RFQAttributes= 'ShipTo'
			LEFT JOIN 
			(
				SELECT site_id ,
					ISNULL(css.site_label + ', ',' ') + ISNULL(ma.address1 +', ',' ') + ISNULL(ma.address2 +', ',' ') + ISNULL(ma.address3 +', ',' ') 
					+ ISNULL(ma.address4 +', ',' ') + ISNULL(ma.address5 + ', ',' ')+ISNULL(country_name,' ')  AS address
				FROM mp_company_shipping_site	css (NOLOCK)
				JOIN mp_addresses				ma (NOLOCK)		on css.address_id = ma.address_id
				JOIN mp_mst_country				mms (NOLOCK)	on mms.country_id = ma.country_id
				WHERE site_id <>0
			) j1 ON b.newvalues  =  CONVERT(NVARCHAR,j1.site_id)   AND RFQAttributes= 'ShipTo'
				--WHERE a.rfq_id = 1189591
		) a

		DELETE [tmp_trans].revision_data_history_3  WHERE (RFQAttributes IN ('PartQty','QuantityLevel'))

		INSERT INTO [tmp_trans].revision_data_history_4(data_history_id,rfq_id , userid)
		SELECT data_history_id ,rfq_id , userid FROM [tmp_trans].revision_data_history_3  (NOLOCK)

		;WITH revision_data_history_2 AS   
		(  
			SELECT rfq_id , userid ,ROW_NUMBER() OVER (PARTITION BY rfq_id , userid ORDER BY rfq_id, userid) AS rn 
			FROM [tmp_trans].revision_data_history_4    (NOLOCK)
		)  
		DELETE FROM revision_data_history_2 WHERE rn >1

		INSERT INTO  [tmp_trans].revision_data_history_5
		(rfq_id ,userid ,rn2)
		SELECT  rfq_id , userid  ,DENSE_RANK() OVER (PARTITION BY rfq_id ORDER BY  rfq_id, row_number1 ) rn2  
		FROM	
		(
			SELECT	*,	ROW_NUMBER() OVER (ORDER BY rfq_id) row_number1	FROM [tmp_trans].revision_data_history_4   (NOLOCK)
		) a
	

		--SELECT * FROM #revision_data_history_3 WHERE rfq_id= 1189595
		--SELECT * FROM [tmp_trans].revision_data_history_5


		INSERT INTO mp_rfq_versions(contact_id,major_number, minor_number, version_number, creation_date, rfq_id)
			OUTPUT INSERTED.rfq_version_id, INSERTED.contact_id, INSERTED.rfq_id , INSERTED.major_number  INTO [tmp_trans].revision_versions  
		SELECT userid contact_id , (rn +rn2 )  major_number ,  0 minor_number , CONVERT(NVARCHAR(50),(rn+rn2 )) + '.0' version_number ,  GETUTCDATE() creation_date , rfq_id
		FROM
		(
			SELECT  
				rfq_id , userid , rn2,  ISNULL((SELECT MAX(major_number) FROM mp_rfq_versions (NOLOCK) WHERE a.rfq_id = rfq_id ),1) rn
			FROM [tmp_trans].revision_data_history_5 a  (NOLOCK)

		) a
		
		INSERT INTO mp_rfq_revision(rfq_id, field	, oldvalue	, newvalue	, creation_date	, rfq_version_id)
		SELECT  
			a.rfq_id	
			,REPLACE(REPLACE(a.field,'"" - Is Default RFQ Part?','Is Default RFQ Part?'),'Part Newly added ""','Part Newly added')	field
			,ISNULL(a.old_value,'')	old_value ,ISNULL(a.new_value,'') new_value ,dh_date ,b.rfq_version_id  
		FROM 
		(
			SELECT DISTINCT a.rfq_id	,field	, ISNULL(oldvalue,'')	old_value ,ISNULL(newvalue,'') new_value ,  creation_date dh_date 
			, b.rn2 version_running_id , a.userid ,a.data_history_id
			FROM [tmp_trans].revision_data_history_3 a  (NOLOCK)
			JOIN [tmp_trans].revision_data_history_5 b  (NOLOCK) ON a.rfq_id = b.rfq_id AND a.userid = b.userid
		) a
		JOIN [tmp_trans].revision_versions b ON a.rfq_id = b.rfq_id AND a.userid = b.contact_id and a.version_running_id = (b.major_number - (b.major_number - a.version_running_id))
		ORDER BY version_running_id ,data_history_id

	END

	TRUNCATE TABLE [tmp_trans].revision_data_history
	TRUNCATE TABLE [tmp_trans].revision_data_history_1
	TRUNCATE TABLE [tmp_trans].revision_data_history_2
	TRUNCATE TABLE [tmp_trans].revision_data_history_3
	TRUNCATE TABLE [tmp_trans].revision_data_history_4
	TRUNCATE TABLE [tmp_trans].revision_data_history_5
	TRUNCATE TABLE [tmp_trans].revision_versions 
	TRUNCATE TABLE [tmp_trans].revision_data_history_old_values
	TRUNCATE TABLE [tmp_trans].revision_data_history_new_values 

END
