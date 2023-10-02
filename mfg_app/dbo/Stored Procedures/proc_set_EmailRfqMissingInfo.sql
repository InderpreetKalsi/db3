



/*

EXEC proc_set_EmailRfqMissingInfo @RfqId = 1160468 , @todays_date = '2022-11-25 13:57:58.767' , @message = 'Have some missing info' 

*/
CREATE PROCEDURE [dbo].[proc_set_EmailRfqMissingInfo]
( 
@RfqId  INT 
, @todays_date AS DATETIME
, @message	VARCHAR(MAX) = NULL
)
AS
BEGIN
	-- M2-4751 RFQ Missing Information Field & Notice
	-- M2-4773

	SET NOCOUNT ON
	
	DECLARE @IsRfqWithMissingInfo BIT
	DECLARE @days INT=0
	DECLARE @rfq_name AS NVARCHAR(500) = ''
	DECLARE @rfq_contact_id AS BIGINT = 0
	DECLARE @from_username AS NVARCHAR(100) = ''
	DECLARE @company_id AS BIGINT
	DECLARE @ToBuyerEmail VARCHAR(250) = ''
	DECLARE @email_msg_body AS NVARCHAR(MAX) = ''
	DECLARE @email_msg_subject AS NVARCHAR(250) = ''
	DECLARE @msg_body AS NVARCHAR(MAX) = ''
	DECLARE @msg_subject AS NVARCHAR(250) = ''
	DECLARE @rfq_guid AS NVARCHAR(500) = ''
	DECLARE @identity_msg BIGINT = 0

	SELECT 
		@rfq_name = rfq_name 
		, @rfq_contact_id = a.contact_id  
		, @from_username = b.first_name + ' ' + b.last_name
		, @company_id = b.company_id
		, @IsRfqWithMissingInfo =  IsRfqWithMissingInfo  
		, @days =   DATEDIFF (DAY,CAST(GETDATE() AS DATE),CAST(Quotes_needed_by AS DATE))
		, @ToBuyerEmail = c.Email
		, @rfq_guid = ISNULL(rfq_guid,'')
	FROM mp_rfq a (NOLOCK) 
	JOIN mp_contacts b  (NOLOCK) ON a.contact_id = b.contact_id
	JOIN AspNetUsers c (NOLOCK) ON  c.Id = b.user_id
	WHERE rfq_id =  @RfqId 


	IF ISNULL(@IsRfqWithMissingInfo,0) = 0
	BEGIN
			SELECT 
			@email_msg_body = email_body_template, @email_msg_subject = email_subject_template
			,  @msg_body = message_body_template, @msg_subject = message_subject_template
			FROM mp_mst_email_template  (NOLOCK) WHERE message_type_id = 241 AND is_active = 1 

			IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @rfq_contact_id AND is_notify_by_email = 1 )   /* M2-4789*/
			BEGIN
				INSERT INTO mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				SELECT 
				@RfqId rfq_id
				, 241  message_type_id 
				,  REPLACE(@msg_subject ,'##RFQNO##', ''+CONVERT(VARCHAR(50),@RfqId)+'') AS message_subject 
				,  REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Buyer_Name#', @from_username) , '##RFQNO##' ,CONVERT(VARCHAR(15),@RfqId)),'##days##',@days), '#RFQNO#', @rfq_guid)  AS message_descr
				, @todays_date AS email_message_date
				, NULL from_contact_id 
				, @rfq_contact_id AS to_contact_id 
				, @ToBuyerEmail AS to_email_id
				, 0 AS message_sent
				, 0 AS message_read
                         END
				
	END
	ELSE  ---- @IsRfqWithMissingInfo = 1
	BEGIN 

		SELECT 
			@email_msg_body = email_body_template, @email_msg_subject = email_subject_template
			,  @msg_body = message_body_template, @msg_subject = message_subject_template
		FROM mp_mst_email_template  (NOLOCK) WHERE message_type_id = 242 AND is_active = 1 

		IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @rfq_contact_id AND is_notify_by_email = 1 )   /* M2-4789*/
		BEGIN
			INSERT INTO mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
			,from_cont ,to_cont, to_email, message_sent,message_read )
			SELECT 
				@RfqId rfq_id
				, 242  message_type_id 
				, REPLACE(@msg_subject ,'##RFQNO##', ''+CONVERT(VARCHAR(50),@RfqId)+'') AS message_subject 
				, REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Buyer_Name#', @from_username) , '##RFQNO##' ,CONVERT(VARCHAR(15),@RfqId)),'##Name##',@rfq_name),'##message##' , ISNULL(@message,'')) AS message_descr
				, @todays_date AS email_message_date
				, NULL from_contact_id 
				, @rfq_contact_id AS to_contact_id 
				, @ToBuyerEmail AS to_email_id
				, 0 AS message_sent
				, 0 AS message_read
                 END

		INSERT INTO mp_messages
		( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
		SELECT 
				@RfqId rfq_id
				, 242  message_type_id 
				, 'RFQ # '+CONVERT(VARCHAR(50),@RfqId)+' - Open for Quoting - Missing Info' 	AS message_subject 
				, 'RFQ # '+CONVERT(VARCHAR(50),@RfqId)+' RFQ Name# '+ @rfq_name +' has been released into the MFG.com marketplace, however, your RFQ is missing some information. Updating it with the requested information can improve your RFQ and experience getting quotes.' 
				+'<br>'
				+ ISNULL(@message,'')	AS message_descr
				, @todays_date as message_date
				, NULL from_contact_id 
				, @rfq_contact_id as to_contact_id 
				, 0 as message_sent
				, 0 as message_read
				, 0 as trash
				, 0 as from_trash
				, 0 as real_from_cont_id
				, 0 as is_last_message
				, 0 as message_status_id_recipient
				, 0 as message_status_id_author
		SET @identity_msg = @@IDENTITY
	END

END

