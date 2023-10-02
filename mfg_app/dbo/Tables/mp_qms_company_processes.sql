CREATE TABLE [dbo].[mp_qms_company_processes] (
    [qms_company_process_id] INT IDENTITY (1, 1) NOT NULL,
    [supplier_company_id]    INT NOT NULL,
    [qms_process_id]         INT NOT NULL,
    CONSTRAINT [PK_mp_qms_company_processes] PRIMARY KEY CLUSTERED ([qms_company_process_id] ASC, [supplier_company_id] ASC, [qms_process_id] ASC) WITH (FILLFACTOR = 90)
);

