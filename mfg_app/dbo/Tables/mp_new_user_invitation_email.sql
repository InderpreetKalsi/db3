CREATE TABLE [dbo].[mp_new_user_invitation_email] (
    [id]              INT            IDENTITY (1, 1) NOT NULL,
    [from_user_email] VARCHAR (250)  NOT NULL,
    [from_contact_id] INT            NOT NULL,
    [company_id]      INT            NOT NULL,
    [to_email]        VARCHAR (250)  NOT NULL,
    [first_name]      NVARCHAR (100) NULL,
    [last_name]       NVARCHAR (100) NULL,
    [is_buyer]        BIT            NOT NULL,
    [is_supplier]     BIT            NOT NULL,
    [is_admin]        BIT            NULL,
    [message]         NVARCHAR (MAX) NULL,
    [encrypted_token] NVARCHAR (MAX) NOT NULL,
    [is_used]         BIT            NULL,
    [created_date]    DATETIME       DEFAULT (getdate()) NULL,
    [modified_date]   DATETIME       NULL,
    CONSTRAINT [pk_mp_new_user_invitation_email_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

