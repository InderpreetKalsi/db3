CREATE TABLE [dbo].[mp_company_supplier_types] (
    [company_supplier_types_id] INT IDENTITY (1, 1) NOT NULL,
    [company_id]                INT NOT NULL,
    [supplier_type_id]          INT NOT NULL,
    [is_buyer]                  BIT NULL,
    CONSTRAINT [PK_mp_company_supplier_types] PRIMARY KEY CLUSTERED ([company_supplier_types_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_supplier_types_mp_companies] FOREIGN KEY ([company_id]) REFERENCES [dbo].[mp_Companies] ([company_id])
);

