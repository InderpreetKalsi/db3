CREATE TABLE [dbo].[mp_user_reset_password_logs] (
    [user_reset_password_log_id] INT      IDENTITY (1, 1) NOT NULL,
    [contact_id]                 INT      NOT NULL,
    [reset_date]                 DATETIME DEFAULT (getutcdate()) NULL,
    [is_reset_from_vision]       BIT      DEFAULT ((0)) NULL,
    [vision_user_id]             INT      NULL,
    [is_password_reset]          BIT      DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([user_reset_password_log_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [NC_mp_user_reset_password_logs_contact_id_user_reset_password_log_id]
    ON [dbo].[mp_user_reset_password_logs]([contact_id] ASC, [user_reset_password_log_id] ASC) WITH (FILLFACTOR = 90);

