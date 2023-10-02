CREATE TABLE [dbo].[mp_lead_emails] (
    [lead_email_message_id] INT            IDENTITY (1000, 1) NOT NULL,
    [first_name]            VARCHAR (150)  NULL,
    [last_name]             VARCHAR (150)  NULL,
    [company]               VARCHAR (250)  NULL,
    [email]                 VARCHAR (150)  NULL,
    [phoneno]               VARCHAR (50)   NULL,
    [email_subject]         VARCHAR (250)  NULL,
    [email_message]         VARCHAR (1100) NULL,
    CONSTRAINT [PK_mp_lead_emails_lead_email_message_id] PRIMARY KEY CLUSTERED ([lead_email_message_id] ASC) WITH (FILLFACTOR = 90)
);

