CREATE TABLE [dbo].[mp_mst_roles] (
    [role_id]     SMALLINT     IDENTITY (1, 1) NOT NULL,
    [role_key]    VARCHAR (50) NOT NULL,
    [description] VARCHAR (50) NOT NULL,
    [is_buyer]    BIT          DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_mp_roles] PRIMARY KEY CLUSTERED ([role_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Store the list of role in the application', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_roles';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 - buyer role, 0 - supplier role', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_roles', @level2type = N'COLUMN', @level2name = N'is_buyer';

