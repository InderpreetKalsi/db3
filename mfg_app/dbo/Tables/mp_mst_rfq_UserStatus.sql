CREATE TABLE [dbo].[mp_mst_rfq_UserStatus] (
    [rfq_userStatus_id]          SMALLINT      IDENTITY (1, 1) NOT NULL,
    [rfq_userstatus_Li_key]      VARCHAR (200) NULL,
    [rfq_userstatus_description] VARCHAR (200) NULL,
    CONSTRAINT [PK_mp_mst_rfq_UserStatus] PRIMARY KEY CLUSTERED ([rfq_userStatus_id] ASC) WITH (FILLFACTOR = 90)
);

