CREATE TABLE [dbo].[mp_company_equipments] (
    [company_equipments_id] INT      IDENTITY (1, 1) NOT NULL,
    [company_id]            INT      NOT NULL,
    [equipment_ID]          INT      NOT NULL,
    [contact_id]            INT      NULL,
    [status_id]             SMALLINT NULL,
    CONSTRAINT [PK_mp_company_equipments] PRIMARY KEY CLUSTERED ([company_equipments_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_equipments_mp_companies] FOREIGN KEY ([company_id]) REFERENCES [dbo].[mp_Companies] ([company_id]),
    CONSTRAINT [FK_mp_company_equipments_mp_mst_equipment] FOREIGN KEY ([equipment_ID]) REFERENCES [dbo].[mp_mst_equipment] ([equipment_Id])
);

