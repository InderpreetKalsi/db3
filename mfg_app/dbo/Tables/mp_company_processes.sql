CREATE TABLE [dbo].[mp_company_processes] (
    [company_id]       INT NOT NULL,
    [part_category_id] INT NOT NULL,
    [id]               INT IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_mp_company_processes] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_processes_mp_companies] FOREIGN KEY ([company_id]) REFERENCES [dbo].[mp_Companies] ([company_id]) NOT FOR REPLICATION,
    CONSTRAINT [FK_mp_company_processes_mp_mst_part_category] FOREIGN KEY ([part_category_id]) REFERENCES [dbo].[mp_mst_part_category] ([part_category_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_company_processes_Company_id]
    ON [dbo].[mp_company_processes]([company_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_company_processes_part_category_id_company_id]
    ON [dbo].[mp_company_processes]([part_category_id] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);

