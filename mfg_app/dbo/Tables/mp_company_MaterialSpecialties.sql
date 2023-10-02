CREATE TABLE [dbo].[mp_company_MaterialSpecialties] (
    [company_MaterialSpecialties_id] INT      IDENTITY (1, 1) NOT NULL,
    [Company_id]                     INT      NOT NULL,
    [Material_id]                    SMALLINT NOT NULL,
    CONSTRAINT [PK_mp_company_MaterialSpecialties] PRIMARY KEY CLUSTERED ([company_MaterialSpecialties_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_MaterialSpecialties_mp_companies] FOREIGN KEY ([Company_id]) REFERENCES [dbo].[mp_Companies] ([company_id]),
    CONSTRAINT [FK_mp_company_MaterialSpecialties_mp_mst_materials] FOREIGN KEY ([Material_id]) REFERENCES [dbo].[mp_mst_materials] ([material_id])
);

