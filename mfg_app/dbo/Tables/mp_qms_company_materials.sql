CREATE TABLE [dbo].[mp_qms_company_materials] (
    [qms_company_material_id] INT IDENTITY (1, 1) NOT NULL,
    [supplier_company_id]     INT NOT NULL,
    [qms_material_id]         INT NOT NULL,
    CONSTRAINT [PK_mp_qms_company_materials] PRIMARY KEY CLUSTERED ([qms_company_material_id] ASC, [supplier_company_id] ASC, [qms_material_id] ASC) WITH (FILLFACTOR = 90)
);

