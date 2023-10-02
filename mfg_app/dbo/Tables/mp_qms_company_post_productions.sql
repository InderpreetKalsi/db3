CREATE TABLE [dbo].[mp_qms_company_post_productions] (
    [qms_company_post_production_id] INT IDENTITY (1, 1) NOT NULL,
    [supplier_company_id]            INT NOT NULL,
    [qms_post_production_id]         INT NOT NULL,
    CONSTRAINT [PK_mp_qms_company_post_productions] PRIMARY KEY CLUSTERED ([qms_company_post_production_id] ASC, [supplier_company_id] ASC, [qms_post_production_id] ASC) WITH (FILLFACTOR = 90)
);

