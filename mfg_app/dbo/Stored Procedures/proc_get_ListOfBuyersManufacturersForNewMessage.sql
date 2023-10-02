
/*
EXEC [proc_get_ListOfBuyersManufacturersForNewMessage]
@ContactId = 1337795
, @IsBuyer =  0

EXEC [proc_get_ListOfBuyersManufacturersForNewMessage]
@ContactId = 1337795
, @IsBuyer =  1


SELECT DISTINCT 
			MC.contact_id as ContactId
			,CONCAT(MC.first_name,' ',MC.last_name) AS ContactName
		FROM [mp_rfq_quote_SupplierQuote] (NOLOCK) MRQS
		INNER JOIN [mp_rfq] (NOLOCK) MR ON MR.rfq_id = MRQS.rfq_id
		INNER JOIN [mp_contacts] MC ON MC.contact_id = MR.contact_id
		WHERE MRQS.contact_id = 1337795
		AND mrqs.is_quote_submitted = 1 AND MRQS.is_rfq_resubmitted = 0
		AND MC.IsTestAccount = 0
*/
CREATE PROCEDURE [dbo].[proc_get_ListOfBuyersManufacturersForNewMessage]
(
	@ContactId	INT
	, @IsBuyer	BIT
)
AS
BEGIN

	/* 
		M2-4213 API - Buyer - Add select an M to send a message to in the drawer
		M2-4216 DB - M - Add a drop down for Followed Buyer selection in the New message drawer	
		M2-4262 Associate to RFQ to be an optional field in message drawer for both Buyer and M
	*/

	SET NOCOUNT ON

	-- manufacturer list will be made up of the buyer’s Like M’s and M’s who quoted their parts
	IF @IsBuyer = 1
	BEGIN
		SELECT DISTINCT 
			MRQS.contact_id as ContactId
			,CONCAT(MC.first_name,' ',MC.last_name) AS ContactName
		FROM [mp_rfq_quote_SupplierQuote] (NOLOCK) MRQS
		INNER JOIN [mp_rfq] (NOLOCK) MR ON MR.rfq_id = MRQS.rfq_id
		INNER JOIN [mp_contacts] MC ON MC.contact_id = MRQS.contact_id
		WHERE MR.contact_id = @ContactId
		AND mrqs.is_quote_submitted = 1 AND MRQS.is_rfq_resubmitted = 0
		AND MC.IsTestAccount = 0
		UNION
		SELECT 
			c.contact_id	AS ContactId
			,c.ContactName	AS ContactName
		FROM [mp_lead] a (NOLOCK)	
		JOIN 
		(
			SELECT 
				company_id , contact_id ,first_name +' '+last_name AS ContactName
				, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
			FROM [mp_contacts](NOLOCK)
			WHERE IsTestAccount = 0 AND is_buyer = 0
		) c ON c.company_id = a.company_id  AND c.rn=1
		WHERE a.lead_from_contact = @ContactId
		AND a.lead_source_id = '17' AND a.status_id = 1
		/* M2-4262 Associate to RFQ to be an optional field in message drawer for both Buyer and M */
		UNION
		SELECT 
			DISTINCT 
			a.contact_id as ContactId
			,CONCAT(MC.first_name,' ',MC.last_name) AS ContactName
		FROM 
		(
			SELECT to_cont AS contact_id  FROM mp_messages (NOLOCK) WHERE from_cont = @ContactId AND message_type_id IN (5,40,220,225,230)
			UNION
			SELECT from_cont FROM mp_messages (NOLOCK) WHERE to_cont = @ContactId AND message_type_id IN (5,40,220,225,230)
		
		) a
		INNER JOIN [mp_contacts] MC ON MC.contact_id = a.contact_id
		WHERE IsTestAccount = 0 AND MC.company_id <> 0 AND MC.contact_id <> 0
		/**/
	END
	-- list of followed Buyer selection in the New message drawer
	ELSE IF @IsBuyer = 0
	BEGIN

		SELECT DISTINCT 
			c.contact_id	AS ContactId
			,c.ContactName	AS ContactName
		FROM mp_book_details	mbd		(NOLOCK)
		JOIN mp_books			mb		(NOLOCK)	ON mbd.book_id =mb.book_id
		JOIN mp_mst_book_type	mmbt	(NOLOCK)	ON mmbt.book_type_id = mb.bk_type
			AND mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
			AND mb.contact_id = @ContactId
		JOIN 
		(
			SELECT 
				company_id , contact_id ,first_name +' '+last_name AS ContactName
				, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
			FROM [mp_contacts](NOLOCK)
			WHERE IsTestAccount = 0 AND is_buyer = 1
		) c ON c.company_id = mbd.company_id  AND c.rn=1
		/* M2-4262 Associate to RFQ to be an optional field in message drawer for both Buyer and M */
		UNION
		SELECT 
			DISTINCT 
			a.contact_id as ContactId
			,CONCAT(MC.first_name,' ',MC.last_name) AS ContactName
		FROM 
		(
			SELECT to_cont AS contact_id  FROM mp_messages (NOLOCK) WHERE from_cont = @ContactId AND message_type_id IN (5,40,220,225,230)
			UNION
			SELECT from_cont FROM mp_messages (NOLOCK) WHERE to_cont = @ContactId AND message_type_id IN (5,40,220,225,230)
		
		) a
		INNER JOIN [mp_contacts] MC ON MC.contact_id = a.contact_id
		WHERE IsTestAccount = 0 AND MC.company_id <> 0 AND MC.contact_id <> 0
		UNION
		SELECT DISTINCT 
			mc.contact_id as ContactId
			,CONCAT(MC.first_name,' ',MC.last_name) AS ContactName
		FROM [mp_rfq_quote_SupplierQuote] (NOLOCK) MRQS
		INNER JOIN [mp_rfq] (NOLOCK) MR ON MR.rfq_id = MRQS.rfq_id
		INNER JOIN [mp_contacts] MC ON MC.contact_id = MR.contact_id
		WHERE MRQS.contact_id = @ContactId
		AND mrqs.is_quote_submitted = 1 AND MRQS.is_rfq_resubmitted = 0
		AND MC.IsTestAccount = 0
		/**/
	END
END
