CREATE TABLE [dbo].[mp_zoho_subscriptions_customerportal_sso_login_securitykey_logs] (
    [id]                   INT           IDENTITY (1, 1) NOT NULL,
    [contact_id]           INT           NOT NULL,
    [dynamic_security_key] VARCHAR (255) NOT NULL,
    [created_datetime]     DATETIME      NOT NULL,
    [is_used]              BIT           NULL,
    [used_datetime]        DATETIME      NULL,
    CONSTRAINT [PK_mp_zoho_subscriptions_customerportal_sso_login_securitykey_logs] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

