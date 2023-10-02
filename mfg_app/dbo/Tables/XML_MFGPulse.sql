CREATE TABLE [dbo].[XML_MFGPulse] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [Enclosure]   VARCHAR (2000) NULL,
    [Title]       VARCHAR (150)  NULL,
    [Link]        VARCHAR (250)  NULL,
    [Description] VARCHAR (1000) NULL,
    [RecordDate]  DATETIME       NULL,
    [CreatedDate] DATETIME2 (7)  NULL,
    CONSTRAINT [PK_MFGPulseXML] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_MFGPulseXML_CreatedDate]
    ON [dbo].[XML_MFGPulse]([CreatedDate] ASC) WITH (FILLFACTOR = 90);

