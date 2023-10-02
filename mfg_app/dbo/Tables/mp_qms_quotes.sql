CREATE TABLE [dbo].[mp_qms_quotes] (
    [qms_quote_id]            INT            IDENTITY (1, 1) NOT NULL,
    [quote_id]                INT            NULL,
    [qms_quote_name]          VARCHAR (500)  NULL,
    [qms_contact_id]          INT            NULL,
    [is_active]               BIT            CONSTRAINT [DF__mp_qms_qu__is_ac__41B297AD] DEFAULT ((1)) NOT NULL,
    [is_notified]             BIT            CONSTRAINT [DF_mp_qms_quotes_is_notified] DEFAULT ((0)) NULL,
    [status_id]               INT            NOT NULL,
    [email_status_id]         INT            CONSTRAINT [DF_mp_qms_quotes_email_status_id] DEFAULT ((6)) NULL,
    [probability]             INT            NULL,
    [quote_ref_no]            VARCHAR (250)  NULL,
    [payment_term_id]         INT            NULL,
    [estimated_delivery_date] DATETIME       NULL,
    [shipping_method_id]      INT            NULL,
    [quote_valid_until]       DATETIME       NULL,
    [notes]                   VARCHAR (1000) NULL,
    [created_by]              INT            NOT NULL,
    [created_date]            DATETIME       CONSTRAINT [DF__mp_qms_qu__creat__42A6BBE6] DEFAULT (getutcdate()) NOT NULL,
    [who_pays_for_shipping]   SMALLINT       NULL,
    CONSTRAINT [pk_mp_qms_quotes_qms_quote_id] PRIMARY KEY CLUSTERED ([qms_quote_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quotes_mp_qms_contacts] FOREIGN KEY ([qms_contact_id]) REFERENCES [dbo].[mp_qms_contacts] ([qms_contact_id])
);


GO

CREATE TRIGGER [dbo].[trg_set_qms_quote_id]
ON [dbo].[mp_qms_quotes]
AFTER INSERT AS
BEGIN
	DECLARE @qms_quote_id int 
	DECLARE @supplier_id int 

	SELECT @qms_quote_id = qms_quote_id , @supplier_id = created_by FROM INSERTED
	
	UPDATE A SET A.quote_id = B.quote_id
	FROM mp_qms_quotes A
	JOIN
	(
		SELECT @qms_quote_id AS qms_quote_id  , ISNULL(MAX(quote_id)+1,100) quote_id  
		FROM mp_qms_quotes (NOLOCK)
		WHERE created_by = @supplier_id
	) B ON A.qms_quote_id = B.qms_quote_id

END
