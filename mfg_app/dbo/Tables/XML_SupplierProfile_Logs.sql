CREATE TABLE [dbo].[XML_SupplierProfile_Logs] (
    [Id]                    INT           IDENTITY (1, 1) NOT NULL,
    [Action]                VARCHAR (150) NULL,
    [DBObject]              VARCHAR (250) NULL,
    [RecordProcessed]       INT           DEFAULT ((0)) NULL,
    [Status]                VARCHAR (150) NULL,
    [Error]                 VARCHAR (MAX) NULL,
    [ErrorDateTime]         DATETIME      NULL,
    [SuccessDateTime]       DATETIME      NULL,
    [CreatedOn]             DATETIME      DEFAULT (getutcdate()) NULL,
    [FetchDataFromDateTime] DATETIME      NULL,
    [FetchDataToDateTime]   DATETIME      NULL,
    CONSTRAINT [PK_XML_SupplierProfile_Logs_Id_CreatedOn] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);

