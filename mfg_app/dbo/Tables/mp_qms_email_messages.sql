CREATE TABLE [dbo].[mp_qms_email_messages] (
    [qms_email_message_id] INT            IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]         INT            NOT NULL,
    [qms_quote_invoice_id] INT            NULL,
    [email_subject]        NVARCHAR (500) NULL,
    [email_body]           NVARCHAR (MAX) NULL,
    [email_date]           DATETIME       NOT NULL,
    [from_cont]            INT            NULL,
    [to_cont]              INT            NULL,
    [to_email]             VARCHAR (250)  NULL,
    [email_sent]           BIT            DEFAULT ((0)) NOT NULL,
    [email_read]           BIT            DEFAULT ((0)) NOT NULL,
    [is_trash]             BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_mp_qms_email_messages] PRIMARY KEY CLUSTERED ([qms_email_message_id] ASC, [qms_quote_id] ASC) WITH (FILLFACTOR = 90)
);

