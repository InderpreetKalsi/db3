CREATE TABLE [dbo].[mp_mst_message_status] (
    [message_status_id]        SMALLINT       IDENTITY (1, 1) NOT NULL,
    [message_status_token]     VARCHAR (100)  NOT NULL,
    [message_type_id]          SMALLINT       NOT NULL,
    [message_status_target_id] SMALLINT       NOT NULL,
    [message_status_token_EN]  NVARCHAR (150) NULL,
    CONSTRAINT [PK_mp_mst_message_status] PRIMARY KEY CLUSTERED ([message_status_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_message_status_mp_mst_message_types] FOREIGN KEY ([message_type_id]) REFERENCES [dbo].[mp_mst_message_types] ([message_type_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_mst_message_types table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_message_status', @level2type = N'COLUMN', @level2name = N'message_type_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'defines who the status is to be showed to : undefined (-1) , supplier (0) , buyer (1), buyer and supplier (2)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_message_status', @level2type = N'COLUMN', @level2name = N'message_status_target_id';

