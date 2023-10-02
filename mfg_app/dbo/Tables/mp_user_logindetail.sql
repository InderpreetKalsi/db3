CREATE TABLE [dbo].[mp_user_logindetail] (
    [user_logindetail_id] INT            IDENTITY (1, 1) NOT NULL,
    [user_id]             NVARCHAR (900) NULL,
    [contact_id]          INT            NOT NULL,
    [login_datetime]      DATETIME       NOT NULL,
    [session_starttime]   DATETIME       NOT NULL,
    [session_endtime]     DATETIME       NULL,
    CONSTRAINT [PK_mp_user_logindetail] PRIMARY KEY CLUSTERED ([user_logindetail_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_user_logindetail]
    ON [dbo].[mp_user_logindetail]([contact_id] ASC, [login_datetime] ASC) WITH (FILLFACTOR = 90);

