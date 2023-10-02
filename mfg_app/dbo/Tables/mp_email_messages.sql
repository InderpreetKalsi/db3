CREATE TABLE [dbo].[mp_email_messages] (
    [email_message_id]        INT            IDENTITY (1, 1) NOT NULL,
    [rfq_id]                  INT            NULL,
    [message_type_id]         SMALLINT       NULL,
    [email_message_hierarchy] INT            NULL,
    [email_message_subject]   NVARCHAR (200) NULL,
    [email_message_descr]     NVARCHAR (MAX) NULL,
    [email_message_date]      DATETIME       NOT NULL,
    [from_cont]               INT            NULL,
    [to_cont]                 INT            NULL,
    [to_email]                VARCHAR (250)  NULL,
    [message_sent]            BIT            NOT NULL,
    [message_read]            BIT            NOT NULL,
    [read_date]               DATETIME       NULL,
    [FILE_NAME]               NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_mp_email_messages] PRIMARY KEY CLUSTERED ([email_message_id] ASC) WITH (FILLFACTOR = 90)
);

