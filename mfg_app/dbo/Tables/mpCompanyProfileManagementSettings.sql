CREATE TABLE [dbo].[mpCompanyProfileManagementSettings] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [CompanyId]       INT            NOT NULL,
    [ProfileSettings] VARCHAR (1000) NOT NULL,
    CONSTRAINT [pk_mpCompanyProfileManagementSettings_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [idx_mpCompanyProfileManagementSettings_CompanyId]
    ON [dbo].[mpCompanyProfileManagementSettings]([CompanyId] ASC) WITH (FILLFACTOR = 90);

