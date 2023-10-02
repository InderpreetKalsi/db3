CREATE TABLE [dbo].[mp_supplier_profile_search_parameters_logs] (
    [Id]          INT              IDENTITY (1, 1) NOT NULL,
    [SearchId]    VARCHAR (250)    NULL,
    [Distance]    INT              NULL,
    [Longitude]   DECIMAL (18, 15) NULL,
    [Latitude]    DECIMAL (18, 15) NULL,
    [ProcessId]   INT              NULL,
    [MoreRecords] BIT              NULL,
    [PageSize]    INT              NULL,
    [PageNumber]  INT              NULL,
    [IPAddress]   VARCHAR (150)    NULL,
    [CreatedAt]   DATETIME         NULL,
    [Source]      VARCHAR (150)    NULL,
    [Type]        VARCHAR (150)    NULL,
    CONSTRAINT [PK_mp_supplier_profile_search_parameters_logs] PRIMARY KEY NONCLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE CLUSTERED INDEX [IX_mp_supplier_profile_search_parameters_logs_Id]
    ON [dbo].[mp_supplier_profile_search_parameters_logs]([Id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NIX_mp_supplier_profile_search_parameters_logs_Id]
    ON [dbo].[mp_supplier_profile_search_parameters_logs]([Longitude] ASC, [Latitude] ASC) WITH (FILLFACTOR = 90);

