CREATE TABLE [dbo].[mpStoredProcedureLogicTracking] (
    [Id]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [ObjectName]    VARCHAR (250) NOT NULL,
    [ExecutionDate] DATETIME      DEFAULT (getutcdate()) NULL,
    [ObjectValues]  VARCHAR (MAX) DEFAULT ('') NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCI_mpStoredProcedureLogicTracking_ObjectName_Id]
    ON [dbo].[mpStoredProcedureLogicTracking]([ObjectName] ASC, [Id] ASC);

