


/*
 


exec proc_get_SendEmailTemplateDataToSendgrid 
@rfq_id=null
,@message_type=N'BuyerPressedCallOnProfileEmail'
,@message_status_id   = null  
,@from_contact=null
,@to_contacts=null
,@message=null
,@message_link=null
,@MessageFileNames  = null
,@json    = 
	N'
	{
	 
	  "app": "mfg-api"   
	  ,"event_type": "BuyerPressedCallOnProfileEmail"  
	  ,"user_id": null
	  ,"email_address" : "supplier19thsept@yopmail.com"
	  ,"EmailVerifyParam" : null
	  ,"LinkToTheProfile" : "profiletest"
	  ,"LeadStreamDeepLink" : "LeadStreamDeepLink"


	}
	'


 
 
*/
CREATE PROCEDURE [dbo].[proc_get_SendEmailTemplateDataToSendgrid]
(
	@rfq_id				INT = NULL ,
	@message_type		VARCHAR(500)	= NULL ,
	@message_status_id  INT	            = NULL ,
	@from_contact		BIGINT          = NULL , 
	@to_contacts		VARCHAR(max)	= NULL ,
	@message			VARCHAR(max)	= NULL ,
	@message_link		VARCHAR(max)	= NULL , 
	@MessageFileNames   VARCHAR(max)	= NULL ,
	@json               VARCHAR(MAX)	= NULL

)
as

begin 

/*
  "event_type": "VerificationEmail",  
  "event_type": "ApprovedEmail",  
  "event_type": "BuyerPressedCallOnProfileEmail",  


  Buyer : "delatestbuyer18sep@yopmail.com"
  Supplier : supplier19thsept@yopmail.com
	  
*/

--DECLARE @message_type varchar(500)	= 'BuyerViewedYourProfileEmail'  ,
--	@rfq_id				int = null ,
--	@message_status_id  int	= null ,
--	@from_contact		bigint = null , 
--	@to_contacts		varchar(max) = null,
--	@message			varchar(max) = null,
--	@message_link		varchar(max) = null, 
--	@MessageFileNames   varchar(max) = null,
--	@json VARCHAR(MAX)  = 
--	N'
--	{
--	  "app": "mfg-api"   
--	  ,"event_type": "BuyerViewedYourProfileEmail"  
--	  ,"user_id": null
--	  ,"email_address" : "supplier19thsept@yopmail.com" 
--	  ,"EmailVerifyParam" : "EmailVerifyParam"
--	  ,"LinkToTheProfile" : "profiletest"
--	  ,"LeadStreamDeepLink" : "LeadStreamDeepLink"
--	}
--	'

	DECLARE @JSONRequest VARCHAR(MAX) ,@UserId NVARCHAR(500) ,@ResponseJSON VARCHAR(MAX)
	SET @JSONRequest =  REPLACE(@json,CHAR(160),'')  
	--select @JSONRequest
	 
	 
	DROP TABLE IF EXISTS #tmpJsonInputParameters
	
	---Convert JSON into tablular format  
   SELECT * INTO #tmpJsonInputParameters FROM  
   (  
	  SELECT   
		i.app, i.event_type, i.[user_id],  i.[email_address]  , i.[EmailVerifyParam]  ,i.[LinkToTheProfile] , i.[FirstName],i.[LeadStreamDeepLink]
	   FROM OPENJSON(@JSONRequest)   
	   WITH   
	   (  
		  app NVARCHAR(15) '$.app'  
		  ,event_type NVARCHAR(200) '$.event_type'  
		  ,user_id VARCHAR(100) '$.user_id' 
		  ,email_address NVARCHAR(200) '$.email_address'
		  ,EmailVerifyParam NVARCHAR(MAX)  '$.EmailVerifyParam'  --- VerificationEmail
		  ,LinkToTheProfile NVARCHAR(MAX)  '$.LinkToTheProfile'  --- ApprovedEmail
		  ,FirstName NVARCHAR(200)  '$.FirstName'                --- ApprovedEmail
		  ,LeadStreamDeepLink  NVARCHAR(200)  '$.LeadStreamDeepLink'                --- BuyerPressedCallOnProfileEmail
	   ) AS i
	 ) tmpJsonInputParameters  

	 /* Common code for instant sync email */
	 BEGIN
	 --update temp table
			UPDATE c 
			set c.[user_id] = b.contact_id
			,c.FirstName =  b.first_name + ' ' + b.last_name
			FROM aspnetusers (NOLOCK) a
			JOIN mp_contacts (NOLOCK) b ON b.user_id = a.id
			JOIN #tmpJsonInputParameters c on  c.email_address = a.email 
	 END

	 --select * from #tmpJsonInputParameters
	
	 

	set nocount on
	declare @processStatus as varchar(max) = 'SUCCESS'
	declare @rfq_contact_id as bigint = 0
	declare @rfq_name as nvarchar(500) = ''
	declare @rfq_guid as nvarchar(500) = ''
	declare @email_msg_subject as nvarchar(250) = ''
	declare @email_msg_body as nvarchar(max) = ''
	declare @msg_subject as nvarchar(250) = ''
	declare @msg_body as nvarchar(max) = ''
	declare @todays_date as datetime = getdate() 
	declare @from_username as nvarchar(100) = ''
	declare @from_user_contactimage as nvarchar(500) = ''
	declare @from_user_email varchar(200) = ''
	declare @to_userid as int = 0
	declare @to_username as nvarchar(100) = ''
	declare @to_user_contactimage as nvarchar(500) = ''
	declare @to_user_email varchar(200) = ''
	declare @identity bigint = 0
	declare @identity_msg bigint = 0
	declare @company_id as bigint
	declare @company as nvarchar(200) = ''
	declare @supplier_company as nvarchar(200) = ''
	declare @total_parts int = 0
	declare @max_quantity bigint = 0
	declare @is_buyer bit = 0
	declare @quote_end_date date 
	declare @to_contacts1 varchar(max) = ''
	declare @notification_email_running_id  table (id int identity(1,1) ,  email_message_id int null)
	declare @notification_message_running_id  table (id int identity(1,1) ,  message_id int null)
	declare @is_2ndLevel_NDA int = 0 
	declare @to_contacts_for_non_awarded_supplier  varchar(max) = ''
	declare @quote_needed_by varchar(50) = '' 
	declare @part_name varchar(max) = ''
	DECLARE @ToSupplier VARCHAR(150) 
	DECLARE @ToSupplierEmail VARCHAR(150) 
	----M2-4773
	DECLARE @IsRfqWithMissingInfo BIT
	DECLARE @MId1 INT = 0 
	DECLARE @ToBuyer VARCHAR(250) = 0
	DECLARE @ToBuyerEmail VARCHAR(250) = ''
		
	/* M-4876 */
	DECLARE @poMfgUniqueId      INT
	DECLARE @poTransactionId    VARCHAR(255)
	/**/
	/* M2-4831 */
	DECLARE @PONumber			VARCHAR(100) 
	DECLARE @quoted_quantity_id VARCHAR(MAX) = @message  
	DECLARE @RfqEncryptedId     VARCHAR(100) 
	DECLARE @RetractedReason    VARCHAR(MAX) = @message
	DECLARE @CancelledReason    VARCHAR(MAX) = @message  
	DECLARE @ReshapeUniqueId    UNIQUEIDENTIFIER
        /**/
	declare @message_type_id bigint = (select  message_type_id from mp_mst_message_types where message_type_name = replace(@message_type,'9999',''))
	declare @messagestatus varchar(500) = (select message_status_token from mp_mst_message_status where message_type_id = @message_type_id and message_status_id = @message_status_id)
	
	/* M-4948 */
	DECLARE @InvNumber VARCHAR (100)= NULL,@InvAmount VARCHAR (100)=NULL, @InvDueDate VARCHAR(50) =NULL,@messageJson VARCHAR(MAX) ,@ViewInvoice VARCHAR(MAX),@StripeLink VARCHAR(MAX)
	
	IF @message_type = 'BUYER_EMAIL_NOTIFICATION_RECEIVED_ON_NEW_INVOICE'
	BEGIN
		 SET @messageJson =  REPLACE(@message,CHAR(160),'')

		SELECT @InvNumber= ISNULL(i.InvoiceNumber,''), @InvAmount= ISNULL(i.[Amount],00.00)
		      ,@InvDueDate = ISNULL(CONVERT(VARCHAR(100), CAST(i.[DueDate] AS DATE), 107)	,'') , @ViewInvoice= ISNULL(ViewInvoice,'')
			  ,@StripeLink = ISNULL(StripeLink,'')
		FROM OPENJSON(@messageJson) WITH (
  			InvoiceNumber VARCHAR(50) '$.InvoiceNumber',
  			Amount VARCHAR (100) '$.Amount',
  			DueDate DATE '$.DueDate' ,   
            ViewInvoice VARCHAR(MAX) '$.ViewInvoice',
			StripeLink VARCHAR(MAX) '$.StripeLink'
		) AS i
	END

	drop table if exists #list_of_admin_contacts_as_per_companies_for_email
	drop table if exists #companies_for_rfq
	drop table if exists #list_of_to_contacts_for_messages_notification
	drop table if exists #tmp_notification
	drop table if exists #tmp_part_awarded
	drop table if exists #list_of_to_contacts_for_messages_notification1
	drop table if exists #list_of_to_contacts_for_messages_notification_freemsg
	drop table if exists #MessageFileTable 
	drop table if exists #SpecialFileIdTable
	drop table if exists #RfqPreferredLocations
	drop table if exists #RfqPartCapabilities
	drop table if exists #SupplierManufacturingLocation
	drop table if exists #SupplierWithMatchingCapabilitiesAndManufacturingLocation
	
	create table #tmp_notification (id int null , email_message_id varchar(50), message_id  varchar(50))
	create table #list_of_admin_contacts_as_per_companies_for_email (company_id int null, contact_id  int null, email_id varchar(50) null , username varchar(50) null, is_notify_by_email  BIT NULL) /* M2-4789 - added is_notify_by_email*/
	create table #companies_for_rfq (company_id int , type varchar(150) )
	begin try
	/* fetching contact , company info using rfq or using from or to contact id*/

		if @message_link is null or @message_link = ''
			set @message_link = ''


	    SELECT @rfq_guid = ISNULL(rfq_guid,'') FROM mp_rfq WHERE rfq_id = @rfq_id

		--SELECT  @rfq_guid = CASE WHEN b.rfqid IS NOT NULL THEN  convert(varchar(50),b.RfqEncryptedId ) ELSE convert(varchar(50), a.rfq_guid) END  
		--FROM mp_rfq (NOLOCK) a 
		--LEFT JOIN mpordermanagement(nolock) b on a.rfq_id = b.rfqid
		--WHERE rfq_id =  @rfq_id


		if @message_type in ( 'RFQ_RELEASED_BY_ENGINEERING' , 'RFQ_EDITED_RESUBMIT_QUOTE','BUYER_SELECTS_RESUBMIT_QUOTE')
		begin
			
			-- getting rfq name , rfq contact id , username & contact image 
			select 
				@rfq_name = rfq_name 
				, @rfq_contact_id = a.contact_id  
				, @from_username = b.first_name + ' ' + b.last_name
				, @from_user_contactimage = c.file_name
				, @quote_end_date = cast(Quotes_needed_by as date)
				, @company_id = b.company_id
				---- M2-4773
				, @IsRfqWithMissingInfo =  IsRfqWithMissingInfo  
			from mp_rfq a (nolock) 
			left join mp_contacts b  (nolock) on a.contact_id = b.contact_id
			left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
			where rfq_id =  @rfq_id 

			select @company = name from mp_companies  (nolock) where company_id = @company_id

			select rfq_pref_manufacturing_location_id into #RfqPreferredLocations 
			from mp_rfq_preferences (nolock) where rfq_id = @rfq_id

			select part_category_id into #RfqPartCapabilities 
			from mp_rfq_parts (nolock) where rfq_id = @rfq_id

			select @total_parts = count(rfq_id) from mp_rfq_parts  (nolock) where rfq_id = @rfq_id 
			set @max_quantity = isnull((select top 1  max(part_qty) part_qty  from mp_rfq_parts  (nolock) a join mp_rfq_part_quantity b  (nolock) on a.rfq_part_id = b.rfq_part_id where rfq_id = @rfq_id group by b.rfq_part_id
			order by part_qty desc ) , 0)

			
			-- individual or group of companies for rfq 
			if (select count(1) from mp_rfq_supplier  (nolock) where  rfq_id = @rfq_id  and company_id <> -1 ) > 0
			begin

				insert into #companies_for_rfq (company_id , type)
				select distinct company_id , 'individual' as type 
				from mp_rfq_supplier (nolock)
				where supplier_group_id is null and   rfq_id = @rfq_id 

			end	
			/*  M2-3249 M - Send M a Notification and Email when an RFQ is released from a followed buyer -DB */
			else 
			begin

				insert into #companies_for_rfq (company_id , type)
				select distinct c.company_id , 'followed_suppliers' as type 
				from mp_book_details (nolock) a
				join mp_books (nolock) b on a.book_id = b.book_id and bk_name = 'Buyer Hotlist'
				join mp_contacts (nolock) c on b.contact_id = c.contact_id
				where a.company_id = @company_id AND c.company_id <> -1

				select company_id into #SupplierManufacturingLocation 
				from mp_companies (nolock)
				where company_id in (select company_id from #companies_for_rfq)
				and Manufacturing_location_id in (select * from #RfqPreferredLocations)

			
				select company_id  into #SupplierWithMatchingCapabilitiesAndManufacturingLocation 
				/* Oct 27, 2021 , As discussed with Eddie - For M2-3249 , delaPlex team need to change logic to look for RFQ quoting capabilities, not profile capabilities */
				from mp_gateway_subscription_company_processes (nolock)
				--from mp_company_processes (nolock)
				/**/
				where company_id in (select * from #SupplierManufacturingLocation)
				and part_category_id in (select * from #RfqPartCapabilities)

			
				delete from #companies_for_rfq  
				where not exists (select * from #SupplierWithMatchingCapabilitiesAndManufacturingLocation b where company_id = b.company_id)

			end
			/**/
			 
			if  @message_type in ( 'RFQ_EDITED_RESUBMIT_QUOTE' ) and ((select count(1) from mp_rfq_supplier  (nolock) where  rfq_id = @rfq_id  and company_id = -1 ) > 0)
			begin

				insert into #companies_for_rfq (company_id , type)
				select distinct c.company_id , 'allregistered' as type 
				from mp_rfq (nolock) a
				join mp_rfq_quote_suplierstatuses (nolock) b on a.rfq_id=b.rfq_id
				join mp_contacts (nolock) c on b.contact_id =c.contact_id
				where a.rfq_id = @rfq_id 
				
			end
					
            delete from #companies_for_rfq 
            where company_id in 
            (
                select distinct a.company_id from mp_book_details  a  (nolock) 
                join mp_books b  (nolock) on a.book_id = b.book_id 
                where bk_type= 5 and b.contact_id  = @rfq_contact_id 
            )

			if exists (select * from #companies_for_rfq where company_id = -1) -- for all registered manufacturer
			begin
				
				insert into #list_of_admin_contacts_as_per_companies_for_email (company_id , contact_id , email_id  , username,is_notify_by_email)
				select distinct a.company_id, a.contact_id ,   b.email as email_id , a.first_name + ' ' + a.last_name as username
				,a.is_notify_by_email  /* M2-4789*/
				from mp_contacts a (nolock) 
				left join aspnetusers b (nolock)  on a.user_id = b.id
				where a.company_id in (select company_id from #companies_for_rfq where company_id <> -1 ) and is_admin = 1 and is_buyer = 0 and is_active = 1
				union
				select distinct a.company_id, a.contact_id ,   b.email as email_id , a.first_name + ' ' + a.last_name as username
				,a.is_notify_by_email  /* M2-4789*/
				from mp_contacts a (nolock) 
				left join aspnetusers b  (nolock) on a.user_id = b.id
				where a.company_id in (select company_id from mp_registered_supplier where is_registered = 1 ) and is_admin = 1 and is_buyer = 0 and is_active = 1

			end
			else
			begin
				
				insert into #list_of_admin_contacts_as_per_companies_for_email (company_id , contact_id , email_id  , username, is_notify_by_email)
				select a.company_id, a.contact_id ,   b.email as email_id , a.first_name + ' ' + a.last_name as username
				,a.is_notify_by_email  /* M2-4789*/
				from mp_contacts a (nolock) 
				left join aspnetusers b  (nolock) on a.user_id = b.id
				where a.company_id in (select company_id from #companies_for_rfq) and is_admin = 1 and is_buyer = 0 and is_active = 1
			end


		end
		else if @message_type in ( 'RFQ_MARKED_INCOMPLETE')
		begin

			-- getting rfq name , rfq contact id , username & contact image 
			select 
				@rfq_name = rfq_name 
				, @to_userid = a.contact_id  
				, @to_username = b.first_name + ' ' + b.last_name
				, @to_user_contactimage = c.file_name
				, @to_user_email =  d.email
			from mp_rfq a (nolock) 
			left join mp_contacts b  (nolock) on a.contact_id = b.contact_id
			left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
			left join aspnetusers d  (nolock) on b.user_id = d.id
			where rfq_id =  @rfq_id 

			-- getting to contacts information
			select 
				 @from_username = a.first_name + ' ' + a.last_name
				, @from_user_contactimage = c.file_name
				, @from_user_email =  b.email			
			from mp_contacts a (nolock) 
			left join aspnetusers b  (nolock) on a.user_id = b.id
			left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
			where a.contact_id = @from_contact

			
		end
		else if @message_type in ( 'rfqFreeMessage')
		begin
			-- getting rfq name , rfq contact id , username & contact image 
			select 
				@company_id = b.company_id
				, @rfq_contact_id = b.contact_id  
				, @from_username = b.first_name + ' ' + b.last_name
				, @from_user_contactimage = c.file_name
				, @from_user_email = d.email
				, @company_id = b.company_id
				--, @is_buyer = b.is_buyer
			from mp_contacts b  (nolock) 
			left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
			left join aspnetusers d  (nolock) on b.user_id = d.id
			where b.contact_id =  @from_contact

			-- getting company name
			select @company = name from mp_companies  (nolock) where company_id = @company_id
				
			-- getting to contacts information
			select a.company_id, a.contact_id ,   b.email as  email_id, a.first_name + ' ' + a.last_name as username, row_number() over(order by a.contact_id) as rn
			,a.is_notify_by_email  /* M2-4789*/
			into #list_of_to_contacts_for_messages_notification_freemsg
			from mp_contacts a (nolock) 
			left join aspnetusers b  (nolock) on a.user_id = b.id
			where a.contact_id in (select value from string_split(@to_contacts, ','))
			
			select @supplier_company = name from mp_companies 	 (nolock) where company_id = @company_id

			-- is buye or supplier
			set @is_buyer = (select is_buyer from mp_contacts   (nolock) where contact_id = @from_contact)
			
		end
		else
		begin

			if @from_contact is null or @from_contact = ''
			begin
				
				set @from_contact = (select contact_id 	from mp_rfq (nolock)  where rfq_id =  @rfq_id )

			end

			if @message_type in ('rfqNonConfirmationMessage','QUOTE_RETRACTED_BY_BUYER')
				set @from_contact = (select contact_id 	from mp_rfq (nolock)  where rfq_id =  @rfq_id )


			if  @message_type in ( 'RFQ_LIKED_BY_SUPPLIER','RFQ_DISLIKED_BY_SUPPLIER','rfqResponse','MESSAGE_TYPE_CONFIDENTIALITY_AGREEMENT','RFQ_MARKED_FOR_QUOTING', 'SUPPLIER_SUBMIT_QUOTE')
			begin
				set @to_contacts = (select contact_id from mp_rfq  (nolock) where rfq_id = @rfq_id )
				set @is_2ndLevel_NDA = (select pref_NDA_Type from mp_rfq  (nolock) where rfq_id = @rfq_id)
			end
			else if  @message_type in ('rfqConfirmationMessage','AWARDED_OFFLINE_MANUFACTURER','RFQ_NOT_AWARDED')
			begin
				
				select @rfq_name = rfq_name  from mp_rfq a	where rfq_id =  @rfq_id 

			end
			else if @message_type in ('BUYER_FOLLOW_SUPPLIER')
			begin
				
				select @to_contacts1 = coalesce(@to_contacts1+',' ,'') + convert(varchar(20),contact_id)
				from mp_contacts a  (nolock) where company_id =  @to_contacts and is_buyer = 0
				
				set @to_contacts = substring(@to_contacts1,2,len(@to_contacts1))
				
			end
			else if  @message_type = ('RFQ_AWARDED_TO_OTH_SUPPLIER')
			begin 
				
				select @rfq_name = rfq_name , @quote_needed_by = convert(varchar(10),Quotes_needed_by,120) from mp_rfq a	where rfq_id =  @rfq_id 
				
					select  @to_contacts =  coalesce(@to_contacts+',' ,'') + convert(varchar(20),a.contact_id)  from 
					(
						select distinct b.contact_id
						from mp_rfq a (nolock) 
						join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_id = b.rfq_id  and  is_rfq_resubmitted = 0
						join mp_rfq_quote_items c (nolock)  on b.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
						where a.rfq_id = @rfq_id 
						and is_quote_submitted = 1
						and 
						 b.contact_id not in 
						 (
							select distinct b.contact_id from mp_rfq a (nolock) 
							join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_id = b.rfq_id  and  is_rfq_resubmitted = 0
							join mp_rfq_quote_items c (nolock)  on b.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
							where a.rfq_id = @rfq_id and (is_awrded =1) 
					 
						 )
						 ) a
				
			end
			
			-- getting rfq name , rfq contact id , username & contact image 
			select 
				@rfq_contact_id = b.contact_id  
				, @from_username = b.first_name + ' ' + b.last_name
				, @from_user_contactimage = c.file_name
				, @from_user_email = d.email
				, @company_id = b.company_id
			from mp_contacts b  (nolock) 
			left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
			left join aspnetusers d  (nolock) on b.user_id = d.id
			where b.contact_id =  @from_contact

			-- getting to contacts information
			
			select distinct a.company_id, a.contact_id ,   b.email as  email_id, a.first_name + ' ' + a.last_name as username
			/* M2-4789*/
			,a.is_notify_by_email
			/* M2-4789*/
			into #list_of_to_contacts_for_messages_notification
			from mp_contacts a (nolock) 
			left join aspnetusers b  (nolock) on a.user_id = b.id
			where a.contact_id in (select value from string_split(@to_contacts, ','))

			
			-- getting company name
			select @company = name from mp_companies  (nolock) where company_id = @company_id
			select @supplier_company = name from mp_companies 	 (nolock) where company_id in  (select distinct company_id from #list_of_to_contacts_for_messages_notification)


			-- is buye or supplier
			set @is_buyer = (select is_buyer from mp_contacts  where contact_id = @from_contact)
		end 
	/**/
	
	
	/* getting email/message subject & body */
	if  @message_type in ( 'RFQ_RELEASED_BY_ENGINEERING')  -- for all registered manufacturer
	begin
		if exists (select * from #companies_for_rfq where company_id <> -1 and   type = 'individual'  ) 
		begin

			set @message_type = 'RFQ_BUYER_INVITATION'
						
			select 
				@email_msg_body = email_body_template, @email_msg_subject = email_subject_template
				,  @msg_body = message_body_template, @msg_subject = message_subject_template
			from mp_mst_email_template  (nolock) where message_type_id = 207 and is_active = 1 
			and isnull(message_status_id,0) = (case when @message_status_id is null  then isnull(message_status_id,0) else @message_status_id end)
		end
		/*  M2-3249 M - Send M a Notification and Email when an RFQ is released from a followed buyer -DB */
		else
		begin

			set @message_type = 'RFQ_RELEASE_NOTIFICATION_FROM_FOLLOWED_BUYER'
						
			select 
				@email_msg_body = email_body_template, @email_msg_subject = email_subject_template
				,  @msg_body = message_body_template, @msg_subject = message_subject_template
			from mp_mst_email_template  (nolock) where message_type_id = 240 and is_active = 1 
						
		end
		/**/
		select	* into #list_of_to_contacts_for_messages_notification1 from #list_of_admin_contacts_as_per_companies_for_email
		
	end
	else 
	begin
		
		 select 
				@email_msg_body = email_body_template
				, @email_msg_subject = email_subject_template
				, @msg_body = message_body_template
				, @msg_subject = message_subject_template
		from mp_mst_email_template  (nolock) where message_type_id = @message_type_id and is_active = 1 
		and isnull(message_status_id,0) = (case when @message_status_id is null  then isnull(message_status_id,0) else @message_status_id end) 
					
							
	end


	/**/

	/* inserting & fetching notification subject & message based on passed message type */
				
		if @message_type = 'RFQ_RELEASED_BY_ENGINEERING'   -- 146
		begin
				set @processStatus = 'SUCCESS'
				select 
					@processStatus processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type

				
		end
		else if @message_type = 'BUYER_APPROVES_2ND_LEVEL_NDA'   
		begin
		
		
				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				output inserted.message_id into @notification_message_running_id
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') as   message_subject 
						, replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'')   as message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification
				set @identity_msg = @@identity

				insert into mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				output inserted.email_message_id into @notification_email_running_id
				select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					,  replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') message_subject 
					,  replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#',@message_link), '#RFQNo#',@rfq_guid)  as message_descr
					, @todays_date as email_message_date
					, @from_contact from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
				from #list_of_to_contacts_for_messages_notification
				WHERE is_notify_by_email = 1  /* M2-4789*/
				
				set @identity = @@identity
				
				if @identity> 0 
				begin
					set @processStatus = 'SUCCESS'

					insert into #tmp_notification (id, message_id)
					select * from @notification_message_running_id

					update a set a.email_message_id = b.email_message_id
					from #tmp_notification a
					join @notification_email_running_id b on a.id = b.id
						

					select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
							,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
							,to_email_id		,message_sent 		,message_type
					from 
					(
						select
							row_number() over (order by @from_contact )  id
							, @processStatus processStatus 
							, @identity email_message_id 
							, @identity_msg message_id
							, @rfq_id rfq_id
							, @message_type_id message_type_id
							, replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') as   message_subject 
							, replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'')   as message_body
							, replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') email_message_subject 
							, replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#',@message_link)  as email_msg_body
							, @todays_date email_message_date
							, @from_contact rfq_contact_id
							, @from_username as from_username
							, @from_user_contactimage from_user_contactimage
							, contact_id as to_contact_id
							, username as to_username
							, email_id as to_email_id
							, 0 as message_sent
							, @message_type message_type
						from #list_of_to_contacts_for_messages_notification
					)
						a
					join #tmp_notification b on a.id = b.id
		
				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
				end

			
		end
		else if @message_type = 'BUYER_DECLINED_2ND_LEVEL_NDA'   
		begin

		
				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				output inserted.message_id into @notification_message_running_id
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') as   message_subject 
						, replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'')   as message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification
				set @identity_msg = @@identity

				insert into mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				output inserted.email_message_id into @notification_email_running_id
				select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					,  replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') message_subject 
					,  replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#',@message_link), '#RFQNo#', @rfq_guid)  as message_descr
					, @todays_date as email_message_date
					, @from_contact from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
				from #list_of_to_contacts_for_messages_notification
				WHERE is_notify_by_email = 1  /* M2-4789*/
				

				set @identity = @@identity
				
				if @identity> 0 
				begin
					set @processStatus = 'SUCCESS'

					insert into #tmp_notification (id, message_id)
					select * from @notification_message_running_id

					update a set a.email_message_id = b.email_message_id
					from #tmp_notification a
					join @notification_email_running_id b on a.id = b.id
						

					select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
							,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
							,to_email_id		,message_sent 		,message_type
					from 
					(
						select
							row_number() over (order by @from_contact )  id
							, @processStatus processStatus 
							, @identity email_message_id , @identity_msg message_id
							, @rfq_id rfq_id
							, @message_type_id message_type_id
							, replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') as   message_subject 
							, replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'')   as message_body
							, replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+'') email_message_subject 
							, replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#',@message_link)  as email_msg_body
							, @todays_date email_message_date
							, @from_contact rfq_contact_id
							, @from_username as from_username
							, @from_user_contactimage from_user_contactimage
							, contact_id as to_contact_id
							, username as to_username
							, email_id as to_email_id
							, 0 as message_sent
							, @message_type message_type
						from #list_of_to_contacts_for_messages_notification
					)
						a
					join #tmp_notification b on a.id = b.id
		
				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
				end

			
		end
		else if @message_type = 'RFQ_MARKED_INCOMPLETE'   
		begin

				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				output inserted.message_id into @notification_message_running_id
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name) as   message_subject 
						, replace(replace(replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name),'##message##' , @message)   as message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, @to_userid as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				
				set @identity_msg = @@identity

				IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @to_userid AND is_notify_by_email = 1 )   /* M2-4789*/
		        BEGIN
				insert into mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				output inserted.email_message_id into @notification_email_running_id
				select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name) as   message_subject 
					, replace(replace(replace(replace(replace(replace(@email_msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name),'##message##' , @message) ,'##Engineer_name##',@from_username),'#Buyer_Name#',@to_username), '#RFQNO#', @rfq_guid)  as message_descr
					, @todays_date as email_message_date
					, @from_contact from_contact_id 
					, @to_userid as to_contact_id 
					, @to_user_email as to_email_id
					, 0 as message_sent
					, 0 as message_read
				
					set @identity = @@identity
				END
				
				if @identity> 0 OR @identity_msg > 0
				begin
					set @processStatus = 'SUCCESS'

					insert into #tmp_notification (id, message_id)
					select * from @notification_message_running_id

					update a set a.email_message_id = b.email_message_id
					from #tmp_notification a
					join @notification_email_running_id b on a.id = b.id
						

					select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
							,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
							,to_email_id		,message_sent 		,message_type
					from 
					(
						select
							row_number() over (order by @from_contact )  id
							, @processStatus processStatus 
							, @identity email_message_id , @identity_msg message_id
							, @rfq_id rfq_id
							, @message_type_id message_type_id
							, replace(replace(@msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name)   message_subject 
							, replace(replace(replace(@msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name),'##message##' , @message)  as message_body
							, replace(replace(@email_msg_subject,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name)  email_message_subject 
							, replace(replace(replace(replace(replace(@email_msg_body,'##RFQNO##', ''+convert(varchar(50),@rfq_id)+''),'##Name##', @rfq_name),'##message##' , @message) ,'##Engineer_name##',@from_username),'#Buyer_Name#',@to_username)   as email_msg_body
							, @todays_date email_message_date
							, @from_contact rfq_contact_id
							, @from_username as from_username
							, @from_user_contactimage from_user_contactimage
							, @to_userid as to_contact_id
							, @to_username as to_username
							, @to_user_email as to_email_id
							, 0 as message_sent
							, @message_type message_type
						
					)
						a
					join #tmp_notification b on a.id = b.id
		

				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
				end

			
		end
		else if  @message_type = 'RFQ_EDITED_RESUBMIT_QUOTE'   -- 153
		begin

				-- getting suppliers for RFQ
				if exists (select * from #companies_for_rfq)
				begin
				
					insert into mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					output inserted.message_id into @notification_message_running_id
					select 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))   message_subject 
							, replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_descr
							, @todays_date as message_date
							, @rfq_contact_id from_contact_id 
							, l.contact_id as to_contact_id 
							, 0 as message_sent
							, 0 as message_read
							, 0 as trash
							, 0 as from_trash
							, 0 as real_from_cont_id
							, 0 as is_last_message
							, 0 as message_status_id_recipient
							, 0 as message_status_id_author
					----changed on date 06/03/2019
					from #list_of_admin_contacts_as_per_companies_for_email L 
					INNER JOIN mp_rfq_quote_suplierstatuses Q ON(L.contact_id = Q.contact_id AND Q.rfq_id = @rfq_id)
					set @identity_msg = @@identity
				
					
					insert into mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					output inserted.email_message_id into @notification_email_running_id
					select 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
							,  replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#', @message_link), '#RFQNO#', @rfq_guid)
							, @todays_date as email_message_date
							, @rfq_contact_id from_contact_id 
							, l.contact_id as to_contact_id 
							, email_id as to_email_id
							, 0 as message_sent
							, 0 as message_read
					--changed on date 06/03/2019
                                        from #list_of_admin_contacts_as_per_companies_for_email L 
					INNER JOIN mp_rfq_quote_suplierstatuses Q ON(L.contact_id = Q.contact_id AND Q.rfq_id = @rfq_id)
					WHERE L.is_notify_by_email = 1  /* M2-4789*/
					
					set @identity = @@identity
				
					if @identity> 0 or @identity_msg > 0
					begin
						set @processStatus = 'SUCCESS'
						
						insert into #tmp_notification (id, message_id)
						select * from @notification_message_running_id

						update a set a.email_message_id = b.email_message_id
						from #tmp_notification a
						join @notification_email_running_id b on a.id = b.id
						

						select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
								,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
								,to_email_id		,message_sent 		,message_type
						from 
						(
							select
								row_number() over (order by b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id , @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_subject
								, replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_body
								, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))  email_message_subject
								, replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)),'#Message_Link#', @message_link) email_msg_body
								, @todays_date email_message_date
								, @rfq_contact_id rfq_contact_id
								, @from_username as from_username
								, @from_user_contactimage from_user_contactimage
								, b.contact_id as to_contact_id
								, b.username as to_username
								, b.email_id as to_email_id
								, 0 as message_sent
								, @message_type message_type
							from #list_of_admin_contacts_as_per_companies_for_email b INNER JOIN mp_rfq_quote_suplierstatuses Q ON(b.contact_id = Q.contact_id AND Q.rfq_id = @rfq_id)
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
					
				end
			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
			end


		end
		else if  @message_type = 'MESSAGE_TYPE_CONFIDENTIALITY_AGREEMENT'  and   @messagestatus = 'ACCEPTED'  -- 42 
		begin
			
			if @is_2ndLevel_NDA = 2
			begin
				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(replace(@msg_subject, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))   message_subject 
						, replace(replace(@msg_body, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_descr
						, @todays_date as message_date
						, @rfq_contact_id from_contact_id 
						, contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification
				set @identity = @@identity
				
				if @identity> 0 
				begin
					set @processStatus = 'SUCCESS'
				
					select  
						@processStatus processStatus 
						, '' email_message_id , message_id message_id
						, rfq_id
						, message_type_id
						, message_subject as message_subject
						, message_descr as message_body
						, '' email_message_subject
						, '' email_msg_body
						, message_date as email_message_date
						, @rfq_contact_id rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, b.contact_id as to_contact_id
						, b.username as to_username
						, b.email_id as to_email_id
						, 0 as message_sent
						, @message_type message_type
					from mp_messages a
					left join #list_of_to_contacts_for_messages_notification b on a.to_cont = b.contact_id
					where rfq_id = @rfq_id and message_type_id = @message_type_id and message_date = @todays_date

				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
					
				end
		 end
		 else
		 begin

			set @processStatus = 'FAILUER'

					select 
						'FAILUER: No 2nd level NDA'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type

		 end
			
		end
		else if  @message_type = 'BUYER_FOLLOW_SUPPLIER' -- 155
		begin
			
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					null rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@msg_subject, '#Company_Name#', @company), '#Buyer_Name#' , @from_username)   message_subject 
					, replace(replace(@msg_body, '#Company_Name#', @company), '#Buyer_Name#' , @from_username)  as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity = @@identity
				
			if @identity> 0 
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, '' email_message_id , message_id message_id
					, rfq_id
					, message_type_id
					, message_subject as message_subject
					, message_descr as message_body
					, '' email_message_subject
					, '' email_msg_body
					, message_date as email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from mp_messages a
				left join #list_of_to_contacts_for_messages_notification b on a.to_cont = b.contact_id
				where from_cont = @rfq_contact_id  and message_type_id = @message_type_id and message_date = @todays_date

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
				
		end
		else if  @message_type = 'RFQ_MARKED_FOR_QUOTING' -- 155
		begin
			
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@msg_subject, '#Manufacturer_company_name#', @company), '##RFQNO##' , ''+convert(varchar(50),@rfq_id)+'')   message_subject 
					, replace(replace(@msg_body, '#Manufacturer_company_name#', @company), '##RFQNO##' , ''+convert(varchar(50),@rfq_id)+'')   as message_descr
					, @todays_date as message_date
					, @from_contact from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity = @@identity
				
			if @identity> 0 
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, '' email_message_id , message_id message_id
					, rfq_id
					, message_type_id
					, message_subject as message_subject
					, message_descr as message_body
					, '' email_message_subject
					, '' email_msg_body
					, message_date as email_message_date
					,  @from_contact as  rfq_contact_id
					,  @from_username as from_username
					, '' from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from mp_messages a
				left join #list_of_to_contacts_for_messages_notification b on a.to_cont = b.contact_id
				where rfq_id = @rfq_id and  from_cont = @from_contact  and message_type_id = @message_type_id and message_date = @todays_date

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
				
		end
		else if  @message_type = 'BUYER_VIEW_SUPPLIER_PROFILE' -- 150
		begin
			
			if exists (select * from mp_ViewedProfile where contactid = @from_contact and convert(date,profile_viewed_date) =  convert(date,@todays_date) )
				update mp_ViewedProfile set profile_viewed_date = @todays_date where contactid = @from_contact and convert(date,profile_viewed_date) =  convert(date,@todays_date) 
			else 
				insert into mp_ViewedProfile (ContactId,profile_viewed_date,contact_id_profile) select @from_contact , @todays_date , @to_contacts


			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					null rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@msg_subject, '#Company_Name#', @company), '#Buyer_Name#' , @from_username)   message_subject 
					, replace(replace(@msg_body, '#Company_Name#', @company), '#Buyer_Name#' , @from_username)  as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity = @@identity
				
			if @identity> 0 
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, '' email_message_id , message_id message_id
					, rfq_id
					, message_type_id
					, message_subject as message_subject
					, message_descr as message_body
					, '' email_message_subject
					, '' email_msg_body
					, message_date as email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from mp_messages a
				left join #list_of_to_contacts_for_messages_notification b on a.to_cont = b.contact_id
				where message_id = @identity and message_type_id = @message_type_id and message_date = @todays_date

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
				
		end
		else if  @message_type = 'SUPPLIER_VIEW_BUYER_PROFILE' -- 151
		begin
			
			if exists (select * from mp_ViewedProfile where contactid = @from_contact and convert(date,profile_viewed_date) =  convert(date,@todays_date) )
				update mp_ViewedProfile set profile_viewed_date = @todays_date where contactid = @from_contact and convert(date,profile_viewed_date) =  convert(date,@todays_date) 
			else 
				insert into mp_ViewedProfile (ContactId,profile_viewed_date,contact_id_profile) select @from_contact , @todays_date , @to_contacts


			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					null rfq_id
					, @message_type_id  message_type_id 
					, replace(@msg_subject, '#Manufacturer_company_name#', @company)   message_subject 
					, replace(@msg_body, '#Manufacturer_company_name#', @company)  as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity = @@identity
				
			if @identity> 0 
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, '' email_message_id , message_id message_id
					, rfq_id
					, message_type_id
					, message_subject as message_subject
					, message_descr as message_body
					, '' email_message_subject
					, '' email_msg_body
					, message_date as email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from mp_messages a
				left join #list_of_to_contacts_for_messages_notification b on a.to_cont = b.contact_id
				where message_id = @identity and message_type_id = @message_type_id and message_date = @todays_date

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
				
		end
		else if  @message_type = 'RFQ_LIKED_BY_SUPPLIER'  -- 148
		begin

			set @processStatus = 'SUCCESS'
				
			select 
				@processStatus  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
				, '' as email_message_date, '' as from_contact_id, '' as from_username
				, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
				, '' as to_email_id, 0 as message_sent
				, '' as message_subject , '' as message_body
				, '' email_message_id , '' message_id
				, ''  message_type
					
			
		end
		else if  @message_type = 'RFQ_DISLIKED_BY_SUPPLIER'   -- 149
		begin

			set @processStatus = 'SUCCESS'
				
			select 
				@processStatus  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
				, '' as email_message_date, '' as from_contact_id, '' as from_username
				, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
				, '' as to_email_id, 0 as message_sent
				, '' as message_subject , '' as message_body
				, '' email_message_id , '' message_id
				, ''  message_type

			
		end
		else if  @message_type = 'rfqResponse'  -- 1
		begin
		/* checking notification required or not for to contacts*/
			if 
			(
				(
					select count(1) from mp_scheduled_job (nolock)
					where contact_id in (select contact_id from #list_of_to_contacts_for_messages_notification)
					and is_deleted = 1 and scheduler_type_id = 1
				) = 0 
			)
			/**/
			begin
				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(replace(@msg_subject, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
						, replace(replace(replace(@msg_body, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#BuyerContactName#' , username)
						, @todays_date as message_date
						, @rfq_contact_id from_contact_id 
						, contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification
				set @identity_msg = @@identity				
				
				insert into mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
				, message_sent,message_read )
				select 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, replace(replace(@email_msg_subject, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
						, replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_company_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , username),'#Message_Link#', @message_link), '#RFQNO#', @rfq_guid)
						, @todays_date as email_message_date
						, @rfq_contact_id from_contact_id 
						, contact_id as to_contact_id 
						, email_id as to_email_id
						, 0 as message_sent
						, 0 as message_read
				from #list_of_to_contacts_for_messages_notification
				WHERE is_notify_by_email = 1  /* M2-4789*/
			 
				set @identity = @@identity
				
				if @identity> 0 or @identity_msg > 0
				begin
					set @processStatus = 'SUCCESS'

					select  
						@processStatus processStatus 
						, @identity email_message_id , @identity_msg message_id
						, @rfq_id rfq_id
						, @message_type_id message_type_id
						, replace(replace(@msg_subject, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_subject
						, replace(replace(replace(@msg_body, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#BuyerContactName#' , username) as message_body
						, replace(replace(@email_msg_subject, '#SuppCompanyName#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))  email_message_subject
						, replace(replace(replace(replace(@email_msg_body, '#Manufacturer_company_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , username),'#Message_Link#', @message_link) email_msg_body
						, @todays_date email_message_date
						, @rfq_contact_id rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, b.contact_id as to_contact_id
						, b.username as to_username
						, b.email_id as to_email_id
						, 0 as message_sent
						, @message_type message_type
					from #list_of_to_contacts_for_messages_notification b 							

				end
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
					
				end
			end
			else
			begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
			end
		end
		else if  @message_type = 'RFQ_AWARDED_TO_OTH_SUPPLIER'  -- 1
		begin

		
		
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			output inserted.message_id into @notification_message_running_id
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
					, replace(@msg_body, '##RFQNO##' ,convert(varchar(15),@rfq_id))
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity_msg = @@identity				
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			output inserted.email_message_id into @notification_email_running_id
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))
					, replace(replace(replace(replace(replace(@email_msg_body, '##QuoteDate##', convert(varchar(10),c.quote_date,120)) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Manufacturer_Contact_name#', username),'#Message_Link#',''),'#RFQNO#', @rfq_guid)
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, #list_of_to_contacts_for_messages_notification.contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification
			join mp_rfq_quote_SupplierQuote c on c.rfq_id = @rfq_id and c.contact_id =  #list_of_to_contacts_for_messages_notification.contact_id  
			WHERE is_notify_by_email = 1  /* M2-4789*/

			set @identity = @@identity
				
			if @identity> 0 or @identity_msg > 0
			begin
				set @processStatus = 'SUCCESS'
						
				insert into #tmp_notification (id, message_id)
				select * from @notification_message_running_id

				update a set a.email_message_id = b.email_message_id
				from #tmp_notification a
				join @notification_email_running_id b on a.id = b.id

				select 
					a.processStatus	,b.email_message_id ,b.message_id	,a.rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
					,replace(email_msg_body,'##QuoteDate##',convert(varchar(10),c.quote_date,120))	as email_msg_body	,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
					,to_email_id		,message_sent 		,message_type
				from 
				(
					select
						row_number() over (order by @from_contact )  id
						, @processStatus processStatus 
						, @identity email_message_id , @identity_msg message_id
						, @rfq_id rfq_id
						, @message_type_id message_type_id
						, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))  as   message_subject 
						, replace(@msg_body, '##RFQNO##' ,convert(varchar(15),@rfq_id))   as message_body
						, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)) email_message_subject 
						, replace(replace(replace(@email_msg_body, '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Manufacturer_Contact_name#', username),'#Message_Link#','')  as email_msg_body
						, @todays_date email_message_date
						, @from_contact rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, contact_id as to_contact_id
						, username as to_username
						, email_id as to_email_id
						, 0 as message_sent
						, @message_type message_type
					from #list_of_to_contacts_for_messages_notification
				)
					a
				join #tmp_notification b on a.id = b.id
				join mp_rfq_quote_SupplierQuote c on c.rfq_id = @rfq_id and c.contact_id =  a.to_contact_id  

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
			
		end
	
		else if  @message_type = 'rfqConfirmationMessage'  -- 7
		begin
			/*
				--- M2-4888 
				If RFQ details exists into mpOrderManagement then supplier get new email template (248) else getting old template i.e (7)
			*/
			IF EXISTS ( SELECT RfqId FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0 ) 
			BEGIN
				 
				SET @message_type = 'MANUFACTURER_EMAIL_NOTIFICATION_ON_NEW_AWARDED_PO'
						
				SELECT @message_type_id = message_type_id,
				@email_msg_body = email_body_template, @email_msg_subject = email_subject_template
				,  @msg_body = message_body_template, @msg_subject = message_subject_template
				FROM mp_mst_email_template  (NOLOCK) WHERE message_type_id = 248 and is_active = 1 


					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					 SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, 'RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' - You''ve been awarded some parts and a purchase has been sent!' AS  message_subject 
						    , 'Congratulations! ' + @company + ' has awarded RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' to your company. Please login to your account and accept their purchase order. Once you accept their purchase order, you will need to configure part tracking statuses to update the buyer during the manufacturing process.'  AS message_descr
							, @todays_date AS message_date
							, @from_contact AS from_contact_id   ---- buyer contact id 
							, @to_contacts  AS to_contact_id     ---- supplier contact id
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author

					SET @identity_msg = @@identity
									 
					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(REPLACE(@email_msg_subject, '##RFQNO##' ,CONVERT(VARCHAR(100),CONVERT(VARCHAR(50),@rfq_id))), '#Company_Name#',@company)  AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(@email_msg_body , '##RFQNO##' ,CONVERT(VARCHAR(100),@rfq_id)) ,'#Manufacturer_Contact_name#',a.first_name +' '+ a.last_name), '#Company_Name#', @company) AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id    ---- buyer contact id 
							, @to_contacts  AS to_contact_id   ---- supplier contact id
							, c.email as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) a 
					JOIN mp_companies(NOLOCK) b ON a.company_id = b.company_id 
					JOIN aspnetusers (NOLOCK) c ON c.id = a.[user_id]
					WHERE  a.contact_id = @to_contacts
					AND a.is_notify_by_email = 1  /* M2-4789*/
					 
					SET @identity = @@identity
					 					
					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						 
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id

						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, 'RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' - You''ve been awarded some parts and a purchase has been sent!' AS  message_subject 
						        , 'Congratulations! ' + @company + ' has awarded RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' to your company. Please login to your account and accept their purchase order. Once you accept their purchase order, you will need to configure part tracking statuses to update the buyer during the manufacturing process.'  AS message_body
								, REPLACE(REPLACE(@email_msg_subject, '##RFQNO##' ,CONVERT(VARCHAR(100),@rfq_id)), '#Company_Name#', @company) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##RFQNO##' ,CONVERT(VARCHAR(100),@rfq_id)) , '#Company_Name#',@company)  AS email_msg_body
								, @todays_date email_message_date
								, @from_contact rfq_contact_id
								, @from_username AS from_username
								, @from_user_contactimage from_user_contactimage
								, @to_contacts AS to_contact_id   --- Supplier contact id
								, b.first_name +' '+ b.last_name AS to_username
								, c.Email AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) b 
							JOIN AspNetUsers(NOLOCK) c ON c.id = b.user_id
							WHERE  b.contact_id = @to_contacts
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'

					SELECT 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
						, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
						, '' AS to_email_id, 0 AS message_sent
						, '' AS message_subject , '' AS message_body
						, '' AS email_message_id , '' AS message_id
						, '' AS message_type
				END
			END

			ELSE

			BEGIN
				---- Below is existing code functionality if PO is not exists
				select distinct 
					a.rfq_id , b.contact_id ,
					e.part_name + ' ' +  convert(varchar(50) ,c.awarded_qty) + ' ' + f.value   parts_awarded
				into #tmp_part_awarded
				from mp_rfq a (nolock)
				join mp_rfq_quote_SupplierQuote b (nolock) on a.rfq_id = b.rfq_id  and  is_rfq_resubmitted = 0
				join mp_rfq_quote_items c(nolock) on b.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
				join mp_rfq_parts  d (nolock) on c.rfq_part_id = d.rfq_part_id 
				join mp_parts  e (nolock) on d.part_id = e.part_id 
				join mp_system_parameters f (nolock) on e.part_qty_unit_id = f.id
				where is_awrded =1 and a.rfq_id = @rfq_id and b.contact_id = @to_contacts

				insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				output inserted.message_id into @notification_message_running_id
				select 
						@rfq_id rfq_id
						, case 
							when  message_type_name = 'rfqConfirmationMessage' then @message_type_id
							when  message_type_name = 'BUYER_NPS_RATING' then b.message_type_id						
							when  message_type_name = 'SUPPLIER_NPS_RATING' then b.message_type_id						
						  end  as  message_type_id 
						, case 
							when  message_type_name = 'rfqConfirmationMessage' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  
							when  message_type_name = 'BUYER_NPS_RATING' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  					
							when  message_type_name = 'SUPPLIER_NPS_RATING' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  						
						  end  as   message_subject 
					
						, case 
							when  message_type_name = 'rfqConfirmationMessage' then
								replace(replace(replace(replace(replace(message_body_template, '# ##Name##' ,' ' + @rfq_name ), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'##Parts##',c.parts), '##RFQNO##', convert(varchar(50),@rfq_id) ) 
							when  message_type_name = 'SUPPLIER_NPS_RATING' then
								replace(replace(message_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) 
							when  message_type_name = 'BUYER_NPS_RATING' then
							replace(replace(message_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company)
						  end  as message_descr
						, @todays_date as message_date
						, case 
							when  message_type_name = 'rfqConfirmationMessage' then  @rfq_contact_id
							when  message_type_name = 'SUPPLIER_NPS_RATING' then 		a.contact_id				
							when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
							end as from_contact_id 
						, case 
							when  message_type_name = 'rfqConfirmationMessage' then  a.contact_id
							when  message_type_name = 'SUPPLIER_NPS_RATING' then 	 		@rfq_contact_id			
							when  message_type_name = 'BUYER_NPS_RATING' then  		 a.contact_id	
							end as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification			a
				cross apply
				(
					select 
						a.message_type_id
						,a.message_type_name 
						,message_subject_template
						,message_body_template
						,email_body_template
						,email_subject_template 
					from 
					mp_mst_message_types  a
					join mp_mst_email_template b on a.message_type_id = b.message_type_id
					where a.message_type_name in 
					('rfqConfirmationMessage'
					--, 'SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING'
					)
				) b 
				join  
				(
					select distinct  a.rfq_id , a.contact_id  , replace((select countries = stuff(( select ','+  parts_awarded	
					from  #tmp_part_awarded where contact_id = a.contact_id	for xml path('') ), 1, 1, '')) ,',' , ', ') as parts
					from #tmp_part_awarded a	
				) c on a.contact_id = c.contact_id
			
			

				set @identity_msg = @@identity

				insert into mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				output inserted.email_message_id into @notification_email_running_id
				select 
					@rfq_id rfq_id
					,  case 
							when  message_type_name = 'rfqConfirmationMessage' then @message_type_id
							when  message_type_name = 'BUYER_NPS_RATING' then b.message_type_id						
							when  message_type_name = 'SUPPLIER_NPS_RATING' then b.message_type_id						
						  end  message_type_id 
					, case 
							when  message_type_name = 'rfqConfirmationMessage' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  
							when  message_type_name = 'BUYER_NPS_RATING' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  					
							when  message_type_name = 'SUPPLIER_NPS_RATING' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  						
					  end  as email_msg_subject
					, case 
							when  message_type_name = 'rfqConfirmationMessage' then

								replace(replace(replace(replace(replace(replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username) , '# ##Name##' ,' ' + '# '+ @rfq_name), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '##Parts##',c.parts), '#RFQ_No#', @rfq_guid ) , '##RFQNo##', convert(varchar(50),@rfq_id) )

							when  message_type_name = 'SUPPLIER_NPS_RATING' then
								replace(replace(replace(email_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) ,'#Message_Link#',@message_link)
							when  message_type_name = 'BUYER_NPS_RATING' then
							replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company),'#Message_Link#',@message_link)
						  end   email_msg_body 
					, @todays_date as email_message_date
					, case 
							when  message_type_name = 'rfqConfirmationMessage' then  @rfq_contact_id
							when  message_type_name = 'SUPPLIER_NPS_RATING' then 		a.contact_id				
							when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
							end as from_contact_id 
					,  case 
							when  message_type_name = 'rfqConfirmationMessage' then  a.contact_id
							when  message_type_name = 'SUPPLIER_NPS_RATING' then 	 		@rfq_contact_id			
							when  message_type_name = 'BUYER_NPS_RATING' then  		 a.contact_id	
							end as to_contact_id 
					, case when  message_type_name = 'SUPPLIER_NPS_RATING' then  @from_user_email else email_id end as to_email_id
					, 0 as message_sent
					, 0 as message_read
				from #list_of_to_contacts_for_messages_notification			a
				cross apply
				(
					select 
						a.message_type_id
						,a.message_type_name 
						,message_subject_template
						,message_body_template
						,email_body_template
						,email_subject_template 
					from 
					mp_mst_message_types  a
					join mp_mst_email_template b on a.message_type_id = b.message_type_id
					where a.message_type_name in 
					('rfqConfirmationMessage'
					--, 'SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING'
					)
				) b
				join  
				(
					select distinct  a.rfq_id , a.contact_id  , replace((select countries = stuff(( select ','+  parts_awarded	
					from  #tmp_part_awarded where contact_id = a.contact_id	for xml path('') ), 1, 1, '')) ,',' , ', ') as parts
					from #tmp_part_awarded a	
				) c on a.contact_id = c.contact_id
				WHERE a.is_notify_by_email = 1  /* M2-4789*/  
			 
				set @identity = @@identity
				
				if @identity> 0 
				begin
					set @processStatus = 'SUCCESS'

					insert into #tmp_notification (id, message_id)
					select * from @notification_message_running_id

					update a set a.email_message_id = b.email_message_id
					from #tmp_notification a
					join @notification_email_running_id b on a.id = b.id
						

					select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
							,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
							,to_email_id		,message_sent 		,message_type
					from 
					(
						select
							row_number() over (order by b.contact_id )  id
							, @processStatus processStatus 
							, @identity email_message_id , @identity_msg message_id
							, @rfq_id rfq_id
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then @message_type_id
								when  message_type_name = 'BUYER_NPS_RATING' then b1.message_type_id						
								when  message_type_name = 'SUPPLIER_NPS_RATING' then b1.message_type_id						
							  end message_type_id
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  
								when  message_type_name = 'BUYER_NPS_RATING' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  					
								when  message_type_name = 'SUPPLIER_NPS_RATING' then replace(message_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  						
							  end  as   message_subject
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then
									replace(replace(replace(replace(replace(message_body_template, '# ##Name##' ,' ' + @rfq_name), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'##Parts##',c.parts), '##RFQNO##', convert(varchar(50),@rfq_id) ) 
								when  message_type_name = 'SUPPLIER_NPS_RATING' then
									replace(replace(message_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) 
								when  message_type_name = 'BUYER_NPS_RATING' then
								replace(replace(message_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company)
							  end as message_body
							,  case 
								when  message_type_name = 'rfqConfirmationMessage' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  
								when  message_type_name = 'BUYER_NPS_RATING' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  					
								when  message_type_name = 'SUPPLIER_NPS_RATING' then replace(email_subject_template,  '##RFQNO##', convert(varchar(50),@rfq_id) )  						
								end  as   email_message_subject
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then
									replace(replace(replace(replace(replace(replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username) ,'# ##Name##' ,' ' + @rfq_name), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link),'##Parts##',c.parts), '#RFQ_No#', @rfq_guid ) , '##RFQNo##', convert(varchar(50),@rfq_id))
								when  message_type_name = 'SUPPLIER_NPS_RATING' then
									replace(replace(replace(email_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) ,'#Message_Link#',@message_link)
								when  message_type_name = 'BUYER_NPS_RATING' then
								 replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company),'#Message_Link#',@message_link)
							  end email_msg_body
							, @todays_date email_message_date
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then  @rfq_contact_id
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		b.contact_id				
								when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
								end  rfq_contact_id
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then  @from_username
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		b.username				
								when  message_type_name = 'BUYER_NPS_RATING' then @from_username   					
								end  as from_username
							,  case 
								when  message_type_name = 'rfqConfirmationMessage' then  @from_user_contactimage
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		''				
								when  message_type_name = 'BUYER_NPS_RATING' then @from_user_contactimage   					
								end   from_user_contactimage
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then  b.contact_id
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@rfq_contact_id				
								when  message_type_name = 'BUYER_NPS_RATING' then b.contact_id  					
								end  as to_contact_id
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then  b.username
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@from_username				
								when  message_type_name = 'BUYER_NPS_RATING' then b.username					
								end	 as to_username
							,  case 
								when  message_type_name = 'rfqConfirmationMessage' then  b.email_id
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@from_user_email			
								when  message_type_name = 'BUYER_NPS_RATING' then b.email_id					
								end	   as to_email_id
							, 0 as message_sent
							, case 
								when  message_type_name = 'rfqConfirmationMessage' then @message_type
								when  message_type_name = 'BUYER_NPS_RATING' then 'BUYER_NPS_RATING'						
								when  message_type_name = 'SUPPLIER_NPS_RATING' then 'SUPPLIER_NPS_RATING'					
							  end message_type
						from #list_of_to_contacts_for_messages_notification			b
						cross apply
						(
							select 
								a.message_type_id
								,a.message_type_name 
								,message_subject_template
								,message_body_template
								,email_body_template
								,email_subject_template 
							from 
							mp_mst_message_types  a
							join mp_mst_email_template b on a.message_type_id = b.message_type_id
							where a.message_type_name in ('rfqConfirmationMessage', 'SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING')
						) b1 
						join  
						(
							select distinct  a.rfq_id , a.contact_id  , replace((select countries = stuff(( select ','+  parts_awarded	
							from  #tmp_part_awarded where contact_id = a.contact_id	for xml path('') ), 1, 1, '')) ,',' , ', ') as parts
							from #tmp_part_awarded a	
						) c on b.contact_id = c.contact_id
					)
						a
					join #tmp_notification b on a.id = b.id
			
				end
			
			 
			END
			
		end
		else if  @message_type in ('rfqNonConfirmationMessage' ,'QUOTE_RETRACTED_BY_BUYER') -- 8 , 224
		begin
		
	 
			if @message_type = 'QUOTE_RETRACTED_BY_BUYER'
			begin
			
				select @part_name = COALESCE( @part_name + ' -', '') + d.part_name  + ' ' + convert(varchar(20),a.awarded_qty) + ' ' + e.value
				from  mp_rfq_quote_items (nolock) a
				join mp_rfq_quote_supplierquote  (nolock) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.rfq_id =  @rfq_id and b.contact_id = @to_contacts 
				join mp_rfq_parts (nolock) c on a.rfq_part_id = c.rfq_part_id
				join mp_parts (nolock) d on c.part_id = d.part_id
				join mp_system_parameters  (nolock) e on c.quantity_unit_id = e.id
				where
				a.awarded_date in 
				(
					select max(awarded_date) from mp_rfq_quote_items (nolock)
					where rfq_quote_SupplierQuote_id in
					(
						select max(rfq_quote_SupplierQuote_id) from mp_rfq_quote_supplierquote  (nolock)
						where rfq_id =  @rfq_id and contact_id = @to_contacts 
					)
					and is_awrded = 0
				)

				/* M-4876 */
				SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @ReshapeUniqueId = ReshapeUniqueId
				FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
				
				EXEC [proc_set_UpdatePOStatus] @poMfgUniqueId = @poMfgUniqueId , @poStatus = 'retracted'  , @poTransactionId =  @poTransactionId

				UPDATE mpOrderManagement SET Reason = @RetractedReason  WHERE RfqId =  @rfq_id

				UPDATE a
				SET
					a.ReshapePartStatus = NULL
				FROM  mp_rfq_quote_items (NOLOCK) a
				JOIN  mp_rfq_quote_supplierquote  (NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				WHERE b.rfq_id =  @rfq_id 


				--SELECT 
				--a.* 
				/* here update isdeleted flag to 1 if retract perform*/
				UPDATE a
				SET a.IsDeleted = 1
					FROM mpOrderManagementPartStatusChangeLogs(NOLOCK) a
					LEFT JOIN mpOrderManagement(NOLOCK) b on a.ReshapeUniqueId  = b.ReshapeUniqueId AND  a.IsDeleted = 0
					WHERE  a.SupplierContactId = @to_contacts 
					AND a.ReshapeUniqueId = @ReshapeUniqueId
					 


				/**/

			end


			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@msg_subject, '#Manufacturer_Contact_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))   message_subject 
					, replace(replace(replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company), '##Message##',@part_name) , '##RetractedReason##',ISNULL(@RetractedReason,'')) as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity_msg = @@identity
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@email_msg_subject, '#Manufacturer_Contact_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
					, replace(replace(replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link),'#RFQNO#', @rfq_guid), '##Message##',@part_name) , '##RetractedReason##',ISNULL(@RetractedReason,'')) 
					--, replace(replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link),'#RFQNO#', @rfq_guid), '##Message##',@part_name) 
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification
			WHERE is_notify_by_email = 1  /* M2-4789*/

			set @identity = @@identity
				
			if @identity> 0 or @identity_msg > 0
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, @identity email_message_id , @identity_msg message_id
					, @rfq_id rfq_id
					, @message_type_id message_type_id
					, replace(replace(@msg_subject, '#Manufacturer_Contact_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) as message_subject
					, replace(replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company), '##Message##',@part_name) as message_body
					, replace(replace(@email_msg_subject, '#Manufacturer_Contact_name#', @company) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) email_message_subject
					, replace(replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '##Message##',@part_name) , '##RetractedReason##',ISNULL(@RetractedReason,''))  email_msg_body
					, @todays_date email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from #list_of_to_contacts_for_messages_notification b 

			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
			
		end
		else if  @message_type = 'RFQ_BUYER_INVITATION'  -- 152
		begin
					
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))   message_subject 
					, replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company) as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification1
			set @identity_msg = @@identity
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))   email_msg_subject 
					, replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '#RFQNO#',@rfq_guid)
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification1
			WHERE is_notify_by_email = 1  /* M2-4789*/

			set @identity = @@identity
				
			/* Data insered into mp_messages and mp_email_messages tables via below SP -> M2-4773 */
			EXEC  [proc_set_EmailRfqMissingInfo] @RfqId = @rfq_id, @todays_date = @todays_date , @message = @message 
			/**/
			
			if @identity> 0 or @identity_msg > 0
			begin
				set @processStatus = 'SUCCESS'

				select  
					@processStatus processStatus 
					, @identity email_message_id , @identity_msg message_id
					, @rfq_id rfq_id
					, @message_type_id message_type_id
					, replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id))  as message_subject
					, replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company) as message_body
					, replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)) email_message_subject
					, replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link) email_msg_body
					, @todays_date email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from #list_of_to_contacts_for_messages_notification1 b 
				UNION
				SELECT 
					@processStatus processStatus 
					, NULL email_message_id 
					, message_id message_id
					, rfq_id rfq_id
					, @message_type_id message_type_id
					, NULL  as message_subject
					, NULL as message_body
					, message_subject  email_message_subject
					, message_descr  email_msg_body
					, message_date  email_message_date
					, from_cont rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, to_cont as to_contact_id
					, NULL as to_username
					, c.email as to_email_id
					, 0 as message_sent
					--, @message_type_id message_type ---- need to check this field getting error
					, 'RFQ_RELEASE_WITH_MISSING_INFO' as message_type
				FROM mp_messages (NOLOCK) a
				JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
				JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
				WHERE rfq_id = @rfq_id 
				AND message_type_id IN (242)
				AND message_date =  @todays_date
					
			end
			else
			begin
				set @processStatus = 'FAILUER'

				if (select count(1) from mp_messages (NOLOCK) where rfq_id = @rfq_id and message_type_id IN (242) and message_date =  @todays_date ) > 0 
				begin
					set @processStatus = 'SUCCESS'

					SELECT 
					@processStatus processStatus 
					, NULL email_message_id 
					, message_id message_id
					, rfq_id rfq_id
					, @message_type_id message_type_id
					, NULL  as message_subject
					, NULL as message_body
					, message_subject  email_message_subject
					, message_descr  email_msg_body
					, message_date  email_message_date
					, from_cont rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, to_cont as to_contact_id
					, NULL as to_username
					, c.email as to_email_id
					, 0 as message_sent
					, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id IN (242)
					AND message_date =  @todays_date
					
				end
				else 
					select 
						'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
					
			end
			
		end
		else if @message_type = 'rfqFreeMessage'  --5
		begin
			
			DECLARE @messageId INT;
			if(@rfq_id=0)
			set @rfq_id=null 
			 
			insert into mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				output inserted.message_id into @notification_message_running_id
				select 
						@rfq_id as rfq_id
						, @message_type_id as message_type_id 
						,	(
								case 
									when @rfq_id is not null then 
										case 
											when CHARINDEX('RFQ #', @message_link) > 0 then '' 
											when CHARINDEX('RFQ#', @message_link) > 0 then '' 
											else 'RFQ # ' + convert(varchar(150),@rfq_id) + ' - ' 
										end +  @message_link 
									else  @message_link 
								end
							) as   message_subject 
						, @message as message_descr
						, @todays_date as message_date
						, @from_contact as from_contact_id 
						, contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				from #list_of_to_contacts_for_messages_notification_freemsg
				set @identity_msg = @@identity
				select @messageId = message_id from @notification_message_running_id
				 

				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			output inserted.email_message_id into @notification_email_running_id
			select 
					  @rfq_id as rfq_id
					, @message_type_id as message_type_id 
					, case when @is_buyer = 1 then 'Message from Buyer' else 'Message from Manufacturer' end  
					 + 	(case when @rfq_id is not null then ' for RFQ # ' + convert(varchar(150),@rfq_id)  else  '' end)
					as   message_subject  --@message_link
					, replace(replace(@email_msg_body, '#contactname#', a.username),'#msgid#',b.message_id)
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, a.contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification_freemsg a
			join @notification_message_running_id b on b.id = a.rn
			WHERE a.is_notify_by_email = 1  /* M2-4789*/

			set @identity = @@identity

			
			if @identity> 0 or @identity_msg > 0
			begin
				set @processStatus = 'SUCCESS'

				insert into #tmp_notification (id, message_id)
				select * from @notification_message_running_id

				update a set a.email_message_id = b.email_message_id
				from #tmp_notification a
				join @notification_email_running_id b on a.id = b.id
				
				select processStatus	,email_message_id ,message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
							,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
							,to_email_id		,message_sent 		,message_type
					from 
					(
						select
							 @processStatus processStatus 
							, email_message_id as  email_message_id
							, message_id as message_id
							, null rfq_id
							, @message_type_id message_type_id
							, case when @is_buyer = 1 then 'Message from Buyer' else 'Message from Manufacturer' end as   message_subject 
							, null  as message_body
							, null email_message_subject 
							,replace(replace(@email_msg_body, '#contactname#', a.username),'#msgid#',b.message_id)  as email_msg_body
							, @todays_date email_message_date
							, @from_contact rfq_contact_id
							, @from_username as from_username
							, @from_user_contactimage from_user_contactimage
							, contact_id as to_contact_id
							, username as to_username
							, email_id as to_email_id
							, 0 as message_sent
							, @message_type message_type
						from #list_of_to_contacts_for_messages_notification_freemsg a
					join #tmp_notification b on a.rn = b.id
					) c


				DECLARE @RowNo INT = 1,@IndivisualFileName varchar(max),@FileId int; 
				SELECT ROW_NUMBER() OVER(ORDER BY value ASC) AS RowNo , value into #MessageFileTable FROM 
				(
					select value from string_split(@MessageFileNames, ',')

				) AS MessageFileDetailList  				 


				While (@RowNo <= (SELECT COUNT(*) from #MessageFileTable))
				BEGIN 
					SET  @IndivisualFileName = (SELECT value from #MessageFileTable where RowNo = @RowNo);
	 
					INSERT INTO mp_special_files(FILE_NAME,CONT_ID,COMP_ID,IS_DELETED,FILETYPE_ID,CREATION_DATE,Imported_Location,parent_file_id
						,Legacy_file_id	,file_title	,file_caption,file_path	,s3_found_status,is_processed,sort_order)					 
					SELECT @IndivisualFileName,contact_id,null,0,57,getdate(),null,null,null,null,null,null,null,0,null  from 					
					 #list_of_to_contacts_for_messages_notification_freemsg a    
					set @FileId = @@identity
					
					INSERT INTO mp_message_file ( MESSAGE_ID, [FILE_ID])
					select message_id , @FileId from @notification_message_running_id

				SET @RowNo = @RowNo + 1;
				END		 
					
			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
		end
		else if  @message_type = 'BUYER_VIEWED_AN_RFQ'  -- 222
		begin
				

			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(replace(replace(@msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  message_subject 
					, replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company) as message_descr
					--, replace(@msg_body,'#RFQ_id#', '"'+convert(varchar(15),@rfq_id)+'"')   email_msg_body 
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
			set @identity_msg = @@identity
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(replace(replace(@email_msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  email_msg_subject 
					, replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '#RFQNO#',@rfq_guid) as email_msg_body
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification
			WHERE is_notify_by_email = 1  /* M2-4789*/

			set @identity = @@identity

			
			
			if @identity> 0 or @identity_msg > 0
			begin
				set @processStatus = 'SUCCESS'
				
				select  
					@processStatus processStatus 
					, @identity email_message_id , @identity_msg message_id
					, @rfq_id rfq_id
					, @message_type_id message_type_id
					, replace(replace(replace(replace(@msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  as message_subject
					, replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company) as message_body
					, replace(replace(replace(replace(@email_msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  email_message_subject
					, replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '#RFQNO#',@rfq_guid) email_msg_body
					, @todays_date email_message_date
					, @rfq_contact_id rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, b.contact_id as to_contact_id
					, b.username as to_username
					, b.email_id as to_email_id
					, 0 as message_sent
					, @message_type message_type
				from #list_of_to_contacts_for_messages_notification b 
				
				
			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
			
		end
		else if  @message_type = 'BUYER_VIEWED_AN_RFQ9999'  -- 222
		begin
				

			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(replace(replace(@msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  message_subject 
					, replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company) as message_descr
					--, replace(@msg_body,'#RFQ_id#', '"'+convert(varchar(15),@rfq_id)+'"')   email_msg_body 
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(replace(replace(@email_msg_subject, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company)  email_msg_subject 
					, replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '#RFQNO#',@rfq_guid) as email_msg_body
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification
			WHERE is_notify_by_email = 1  /* M2-4789*/
			
			
			
		end
		else if  @message_type = 'QUOTE_FEEDBACK_BUYER' -- 155
		begin
			
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, 'Feedback from the buyer for RFQ #'+convert(varchar(50),@rfq_id)+' :' +@message as   message_subject 
					, 'Feedback from the buyer for RFQ #'+convert(varchar(50),@rfq_id)+' :' +@message as message_descr
					--, replace(@msg_body,'#RFQ_id#', '"'+convert(varchar(15),@rfq_id)+'"')   email_msg_body 
					, @todays_date as message_date
					, @from_contact from_contact_id 
					, @to_contacts as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			--from #list_of_to_contacts_for_messages_notification
			set @identity = @@identity
				
			if @identity> 0 
			begin
				set @processStatus = 'SUCCESS'
				
				select 
					@processStatus as processStatus 
					, '' as email_message_id 
					, @identity as message_id
					, @rfq_id as rfq_id
					, @message_type_id  as message_type_id 
					, 'Feedback from the buyer for RFQ #'+convert(varchar(50),@rfq_id)+' :' +@message as message_subject 
					, 'Feedback from the buyer for RFQ #'+convert(varchar(50),@rfq_id)+' :' +@message as message_body
					, '' email_message_subject
					, '' email_msg_body 
					, @todays_date as email_message_date
					, @from_contact as rfq_contact_id 
					, (select top 1 first_name + ' ' + last_name from mp_contacts  (nolock) where contact_id = @from_contact) as from_username
					,  (select top 1 c.file_name from mp_contacts b  (nolock) left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17  and b.contact_id =@from_contact ) from_user_contactimage
					, @to_contacts as to_contact_id
					, (select top 1 first_name + ' ' + last_name from mp_contacts  (nolock) where contact_id = @to_contacts) as to_username
					, (select top 1 email from aspnetusers a (nolock) join mp_contacts b (nolock) on a.id = b.user_id and b.contact_id = @to_contacts) as to_email_id
					, 0 as message_sent
					, @message_type as  message_type


			end
			else
			begin
				set @processStatus = 'FAILUER'

				select 
					'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
					, '' as email_message_date, '' as from_contact_id, '' as from_username
					, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
					, '' as to_email_id, 0 as message_sent
					, '' as message_subject , '' as message_body
					, '' email_message_id , '' message_id
					, ''  message_type
					
			end
				
		end
		
		else if @message_type = 'QUOTED_MARKED_QUOTED_RFQ_EDITED' -- 226
		begin
			
				UPDATE mp_lead SET status_id = 2
				FROM mp_rfq_quote_SupplierQuote a  (nolock) 
				JOIN mp_contacts b (nolock)  on(a.contact_id = b.contact_id) AND a.rfq_id =@rfq_id
				JOIN mp_lead c (nolock)  on(b.company_id = c.company_id)
				WHERE
				c.lead_source_id = 10 AND c.value = @rfq_id
				
				
				INSERT INTO mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				SELECT 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						----, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' is being edited by '+@from_username+' and you have either marked it for quoting or sent a quote against it.'	AS  message_subject 
						----, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' is being edited by '+@from_username+' and you have either marked it for quoting or sent a quote against it.'	AS message_descr
						, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' is being edited by buyer'	AS  message_subject 
						, 'The buyer is making changes to the RFQ, and therefore you can now find it in your Quotes in Progress.  When the buyer re-releases the RFQ on the site, you will be notified to re-submit your quote if anything has changed.'	AS message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, a.contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				FROM 
				(	
					SELECT 
						DISTINCT a.contact_id
					FROM mp_rfq_quote_supplierquote (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.is_rfq_resubmitted = 0
					AND a.is_quote_submitted = 1
					UNION
					SELECT 
						DISTINCT a.contact_id 
					FROM mp_rfq_quote_suplierstatuses (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.rfq_userStatus_id in (1, 2)
				) a 
				SET @identity_msg = @@identity

				---- M2-4877-- Added email template code
				INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
				OUTPUT inserted.email_message_id INTO @notification_email_running_id
				SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(@email_msg_subject ,'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id)) AS email_msg_subject 
							, REPLACE(@email_msg_body   ,'#Manufacturer_Contact_name#',a.first_name +' '+ a.last_name)  AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---buyer contact id 
							, a.contact_id AS to_contact_id    ---supplier contact id
							, b.email as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) a 
					JOIN AspNetUsers(NOLOCK) b on a.user_id = b.id 
					WHERE  a.contact_id in
					(
						SELECT 
						DISTINCT a.contact_id
						FROM mp_rfq_quote_supplierquote (NOLOCK) a
						WHERE a.rfq_id = @rfq_id 
						AND a.is_rfq_resubmitted = 0
						AND a.is_quote_submitted = 1
						UNION
						SELECT 
							DISTINCT a.contact_id 
						FROM mp_rfq_quote_suplierstatuses (NOLOCK) a
						WHERE a.rfq_id = @rfq_id 
						AND a.rfq_userStatus_id in (1, 2)
					)
					AND a.is_notify_by_email = 1  /* M2-4789*/
				
				SET @identity = @@identity
			 	IF	@identity_msg > 0 OR @identity> 0
				BEGIN
					SET @processStatus = 'SUCCESS'
				
					
				SELECT 
					@processStatus processStatus 
					, NULL email_message_id 
					, message_id message_id
					, rfq_id rfq_id
					, @message_type_id message_type_id
					, message_subject  as message_subject
					, message_descr as message_body
					, REPLACE(@email_msg_subject ,'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id)) AS  email_message_subject 
					, REPLACE(REPLACE( @email_msg_body   ,'#Manufacturer_Contact_name#',b.first_name +' '+ b.last_name), '#Company_Name#', @company) AS email_msg_body
					, message_date email_message_date
					, from_cont rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, to_cont as to_contact_id
					, NULL as to_username
					, c.email as to_email_id
					, 0 as message_sent
					, @message_type_id message_type
				FROM mp_messages (NOLOCK) a
				JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
				JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
				WHERE rfq_id = @rfq_id 
				AND message_type_id = @message_type_id
				AND message_date =  @todays_date

			END
			ELSE
			BEGIN
				SET @processStatus = 'FAILUER'
			END


		end
		else if @message_type = 'AWARDED_OFFLINE_MANUFACTURER' -- 227
		begin
			
								
				INSERT INTO mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				SELECT 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' - '+ @rfq_name +' has parts that have been awarded to an offline manufacturer.'	AS message_subject 
						, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' - '+ @rfq_name +' has parts that have been awarded to an offline manufacturer.'	AS message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, a.contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				FROM 
				(	
					SELECT 
						DISTINCT a.contact_id
					FROM mp_rfq_quote_supplierquote (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.is_rfq_resubmitted = 0
					AND a.is_quote_submitted = 1
					UNION
					SELECT 
						DISTINCT a.contact_id 
					FROM mp_rfq_quote_suplierstatuses (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.rfq_userStatus_id in (1, 2)
				) a 
				SET @identity_msg = @@identity

				IF	@identity_msg > 0
				BEGIN
					SET @processStatus = 'SUCCESS'
				
					
					SELECT 
						@processStatus processStatus 
						, NULL email_message_id 
						, message_id message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, message_subject  as message_subject
						, message_descr as message_body
						, NULL  email_message_subject
						, NULL email_msg_body
						, message_date email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id = @message_type_id
					AND message_date =  @todays_date

			END
			ELSE
			BEGIN
				SET @processStatus = 'FAILUER'
			END


		end
		else if @message_type = 'RFQ_NOT_AWARDED' -- 227
		begin
			
								
				INSERT INTO mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				SELECT 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' - '+ @rfq_name +' has parts that will not be awarded.'	AS message_subject 
						, 'RFQ# '+CONVERT(VARCHAR(50),@rfq_id)+' - '+ @rfq_name +' has parts that will not be awarded.'	AS message_descr
						, @todays_date as message_date
						, @from_contact from_contact_id 
						, a.contact_id as to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				FROM 
				(	
					SELECT 
						DISTINCT a.contact_id
					FROM mp_rfq_quote_supplierquote (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.is_rfq_resubmitted = 0
					AND a.is_quote_submitted = 1
					UNION
					SELECT 
						DISTINCT a.contact_id 
					FROM mp_rfq_quote_suplierstatuses (NOLOCK) a
					WHERE a.rfq_id = @rfq_id 
					AND a.rfq_userStatus_id in (1, 2)
				) a 
				SET @identity_msg = @@identity

				IF	@identity_msg > 0
				BEGIN
					SET @processStatus = 'SUCCESS'
				
					
					SELECT 
						@processStatus processStatus 
						, NULL email_message_id 
						, message_id message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, message_subject  as message_subject
						, message_descr as message_body
						, NULL  email_message_subject
						, NULL email_msg_body
						, message_date email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id = @message_type_id
					AND message_date =  @todays_date

			END
			ELSE
			BEGIN
				SET @processStatus = 'FAILUER'
			END


		end
		/* M2-3717 Email - MULTI-PART RFQ EMAIL - MANUFACTURER */
		else if @message_type = 'COMMUNITY_DIRECTORY_RFQ' -- 231
		begin
			
				DROP TABLE IF EXISTS #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ

				SELECT 
					a.contact_id						AS BuyerId
					, a.rfq_id							AS RfqNo
					, a.rfq_guid						AS RfqGUId
					, ISNULL(d.discipline_name,'')		AS Process
					, ISNULL(e.material_name_en,'')		AS Material
					, ISNULL(h.region_name,'-')			AS BuyerState
					, ISNULL(i.CompanyType,'-')			AS BuyerIndustry
					, ROW_NUMBER() OVER(ORDER BY a.rfq_id) AS RN
					, f.first_name + ' ' + f.last_name AS FromUsername
					, j.file_name AS FromUserContactimage
				INTO #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ
				FROM mp_rfq						a	(NOLOCK)
				JOIN mp_rfq_parts				b	(NOLOCK) ON a.rfq_id = b.rfq_id
				LEFT JOIN mp_mst_part_category	c	(NOLOCK) ON b.part_category_id = c.part_category_id AND c.status_id = 2
				LEFT JOIN mp_mst_part_category	d	(NOLOCK) ON c.parent_part_category_id = d.part_category_id AND d.status_id = 2
				LEFT JOIN mp_mst_materials		e	(NOLOCK) ON b.material_id = e.material_id
				JOIN mp_contacts				f	(NOLOCK) ON a.contact_id = f.contact_id
				LEFT JOIN mp_addresses			g	(NOLOCK) ON f.address_id = g.address_id
				LEFT JOIN mp_mst_region			h	(NOLOCK) ON g.region_id = h.region_id AND g.region_id <> 0
				LEFT JOIN 
				(
					SELECT 
						CompSuppl.company_id CompanyId
						, SuppType.IndustryBranches_name_EN as CompanyType
						, ROW_NUMBER () OVER (PARTITION BY CompSuppl.company_id  ORDER BY CompSuppl.company_id , CompSuppl.supplier_type_id DESC) RN
					FROM mp_company_supplier_types CompSuppl	(NOLOCK) 
					LEFT JOIN mp_mst_IndustryBranches SuppType  (NOLOCK) ON CompSuppl.supplier_type_id=SuppType.IndustryBranches_id  
				) i ON f.company_id = i.CompanyId
				left join mp_special_files j  (nolock) on a.contact_id = j.cont_id and filetype_id = 17
				WHERE a.IsMfgCommunityRfq = 1 
				AND a.rfq_id  = @rfq_id

				

				--SELECT * FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ
				DECLARE @email_msg_body_first_part AS NVARCHAR(MAX) = ''
				DECLARE @email_msg_body_middle_part AS NVARCHAR(MAX) = ''
				DECLARE @email_msg_body_middle_part_final AS NVARCHAR(MAX) = ''
				DECLARE @email_msg_body_last_part AS NVARCHAR(MAX) = ''
				DECLARE @BuyerState  AS NVARCHAR(MAX) = (SELECT DISTINCT BuyerState  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ)
				DECLARE @BuyerIndustry AS NVARCHAR(MAX) = (SELECT DISTINCT BuyerIndustry  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ)
				DECLARE @RfqGUId AS NVARCHAR(MAX) = (SELECT DISTINCT RfqGUId  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ)
				DECLARE @BuyerId AS NVARCHAR(MAX) = (SELECT DISTINCT BuyerId  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ)
				
				SET @from_username =  (SELECT DISTINCT FromUsername  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ) 
				SET @from_user_contactimage =  (SELECT DISTINCT FromUserContactimage  FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ) 

				
				SET @email_msg_body_first_part = SUBSTRING(@email_msg_body,0,CHARINDEX('<!--Rfq Details Iteration Start here -->',@email_msg_body))
				SET @email_msg_body_middle_part = SUBSTRING(@email_msg_body,CHARINDEX('<!--Rfq Details Iteration Start here -->',@email_msg_body),CHARINDEX('<!--Rfq Details Iteration End here -->',@email_msg_body) - CHARINDEX('<!--Rfq Details Iteration Start here -->',@email_msg_body))
				SET @email_msg_body_last_part = SUBSTRING(@email_msg_body,CHARINDEX('<!--Rfq Details Iteration End here -->',@email_msg_body),LEN(@email_msg_body))

				DECLARE @Counter INT 
				DECLARE @Process VARCHAR(MAX) = ''
				DECLARE @Material VARCHAR(MAX)  = ''
				SET @Counter=1
				WHILE ( @Counter <= (SELECT COUNT(1) FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ))
				BEGIN
					
					SELECT 
						@Process = Process
						,@Material = Material
					FROM #tmp_email_messages_COMMUNITY_DIRECTORY_RFQ WHERE RN = @Counter

					SET @email_msg_body_middle_part_final = 
						@email_msg_body_middle_part_final 
						+ REPLACE(REPLACE(@email_msg_body_middle_part  , '#Process#' ,  @Process ) ,'#Material#' , @Material)
					SET @Counter  = @Counter  + 1
				END
				
				SET @email_msg_body = @email_msg_body_first_part + @email_msg_body_middle_part_final + @email_msg_body_last_part
				--SELECT @email_msg_subject 		
				--, @email_msg_body 	
				--, @email_msg_body_first_part
				--, @email_msg_body_middle_part
				--, @email_msg_body_last_part
				--, @email_msg_body_middle_part_final
				--, @from_username
				--, @from_user_contactimage

				/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
				INSERT INTO mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				OUTPUT inserted.message_id INTO @notification_message_running_id
				SELECT 
						@rfq_id rfq_id
						, @message_type_id  message_type_id 
						, REPLACE(REPLACE(@email_msg_subject,'#RfqNo#',''+CONVERT(VARCHAR(50),@rfq_id)+''), '#SupplierFirstName#' , b.first_name) message_subject 
						, REPLACE(REPLACE(@email_msg_subject,'#RfqNo#',''+CONVERT(VARCHAR(50),@rfq_id)+''), '#SupplierFirstName#' , b.first_name) message_subject  
						, @todays_date as message_date
						, @BuyerId from_contact_id 
						, b.contact_id AS to_contact_id 
						, 0 as message_sent
						, 0 as message_read
						, 0 as trash
						, 0 as from_trash
						, 0 as real_from_cont_id
						, 0 as is_last_message
						, 0 as message_status_id_recipient
						, 0 as message_status_id_author
				FROM mp_rfq_supplier (NOLOCK) a
				JOIN mp_contacts	(NOLOCK) b ON a.company_id = b.company_id AND is_buyer= 0
				JOIN aspnetusers	(NOLOCK) c ON b.user_id = c.id
				WHERE a.rfq_id = @rfq_id 
				/**/ 

				INSERT INTO mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				OUTPUT inserted.email_message_id INTO @notification_email_running_id
				SELECT 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					,  REPLACE(REPLACE(@email_msg_subject,'#RfqNo#',''+CONVERT(VARCHAR(50),@rfq_id)+''), '#SupplierFirstName#' , b.first_name) message_subject 
					,  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#SupplierFirstName#',  b.first_name) , '#State#' ,@BuyerState),'#Industry#',@BuyerIndustry), '#RfqId#',''+CONVERT(VARCHAR(50),@rfq_id)+''), '#RfqGuid#',+CONVERT(VARCHAR(50),@rfq_id))  AS message_descr
					, @todays_date AS email_message_date
					, @BuyerId from_contact_id 
					, b.contact_id AS to_contact_id 
					, c.Email AS to_email_id
					, 0 AS message_sent
					, 0 AS message_read
				FROM mp_rfq_supplier (NOLOCK) a
				JOIN mp_contacts	(NOLOCK) b ON a.company_id = b.company_id AND is_buyer= 0
				AND b.is_notify_by_email = 1 /* M2-4789*/
				JOIN aspnetusers	(NOLOCK) c ON b.user_id = c.id
				WHERE a.rfq_id = @rfq_id 
				
				IF	(SELECT COUNT(1) FROM @notification_email_running_id) > 0
				BEGIN
					SET @processStatus = 'SUCCESS'
				
					
					SELECT 
						@processStatus processStatus 
						, email_message_id email_message_id 
						, NULL message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, NULL  as message_subject
						, NULL as message_body
						, email_message_subject  email_message_subject
						, email_message_descr email_msg_body
						, email_message_date email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_email_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id = @message_type_id
					AND email_message_date =  @todays_date
					UNION
					SELECT 
						@processStatus processStatus 
						, NULL email_message_id 
						, message_id message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, NULL  as message_subject
						, NULL as message_body
						, message_subject  email_message_subject
						, message_descr  email_msg_body
						, message_date  email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id = @message_type_id
					AND message_date =  @todays_date

				END
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'
				END		



		end
		/**/
		/* M2-3717 Email - MULTI-PART RFQ EMAIL - MANUFACTURER */
		else if @message_type = 'BUYER_INCOMPLETE_PROFILE' -- 232
		begin
			        --- Declare below variable in above
				--DECLARE @ToBuyer VARCHAR(250) = 0
				--DECLARE @ToBuyerEmail VARCHAR(250) = ''
				
				SELECT 
					@ToBuyer = b.first_name +' '+ b.last_name
					, @ToBuyerEmail = c.email
				FROM mp_contacts (NOLOCK) b 
				JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
				WHERE b.contact_id = @to_contacts
				

				--SELECT 
				--	@msg_subject
				--	,@msg_body
				--	,@email_msg_subject
				--	,@email_msg_body 

				
				INSERT INTO mp_messages
				( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
				OUTPUT inserted.message_id INTO @notification_message_running_id
				SELECT 
					NULL rfq_id
					, @message_type_id  message_type_id 
					, REPLACE(@msg_subject , '#BuyerDisplayName#' , @ToBuyer)	AS message_subject 
					, @msg_body	AS message_descr
					, @todays_date as message_date
					, NULL from_contact_id 
					, @to_contacts as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author


				IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @to_contacts AND is_notify_by_email = 1 )   /* M2-4789*/
		        BEGIN
				INSERT INTO mp_email_messages
				( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
				,from_cont ,to_cont, to_email, message_sent,message_read )
				OUTPUT inserted.email_message_id INTO @notification_email_running_id
				SELECT 
					NULL rfq_id
					, @message_type_id  message_type_id 
					,  REPLACE(@email_msg_subject , '#BuyerDisplayName#' , @ToBuyer) message_subject 
					,  REPLACE(@email_msg_body , '#BuyerDisplayName#' , @ToBuyer)  AS message_descr
					, @todays_date AS email_message_date
					, NULL from_contact_id 
					, @to_contacts AS to_contact_id 
					, @ToBuyerEmail AS to_email_id
					, 0 AS message_sent
					, 0 AS message_read
				
				END
				
				----IF	((SELECT COUNT(1) FROM @notification_email_running_id) > 0 AND (SELECT COUNT(1) FROM @notification_message_running_id) > 0 ) ---Commented with  /* M2-4789*/
				IF	((SELECT COUNT(1) FROM @notification_email_running_id) > 0 OR (SELECT COUNT(1) FROM @notification_message_running_id) > 0 )
				BEGIN
					SET @processStatus = 'SUCCESS'
				
					
					select  
						@processStatus processStatus 
						, (SELECT email_message_id FROM @notification_email_running_id) AS email_message_id 
						, (SELECT message_id FROM @notification_message_running_id) AS message_id
						, NULL AS rfq_id
						, @message_type_id AS message_type_id
						, REPLACE(@msg_subject , '#BuyerDisplayName#' , @ToBuyer) AS message_subject
						, @msg_body  AS message_body
						, REPLACE(@email_msg_subject , '#BuyerDisplayName#' , @ToBuyer) AS  email_message_subject
						, REPLACE(@email_msg_body , '#BuyerDisplayName#' , @ToBuyer) AS  email_msg_body
						, @todays_date email_message_date
						, NULL AS rfq_contact_id
						, NULL AS from_username
						, NULL AS from_user_contactimage
						, @to_contacts	AS to_contact_id
						, @ToBuyer		AS to_username
						, @ToBuyerEmail AS to_email_id
						, 0				AS message_sent
						, @message_type AS message_type
					
					
				END
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'
				END		

		end 
		/**/
		/* M2-3910 M - Email - Your profile is not complete - DB */
		else if @message_type = 'SUPPLIER_INCOMPLETE_PROFILE' -- 233
		begin

			SELECT 
				@ToSupplier =	a.first_name +' '+a.last_name
				,@ToSupplierEmail = b.email
			FROM mp_contacts (NOLOCK) a
			JOIN aspnetusers (NOLOCK) b ON a.[user_id] = b.id
			WHERE a.contact_id = @to_contacts

			IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @to_contacts AND is_notify_by_email = 1 )   /* M2-4789*/
		    BEGIN
			INSERT INTO mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
			,from_cont ,to_cont, to_email, message_sent,message_read )
			SELECT 
				NULL rfq_id
				, @message_type_id  message_type_id 
				, @email_msg_subject email_subject 
				, REPLACE(@email_msg_body , '#FirstName#' , @ToSupplier)  AS email_body
				, @todays_date AS email_message_date
				, NULL from_contact_id 
				, @to_contacts AS to_contact_id 
				, @ToSupplierEmail AS to_email_id
				, 0 AS message_sent
				, 0 AS message_read
			END

		end
		/**/
		/* M2-3926 M - Email - Congrats your profile is live - DB */
		else if @message_type = 'SUPPLIER_PROFILE_APPROVED' -- 234
		begin


			DECLARE @PublicProfile VARCHAR(1000) 
			DECLARE @SupplierCompanyId INT
			DECLARE @tbl_PublicProfile table (PublicProfile VARCHAR(1000) ,PublicProfileDetail VARCHAR(1000))

			SELECT 
				@ToSupplier =	a.first_name +' '+a.last_name
				,@ToSupplierEmail = b.email
				,@SupplierCompanyId = a.company_id
			FROM mp_contacts (NOLOCK) a
			JOIN aspnetusers (NOLOCK) b ON a.[user_id] = b.id
			WHERE a.contact_id = @to_contacts

			INSERT INTO @tbl_PublicProfile (PublicProfile , PublicProfileDetail)
			EXEC proc_get_CommunityCompanyProfileURL @CompanyId = @SupplierCompanyId
			
			SET @PublicProfile = (SELECT PublicProfile FROM @tbl_PublicProfile)

			IF EXISTS( SELECT contact_id FROM mp_contacts(NOLOCK) WHERE contact_id = @to_contacts AND is_notify_by_email = 1 )   /* M2-4789*/
		    BEGIN
			INSERT INTO mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
			,from_cont ,to_cont, to_email, message_sent,message_read )
			SELECT 
				NULL rfq_id
				, @message_type_id  message_type_id 
				, @email_msg_subject email_subject 
				, REPLACE(REPLACE(@email_msg_body , '#FirstName#' , @ToSupplier),'#PublicProfile#', ISNULL(@PublicProfile,''))  AS email_body
				, @todays_date AS email_message_date
				, NULL from_contact_id 
				, @to_contacts AS to_contact_id 
				, @ToSupplierEmail AS to_email_id
				, 0 AS message_sent
				, 0 AS message_read
			END

		end
		/**/
		/*  M2-3249 M - Send M a Notification and Email when an RFQ is released from a followed buyer -DB */
		else if  @message_type = 'RFQ_RELEASE_NOTIFICATION_FROM_FOLLOWED_BUYER'  -- 240
		begin
				
				
			
			insert into mp_messages
			( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
			OUTPUT inserted.message_id INTO @notification_message_running_id
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)) ,'##RFQName##' ,@rfq_name)  message_subject 
					, replace(replace(replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'##RFQName##' ,@rfq_name) as message_descr
					, @todays_date as message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, 0 as message_sent
					, 0 as message_read
					, 0 as trash
					, 0 as from_trash
					, 0 as real_from_cont_id
					, 0 as is_last_message
					, 0 as message_status_id_recipient
					, 0 as message_status_id_author
			from #list_of_to_contacts_for_messages_notification1
				
				
			insert into mp_email_messages
			( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
			, message_sent,message_read )
			OUTPUT inserted.email_message_id INTO @notification_email_running_id
			select 
					@rfq_id rfq_id
					, @message_type_id  message_type_id 
					, replace(replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)),'##RFQName##' ,@rfq_name)   email_msg_subject 
					, replace(replace(replace(replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Buyer_Name#' , @from_username) , '#Company_Name#',@company),'#Message_Link#',@message_link), '#RFQNO#',@rfq_guid),'##RFQName##' ,@rfq_name)
					, @todays_date as email_message_date
					, @rfq_contact_id from_contact_id 
					, contact_id as to_contact_id 
					, email_id as to_email_id
					, 0 as message_sent
					, 0 as message_read
			from #list_of_to_contacts_for_messages_notification1
			WHERE is_notify_by_email = 1  /* M2-4789*/

						
			/* M2-4773 Data insered into mp_email_messages tables via below SP : */
			EXEC  proc_set_EmailRfqMissingInfo @RfqId = @rfq_id, @todays_date = @todays_date , @message = @message 
			/**/
				
			if ((SELECT COUNT(1) FROM @notification_email_running_id) > 0 AND (SELECT COUNT(1) FROM @notification_message_running_id) > 0 )
			begin
				set @processStatus = 'SUCCESS'
			
				SELECT 
						@processStatus processStatus 
						, email_message_id email_message_id 
						, NULL message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, NULL  as message_subject
						, NULL as message_body
						, email_message_subject  email_message_subject
						, email_message_descr email_msg_body
						, email_message_date email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_email_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id IN (@message_type_id)
					AND email_message_date =  @todays_date
					UNION					SELECT 
						@processStatus processStatus 
						, NULL email_message_id 
						, message_id message_id
						, rfq_id rfq_id
						, @message_type_id message_type_id
						, NULL  as message_subject
						, NULL as message_body
						, message_subject  email_message_subject
						, message_descr  email_msg_body
						, message_date  email_message_date
						, from_cont rfq_contact_id
						, @from_username as from_username
						, @from_user_contactimage from_user_contactimage
						, to_cont as to_contact_id
						, NULL as to_username
						, c.email as to_email_id
						, 0 as message_sent
						, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id IN (@message_type_id,242)
					AND message_date =  @todays_date
							
			end
			else
			begin
				set @processStatus = 'FAILUER'

				if (select count(1) from mp_messages (NOLOCK) where rfq_id = @rfq_id and message_type_id IN (242) and message_date =  @todays_date ) > 0 
				begin
		
					set @processStatus = 'SUCCESS'

					SELECT 
					@processStatus processStatus 
					, NULL email_message_id 
					, message_id message_id
					, rfq_id rfq_id
					, @message_type_id message_type_id
					, NULL  as message_subject
					, NULL as message_body
					, message_subject  email_message_subject
					, message_descr  email_msg_body
					, message_date  email_message_date
					, from_cont rfq_contact_id
					, @from_username as from_username
					, @from_user_contactimage from_user_contactimage
					, to_cont as to_contact_id
					, NULL as to_username
					, c.email as to_email_id
					, 0 as message_sent
					, @message_type_id message_type
					FROM mp_messages (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE rfq_id = @rfq_id 
					AND message_type_id IN (242)
					AND message_date =  @todays_date
					
				end
				else 
				
					select 
						'FAILUER: No data for message notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
				
					
			end
			
		end
		/* M2-4837 */
		 else if  @message_type in( 'BUYER_SELECTS_RESUBMIT_QUOTE')   -- 243
		 BEGIN
				 			
					insert into mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					output inserted.message_id into @notification_message_running_id
					select 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, replace(replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company)   message_subject 
							, replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company) as message_descr
							, @todays_date as message_date
							, @rfq_contact_id from_contact_id 
							, @to_contacts as to_contact_id 
							, 0 as message_sent
							, 0 as message_read
							, 0 as trash
							, 0 as from_trash
							, 0 as real_from_cont_id
							, 0 as is_last_message
							, 0 as message_status_id_recipient
							, 0 as message_status_id_author
					from mp_rfq_quote_suplierstatuses (NOLOCK) a
					join mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id
					WHERE a.rfq_id = @rfq_id AND a.contact_id = @to_contacts

					 
					set @identity_msg = @@identity
					 
									
					insert into mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					output inserted.email_message_id into @notification_email_running_id
					select 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, replace(replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company)   email_msg_subject 
							,  replace(replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) , '#RFQNO#', @rfq_guid) , '#Company_Name#',@company)
							, @todays_date as email_message_date
							, @rfq_contact_id from_contact_id 
							, @to_contacts as to_contact_id 
							, Email as to_email_id
							, 0 as message_sent
							, 0 as message_read
					from mp_rfq_quote_suplierstatuses (NOLOCK) a
					join mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id
					AND b.is_notify_by_email = 1  /* M2-4789*/
					join aspnetusers(nolock) c ON c.id = b.user_id 
					WHERE a.rfq_id = @rfq_id AND a.contact_id = @to_contacts

					set @identity = @@identity


					if @identity> 0 or @identity_msg > 0
					begin
						set @processStatus = 'SUCCESS'
						
						insert into #tmp_notification (id, message_id)
						select * from @notification_message_running_id
						
						insert into #tmp_notification (id, email_message_id)
						select * from @notification_email_running_id

						select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
								, case when b.email_message_id is null then a.message_subject  else a.email_msg_body end as  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
								,to_email_id		,message_sent 		,message_type
						from 
						(
							select
								row_number() over (order by b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id , @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, replace(replace(@msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company)  as message_subject
								, replace(replace(replace(@msg_body, '#Manufacturer_Contact_name#', username) , '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company)  as message_body
								, replace(replace(@email_msg_subject, '##RFQNO##' ,convert(varchar(15),@rfq_id)), '#Company_Name#',@company)   email_message_subject
								, replace(replace(replace(@email_msg_body, '#Manufacturer_Contact_name#',  b.first_name + ' ' + b.last_name ) , '##RFQNO##' ,convert(varchar(15),@rfq_id)) , '#Company_Name#',@company)  email_msg_body
								, @todays_date email_message_date
								, @rfq_contact_id rfq_contact_id
								, @from_username as from_username
								, @from_user_contactimage from_user_contactimage
								, b.contact_id as to_contact_id
								, b.first_name + ' ' + b.last_name as to_username
								, c.email as to_email_id
								, 0 as message_sent
								, @message_type message_type
					from mp_rfq_quote_suplierstatuses (NOLOCK) a
					join mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id
					join aspnetusers(nolock) c ON c.id = b.user_id 
					WHERE a.rfq_id = @rfq_id AND a.contact_id = @to_contacts
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				end --1
				else
				begin
					set @processStatus = 'FAILUER'

					select 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type
				end

					 
		 END

		 /*M2-4826 and M2-4827*/
		 ELSE IF  @message_type in( 'BUYER_EMAIL_NOTIFICATION_FOR_PO_ACCEPTANCE')   -- 244
		 BEGIN

					 SELECT 
								@ToBuyer = b.first_name +' '+ b.last_name
								, @ToBuyerEmail = c.email
							FROM mp_contacts (NOLOCK) b 
							JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
							WHERE b.contact_id = @to_contacts

					SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @PONumber = PONumber
					,@RfqEncryptedId = RfqEncryptedId
					FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
								 			
					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, @company + ' has accepted your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS  message_subject 
						    , @company + ' has accepted your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS message_descr
							, @todays_date AS message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts AS to_contact_id   ---buyer contact id
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author
					
				  
					SET @identity_msg = @@identity
						
					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(REPLACE(@email_msg_subject, '##RFQNO##' ,CONVERT(VARCHAR(15),@rfq_id)), '#Manufacturer_Contact_name#',b.first_name + ' ' + b.last_name)  AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##RFQNO##' ,CONVERT(VARCHAR(15),@rfq_id)) , '#RfqEncryptedId#', CONVERT(VARCHAR(50),@RfqEncryptedId)) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts  AS to_contact_id   ---buyer contact id
							, @ToBuyerEmail as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) b 
					WHERE  b.contact_id = @from_contact
					AND b.is_notify_by_email = 1  /* M2-4789*/

					SET @identity = @@identity
					
					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id

						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, @company + ' has accepted your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS  message_subject 
								, @company + ' has accepted your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS message_body
								, REPLACE(REPLACE(@email_msg_subject, '##RFQNO##' ,CONVERT(VARCHAR(15),@rfq_id)), '#Manufacturer_Contact_name#',b.first_name + ' ' + b.last_name) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##RFQNO##' ,CONVERT(VARCHAR(15),@rfq_id)) , '#RfqEncryptedId#', CONVERT(VARCHAR(50),@RfqEncryptedId)) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, b.first_name + ' ' + b.last_name AS from_username
								, @from_user_contactimage from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, @ToBuyer AS to_username
								, @ToBuyerEmail AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) b 
							WHERE  b.contact_id = @from_contact
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'

					SELECT 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
						, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
						, '' AS to_email_id, 0 AS message_sent
						, '' AS message_subject , '' AS message_body
						, '' AS email_message_id , '' AS message_id
						, '' AS message_type
				END

				 
					 
		 END

		  /*M2-4826 and M2-4829*/
		 else if  @message_type in( 'BUYER_EMAIL_NOTIFICATION_FOR_PO_CANCELATION')   -- 245
		 BEGIN

					SELECT 
						@ToBuyer = b.first_name +' '+ b.last_name
						, @ToBuyerEmail = c.email
					FROM mp_contacts (NOLOCK) b 
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE b.contact_id = @to_contacts

					SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @PONumber = PONumber
					,@RfqEncryptedId = RfqEncryptedId , @ReshapeUniqueId = ReshapeUniqueId
					FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
			 			
					UPDATE mpOrderManagement SET Reason = @RetractedReason  WHERE RfqId =  @rfq_id

					/*
					/* TBD : This status need to reset null or not Set ReshapePartStatus to null if PO cancelllation */
					UPDATE a
					SET	a.ReshapePartStatus = NULL
					FROM  mp_rfq_quote_items (NOLOCK) a
					JOIN  mp_rfq_quote_supplierquote  (NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
					WHERE b.rfq_id = @rfq_id
					/* END Set ReshapePartStatus to null if PO cancelllation */

					/* here update isdeleted flag to 1 if PO cancelllation*/
					UPDATE a
					SET a.IsDeleted = 1
					FROM mpOrderManagementPartStatusChangeLogs(NOLOCK) a
					LEFT JOIN mpOrderManagement(NOLOCK) b on a.ReshapeUniqueId  = b.ReshapeUniqueId AND  a.IsDeleted = 0
					WHERE  a.SupplierContactId = @from_contact  
					AND a.ReshapeUniqueId = @ReshapeUniqueId
					/* here update isdeleted flag to 1 if PO cancelllation*/

					*/

					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, @company + ' has canceled your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.'  AS  message_subject 
						    , @company + ' has canceled your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' + '<br> <b>Reason</b> : ' + CAST(ISNULL(@CancelledReason,'') AS VARCHAR(2000)) + ' </br>' AS message_descr
							, @todays_date AS message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts AS to_contact_id   ---buyer contact id
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author
					
			
					set @identity_msg = @@identity
					 
						

					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(15),@PONumber)), '#Manufacturer_Contact_name#',b.first_name + ' ' + b.last_name)  AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) , '#RFQNO#', @rfq_guid) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) , '##CancelledReason##',ISNULL(@CancelledReason,''))  AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts  AS to_contact_id   ---buyer contact id
							, @ToBuyerEmail as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) b 
					WHERE  b.contact_id = @from_contact
					AND b.is_notify_by_email = 1  /* M2-4789*/

					SET @identity = @@identity

					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id
						 
						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, @company + ' has canceled your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS  message_subject 
								, @company + ' has canceled your purchase order for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '.' AS message_body
								, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(15),@PONumber)), '#Manufacturer_Contact_name#',b.first_name + ' ' + b.last_name) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##ORDERNO##' ,CONVERT(VARCHAR(15),@PONumber)) , '#RFQNO#', @rfq_guid) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) , '##CancelledReason##',ISNULL(@CancelledReason,''))  AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, b.first_name + ' ' + b.last_name AS from_username
								, @from_user_contactimage from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, @ToBuyer AS to_username
								, @ToBuyerEmail AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) b 
							WHERE  b.contact_id = @from_contact
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'

					SELECT 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
						, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
						, '' AS to_email_id, 0 AS message_sent
						, '' AS message_subject , '' AS message_body
						, '' AS email_message_id , '' AS message_id
						, '' AS message_type
				END
					 
		 END

		  /*M2-4831*/
		 ELSE IF  @message_type in( 'BUYER_EMAIL_NOTIFICATION_RECEIVED_ON_PO_UPDATE_PART')   -- 247
		 BEGIN
		
					SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @PONumber = PONumber
					FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
				
					SELECT 
						@ToBuyer = b.first_name +' '+ b.last_name
					   ,@ToBuyerEmail = c.email
					FROM mp_contacts (NOLOCK) b 
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE b.contact_id = @to_contacts
			 			
					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					 SELECT 
							@rfq_id AS rfq_id
							, @message_type_id  AS message_type_id 
							, 'Status for [' + e.part_name + '] in Order Number # ' +CONVERT(VARCHAR(50),f.PONumber) + ' has updated!' AS  message_subject 
						    , 'Status for [' + e.part_name + '] in Order Number # ' +CONVERT(VARCHAR(50),f.PONumber) + ' has updated!' AS message_descr
							, @todays_date AS message_date
							, a.contact_id as from_contact_id
							, g.contact_id AS to_contact_id 
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author
							FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
							JOIN mp_rfq_quote_items( NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
							JOIN mp_rfq_part_quantity (NOLOCK) c on c.rfq_part_quantity_id = b.rfq_part_quantity_id
							JOIN mp_rfq_parts(NOLOCK) d on d.rfq_part_id = c.rfq_part_id
							JOIN mp_parts(NOLOCK) e on e.part_id = d.part_id
							JOIN  mpOrderManagement (NOLOCK) f on f.rfqid = a.rfq_id AND IsDeleted = 0
							JOIN mp_rfq(NOLOCK) g on g.rfq_id = f.rfqid
							where    a.rfq_id = @rfq_id
							and b.rfq_quote_items_id in ((select value from string_split(@quoted_quantity_id, ',')))

					SET @identity_msg = @@identity

									
					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)), '#Company_Name#',@company)  AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(@email_msg_body , '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts  AS to_contact_id   ---buyer contact id
							, @ToBuyerEmail as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) b 
					WHERE  b.contact_id = @from_contact
					AND b.is_notify_by_email = 1  /* M2-4789*/

					SET @identity = @@identity
					 					
					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						 
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id

						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY b.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, @company + ' has updated the part statuses for order # '+CONVERT(VARCHAR(100),@PONumber) + '.' AS  message_subject 
								, @company + ' has updated the part statuses for order # '+CONVERT(VARCHAR(100),@PONumber) + '.' AS message_body
								, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)), '#Company_Name#', @company) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '#Manufacturer_Contact_name#', b.first_name + ' ' + b.last_name) , '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) , '#Company_Name#',@company) ,'#Buyer_Name#',@ToBuyer) AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, b.first_name + ' ' + b.last_name AS from_username
								, @from_user_contactimage from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, @ToBuyer AS to_username
								, @ToBuyerEmail AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) b 
							WHERE  b.contact_id = @from_contact
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
				ELSE
				BEGIN
					SET @processStatus = 'FAILUER'

					SELECT 
						'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
						, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
						, '' AS to_email_id, 0 AS message_sent
						, '' AS message_subject , '' AS message_body
						, '' AS email_message_id , '' AS message_id
						, '' AS message_type
				END

				 
					 
		 END

		 /*M2-4948*/ 
		 ELSE IF  @message_type in( 'BUYER_EMAIL_NOTIFICATION_RECEIVED_ON_NEW_INVOICE')   -- 249
		 BEGIN
				    SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @PONumber = PONumber
					FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
			
					SELECT 
						@ToBuyer = b.first_name +' '+ b.last_name
					   ,@ToBuyerEmail = c.email
					FROM mp_contacts (NOLOCK) b 
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE b.contact_id = @to_contacts
			 			
					
					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, a.first_name + ' ' + a.last_name + ' has sent you an invoice for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '. <a href="'+ CONVERT(VARCHAR(MAX),@ViewInvoice) + '">View Invoice</a>'   AS  message_subject 
						    , a.first_name + ' ' + a.last_name + ' has sent you an invoice for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '. <a href="'+ CONVERT(VARCHAR(MAX),@ViewInvoice) + '">View Invoice</a>'   AS  message_descr
							, @todays_date AS message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts AS to_contact_id   ---buyer contact id
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author
						FROM mp_contacts(NOLOCK) a
						WHERE contact_id = @from_contact

					SET @identity_msg = @@identity
					--declare @InvNumber varchar (100)='INV-01',@InvAmount varchar (100)='199.99', @InvDueDate varchar(50) = '2023-04-07'
								
					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber))  AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '##INVOICENUMBER##' ,CONVERT(VARCHAR(100),@InvNumber)),' ##INVOICEAMOUNT##',CONVERT(VARCHAR(100),@InvAmount)),'##INVOICEDATE##',CONVERT(VARCHAR(100),@InvDueDate)),'#Buyer_Name#',@ToBuyer),'#VIEWINVOICE#',@ViewInvoice) ,'#STRIPELINK#',@ViewInvoice) AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---supplier contact id
							, @to_contacts  AS to_contact_id   ---buyer contact id
							, @ToBuyerEmail as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) b 
					WHERE  b.contact_id = @to_contacts
					AND b.is_notify_by_email = 1  /* M2-4789*/

					SET @identity = @@identity
					 					
					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						 
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id

						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY a.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, a.first_name + ' ' + a.last_name + ' has sent you an invoice for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '. View Invoice' AS  message_subject 
								, a.first_name + ' ' + a.last_name + ' has sent you an invoice for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + '. View Invoice' AS message_body
								, REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@email_msg_body, '##INVOICENUMBER##' ,CONVERT(VARCHAR(100),@InvNumber)),' ##INVOICEAMOUNT##',CONVERT(VARCHAR(100),@InvAmount)),'##INVOICEDATE##',CONVERT(VARCHAR(100),@InvDueDate)),'#Buyer_Name#',@ToBuyer) ,'#VIEWINVOICE#',@ViewInvoice),'#STRIPELINK#',@ViewInvoice) AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, a.first_name + ' ' + a.last_name AS from_username
								, NULL from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, @ToBuyer AS to_username
								, @ToBuyerEmail AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) a  
							WHERE  a.contact_id = @from_contact
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
					ELSE
					BEGIN
						SET @processStatus = 'FAILUER'

						SELECT 
							'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
							, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
							, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
							, '' AS to_email_id, 0 AS message_sent
							, '' AS message_subject , '' AS message_body
							, '' AS email_message_id , '' AS message_id
							, '' AS message_type
					END

				 
					 
		 END
		  /*M2-4900*/
		 ELSE IF  @message_type in( 'MANUFACTURER_EMAIL_NOTIFICATION_ON_EDITED_PO')   -- 250
		 BEGIN
		
				    SELECT @poMfgUniqueId  = Id , @poTransactionId   = TransactionId , @PONumber = PONumber
					FROM mpOrderManagement (NOLOCK) WHERE RfqId =  @rfq_id AND IsDeleted = 0
			
					SELECT 
						@ToBuyer = b.first_name +' '+ b.last_name
					   ,@ToBuyerEmail = c.email
					FROM mp_contacts (NOLOCK) b 
					JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
					WHERE b.contact_id = @to_contacts
			 		
					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					SELECT  
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, 'PO # '+CONVERT(VARCHAR(50),@PONumber) + ' for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' has been updated' AS  message_subject 
						    , 'PO # '+CONVERT(VARCHAR(50),@PONumber) + ' for RFQ # '+CONVERT(VARCHAR(50),@rfq_id) + ' has been updated' AS message_descr
							, @todays_date AS message_date
							, @from_contact AS from_contact_id   ---- buyer contact id 
							, @to_contacts  AS to_contact_id     ---- supplier contact id
							, 0 AS message_sent
							, 0 AS message_read
							, 0 AS trash
							, 0 AS from_trash
							, 0 AS real_from_cont_id
							, 0 AS is_last_message
							, 0 AS message_status_id_recipient
							, 0 AS message_status_id_author

					SET @identity_msg = @@identity
								
					INSERT INTO mp_email_messages 
					( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email
					, message_sent,message_read )
					OUTPUT inserted.email_message_id INTO @notification_email_running_id
					SELECT 
							@rfq_id rfq_id
							, @message_type_id  message_type_id 
							, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)),'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id)) AS email_msg_subject 
							, REPLACE(REPLACE(REPLACE(@email_msg_body , '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) ,'#Manufacturer_Contact_name#',a.first_name +' '+ a.last_name), '#Company_Name#', @company) AS email_message_descr
							, @todays_date  AS email_message_date
							, @from_contact AS from_contact_id ---buyer contact id 
							, @to_contacts  AS to_contact_id   ---supplier contact id
							, @ToBuyerEmail as to_email_id
							, 0 AS message_sent
							, 0 AS message_read
					FROM mp_contacts (NOLOCK) a 
					WHERE  a.contact_id = @to_contacts
					AND a.is_notify_by_email = 1  /* M2-4789*/

				 	SET @identity = @@identity
					
					IF @identity> 0 or @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'
						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						 
						INSERT INTO #tmp_notification (id, email_message_id)
						SELECT * FROM @notification_email_running_id
						 
						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, NULL message_subject	, NULL message_body	,email_message_subject
						, CASE WHEN b.email_message_id is null THEN a.message_subject  ELSE a.email_msg_body END AS  email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY a.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, @rfq_id rfq_id
								, @message_type_id message_type_id
								, REPLACE(REPLACE(@msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)),'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id))  AS  message_subject 
								, REPLACE(REPLACE(@msg_body, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)),'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id))  AS message_body
								, REPLACE(REPLACE(@email_msg_subject, '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)),'##RFQNO##', CONVERT(VARCHAR(100),@rfq_id)) AS  email_message_subject 
								, REPLACE(REPLACE(REPLACE(@email_msg_body , '##ORDERNO##' ,CONVERT(VARCHAR(100),@PONumber)) ,'#Manufacturer_Contact_name#',a.first_name +' '+ a.last_name), '#Company_Name#', @company) AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, a.first_name + ' ' + a.last_name AS from_username
								, NULL from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, @ToBuyer AS to_username
								, @ToBuyerEmail AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) a  
							WHERE  a.contact_id = @to_contacts
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
					ELSE
					BEGIN
						SET @processStatus = 'FAILUER'

						SELECT 
							'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
							, '' AS email_message_date, '' AS from_contact_id, '' AS from_username
							, '' AS from_user_contactimage, '' AS to_contact_id, '' AS to_username
							, '' AS to_email_id, 0 AS message_sent
							, '' AS message_subject , '' AS message_body
							, '' AS email_message_id , '' AS message_id
							, '' AS message_type
					END

				 
					 
		 END
		  /*M2-5023*/ 
		 ELSE IF  @message_type in( 'BUYER_NOTIFICATION_AFTER_AWARD_DATE_PASSES')   -- 251
		 BEGIN
					/* Fetch records into temp table */
					SELECT DISTINCT a.rfq_id, a.contact_id
					INTO #tmpPassRFQAwardDateList
					FROM mp_rfq(nolock) a
					JOIN mp_rfq_quote_SupplierQuote (NOLOCK) b on a.rfq_id = b.rfq_id
					JOIN mp_rfq_quote_items (NOLOCK) c ON c.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
					JOIN mp_rfq_part_quantity (NOLOCK) d ON d.rfq_part_id = c.rfq_part_id 
							AND c.rfq_part_quantity_id = d.rfq_part_quantity_id
					JOIN mp_contacts(NOLOCK) e on e.contact_id = a.contact_id
					WHERE a.contact_id = @to_contacts
					AND b.is_quote_submitted = 1
					AND a.rfq_status_id = 3
					----AND award_date BETWEEN  e.BuyerLastAwardingNotificationDate  AND DATEADD(DAY,DATEDIFF(DAY, 0, GETUTCDATE()),CAST('23:59:59.000' AS DATETIME)) 
					AND CAST(award_date AS DATE) BETWEEN  CAST(e.BuyerLastAwardingNotificationDate AS DATE)
									AND CAST(GETUTCDATE() AS DATE) 
					AND NOT EXISTS 
					( 
						SELECT b.rfq_id 
						FROM mp_messages(NOLOCK) b
						WHERE b.rfq_id = a.rfq_id
						AND  b.message_type_id = 251
						AND b.to_cont = a.contact_id
						
					)


					INSERT INTO mp_messages
					( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
					OUTPUT inserted.message_id INTO @notification_message_running_id
					SELECT DISTINCT
					a.rfq_id rfq_id
					, 251  message_type_id 
					, 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),a.rfq_id)  + ' has reached its award date.' AS message_subject
				    , 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),a.rfq_id)  + ' has reached its award date. Please update the award status of this RFQ.' AS   message_descr
					, @todays_date AS message_date
					, NULL from_contact_id 
					, a.contact_id as to_contact_id 
					, 0 AS message_sent
					, 0 AS message_read
					, 0 AS trash
					, 0 AS from_trash
					, 0 AS real_from_cont_id
					, 0 AS is_last_message
					, 0 AS message_status_id_recipient
					, 0 AS message_status_id_author
					FROM #tmpPassRFQAwardDateList a

					SET @identity_msg = @@identity
														 					
					IF  @identity_msg > 0
					BEGIN
						SET @processStatus = 'SUCCESS'

						UPDATE mp_contacts
						SET BuyerLastAwardingNotificationDate = @todays_date
						FROM mp_contacts(NOLOCK) 
						WHERE contact_id = @to_contacts

						
						INSERT INTO #tmp_notification (id, message_id)
						SELECT * FROM @notification_message_running_id
						 						

						SELECT a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id,  message_subject	,  message_body	,email_message_subject
						,    email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
						,to_email_id		,message_sent 		,message_type
						FROM 
						(
							SELECT
								ROW_NUMBER() OVER (ORDER BY a.contact_id )  id
								, @processStatus processStatus 
								, @identity email_message_id 
								, @identity_msg message_id
								, b.rfq_id rfq_id
								, @message_type_id message_type_id
								, 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),b.rfq_id)  + ' has reached its award date.' AS  message_subject 
								, 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),b.rfq_id)  + ' has reached its award date. Please update the award status of this RFQ.' AS message_body
								, 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),b.rfq_id)  + ' has reached its award date.' AS  email_message_subject 
								, 'Time to award! RFQ # ' + CONVERT(VARCHAR(15),b.rfq_id)  + ' has reached its award date. Please update the award status of this RFQ.' AS email_msg_body
								, @todays_date email_message_date
								, @to_contacts rfq_contact_id
								, a.first_name + ' ' + a.last_name AS from_username
								, NULL from_user_contactimage
								, @to_contacts AS to_contact_id   ---buyer contact id
								, a.first_name + ' ' + a.last_name  AS to_username
								, c.Email AS to_email_id
								, 0 AS message_sent
								, @message_type message_type
							FROM mp_contacts (NOLOCK) a  
							JOIN #tmpPassRFQAwardDateList b on a.contact_id = b.contact_id
							JOIN aspnetusers (NOLOCK) c on a.[user_id] = c.id 
							WHERE  a.contact_id = @to_contacts
						)
						 a
						join #tmp_notification b on a.id = b.id

												
				END --1
					ELSE
					BEGIN
						
						---- here if no notification records getting than still sending SUCCESS to API
						set @processStatus = 'SUCCESS'
						select 
						@processStatus processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type


					END
					 
		 END
		 ELSE IF @message_type = 'user.verification'
		 BEGIN
		 	----- Retun data into JSON format 
		
			SELECT REPLACE(REPLACE(JsonData,'[',''),']','') AS ResponseJSON
			FROM 
			(
				SELECT 
				(
					SELECT 
						  app
						, event_type
						, [user_id]
						, email_address   
						, (SELECT  EmailVerifyParam
							FROM #tmpJsonInputParameters FOR JSON AUTO 
						  ) AS template_data  
					FROM #tmpJsonInputParameters FOR JSON AUTO , WITHOUT_ARRAY_WRAPPER 
				) AS JsonData
			) ResponseJSON
			 
		 END --1
		 --ELSE 
		 --BEGIN
			--SET @processStatus = 'FAILUER'
				 
			--SELECT 
			--		@processStatus processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
			--		, '' as email_message_date, '' as from_contact_id, '' as from_username
			--		, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
			--		, '' as to_email_id, 0 as message_sent
			--		, '' as message_subject , '' as message_body
			--		, '' email_message_id , '' message_id
			--		, ''  message_type
		 --END  
	     ELSE IF @message_type = 'ApprovedEmail'
	     BEGIN 
			-- FirstName ,LinkToTheProfile
			------- Retun data into JSON format 
			SELECT REPLACE(REPLACE(JsonData,'[',''),']','') AS ResponseJSON
			FROM 
			(
					SELECT  
					(
							SELECT 
								  app
								, event_type
								, [user_id]
								, email_address   
								, (SELECT  FirstName,LinkToTheProfile
									FROM #tmpJsonInputParameters FOR JSON AUTO  
								  ) AS template_data   
							FROM #tmpJsonInputParameters FOR JSON AUTO , WITHOUT_ARRAY_WRAPPER 
					) AS JsonData
			) ResponseJSON

		 
		 END

		 ELSE IF @message_type IN ( 'BuyerPressedCallOnProfileEmail' ,'BuyerPressedCallOnProfileEmail','BuyerViewedYourProfileEmail')
	     BEGIN 
		 
			-- Supplier_Name ,LeadStreamDeepLink,SourcingAdvisor,SourcingAdvisorDesignation,SourcingAdvisorNo
			----- Retun data into JSON format
			SELECT REPLACE(REPLACE(JsonData,'[',''),']','') AS ResponseJSON
			FROM 
			(
				SELECT 
				(
					SELECT 
						  app
						, event_type
						, [user_id]
						, email_address   
						,( SELECT 
							 a.first_name + ' ' + a.last_name			AS SourcingAdvisor
							, a.title									AS SourcingAdvisorDesignation
							, CAST( b.PhoneNumber AS VARCHAR(100))		AS SourcingAdvisorNo 
							, CAST( SourcingAdvisor.Supplier_Name		AS VARCHAR(100)) AS [Supplier_Name]
							, CAST( SourcingAdvisor.LeadStreamDeepLink  AS VARCHAR(100)) AS [LeadStreamDeepLink]  
							FROM mp_contacts (NOLOCK) a
							JOIN 
							(   
								SELECT 
								  c.Assigned_SourcingAdvisor  
								, a.FirstName AS [Supplier_Name] 
								, a.LeadStreamDeepLink
								FROM #tmpJsonInputParameters  a
								JOIN mp_contacts(NOLOCK) b ON b.contact_id = a.[user_id]
								JOIN mp_companies(NOLOCK) c ON c.company_id = b.company_id
							) SourcingAdvisor  ON SourcingAdvisor.Assigned_SourcingAdvisor = a.contact_id
							JOIN AspNetUsers(NOLOCK) b on b.id = a.[user_id] FOR JSON AUTO  
						) AS template_data
					FROM #tmpJsonInputParameters FOR JSON AUTO , WITHOUT_ARRAY_WRAPPER 
				) AS JsonData
			) ResponseJSON
			 
			 
		 END

	 



	end try
	begin catch

		select 
						'FAILUER: '+ error_message()  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
						, '' as email_message_date, '' as from_contact_id, '' as from_username
						, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
						, '' as to_email_id, 0 as message_sent
						, '' as message_subject , '' as message_body
						, '' email_message_id , '' message_id
						, ''  message_type

	end catch


	drop table if exists #list_of_admin_contacts_as_per_companies_for_email
	drop table if exists #companies_for_rfq
	drop table if exists #list_of_to_contacts_for_messages_notification
	drop table if exists #tmp_notification
	drop table if exists #tmp_part_awarded
	drop table if exists #list_of_to_contacts_for_messages_notification1
	drop table if exists #list_of_to_contacts_for_messages_notification_freemsg
	drop table if exists #MessageFileTable 
	drop table if exists #SpecialFileIdTable
	drop table if exists #RfqPreferredLocations
	drop table if exists #RfqPartCapabilities
	drop table if exists #SupplierManufacturingLocation
	drop table if exists #SupplierWithMatchingCapabilitiesAndManufacturingLocation
	drop table if exists #tmpPassRFQAwardDateList



end
