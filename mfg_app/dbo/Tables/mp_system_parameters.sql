CREATE TABLE [dbo].[mp_system_parameters] (
    [id]                      INT            IDENTITY (1, 1) NOT NULL,
    [sys_key]                 NVARCHAR (100) NOT NULL,
    [value]                   NVARCHAR (100) NOT NULL,
    [description]             NVARCHAR (150) NOT NULL,
    [parent]                  INT            NULL,
    [active]                  BIT            NOT NULL,
    [sort_order]              SMALLINT       NOT NULL,
    [Actual_ID_fromSource_DB] INT            NULL,
    CONSTRAINT [PK_mp_system_parameters] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_system_parameters_mp_system_parameters] FOREIGN KEY ([parent]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Maintain system parameters required in the system', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_system_parameters';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Key for filtering the specific set of values', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_system_parameters', @level2type = N'COLUMN', @level2name = N'sys_key';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'sort order for the value ideally it should be like 10,20,30,40...', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_system_parameters', @level2type = N'COLUMN', @level2name = N'sort_order';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This column will be used for holding original ID from source database if data imported from it. This column can be remove after migrating all the data from original system.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_system_parameters', @level2type = N'COLUMN', @level2name = N'Actual_ID_fromSource_DB';

