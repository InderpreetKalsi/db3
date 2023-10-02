CREATE TABLE [dbo].[mp_mst_email_template] (
    [email_template_id]        INT            IDENTITY (1, 1) NOT NULL,
    [message_type_id]          SMALLINT       NULL,
    [message_status_id]        SMALLINT       NULL,
    [message_subject_template] NVARCHAR (150) NULL,
    [message_body_template]    NVARCHAR (MAX) NULL,
    [email_subject_template]   NVARCHAR (150) NULL,
    [email_body_template]      NVARCHAR (MAX) NULL,
    [is_active]                BIT            NULL,
    CONSTRAINT [PK_mp_mst_email_template] PRIMARY KEY CLUSTERED ([email_template_id] ASC) WITH (FILLFACTOR = 90)
);

