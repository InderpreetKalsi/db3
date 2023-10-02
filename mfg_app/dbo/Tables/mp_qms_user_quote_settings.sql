CREATE TABLE [dbo].[mp_qms_user_quote_settings] (
    [qms_user_quote_setting_id] INT IDENTITY (1, 1) NOT NULL,
    [contact_id]                INT NOT NULL,
    [qms_quote_setting_id]      INT NOT NULL,
    [default_value]             INT NULL,
    PRIMARY KEY CLUSTERED ([qms_user_quote_setting_id] ASC, [contact_id] ASC, [qms_quote_setting_id] ASC) WITH (FILLFACTOR = 90)
);

