CREATE TABLE [dbo].[mp_admin_user] (
    [admin_user_id]        INT            IDENTITY (1, 1) NOT NULL,
    [user_phone]           NVARCHAR (100) NULL,
    [title]                NVARCHAR (500) NULL,
    [is_sales_manager]     BIT            NOT NULL,
    [is_prod_manager]      BIT            NOT NULL,
    [is_for_buyer]         BIT            NOT NULL,
    [is_for_supplier]      BIT            NOT NULL,
    [parent_admin_user_id] INT            NOT NULL,
    [is_active]            BIT            NOT NULL,
    [creation_date]        DATETIME       NOT NULL,
    [modification_date]    DATETIME       NOT NULL,
    [Id]                   NVARCHAR (900) NOT NULL,
    CONSTRAINT [PK_mp_admin_user] PRIMARY KEY CLUSTERED ([admin_user_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is a linked id to aspnetusers table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_admin_user', @level2type = N'COLUMN', @level2name = N'Id';

