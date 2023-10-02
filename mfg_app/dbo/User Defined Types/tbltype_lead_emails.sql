CREATE TYPE [dbo].[tbltype_lead_emails] AS TABLE (
    [first_name]      VARCHAR (150)  NULL,
    [last_name]       VARCHAR (150)  NULL,
    [company]         VARCHAR (250)  NULL,
    [email]           VARCHAR (150)  NULL,
    [phoneno]         VARCHAR (50)   NULL,
    [email_subject]   VARCHAR (250)  NULL,
    [email_message]   VARCHAR (1100) NULL,
    [files]           VARCHAR (2000) NULL,
    [is_nda_required] BIT            DEFAULT ((0)) NULL);

