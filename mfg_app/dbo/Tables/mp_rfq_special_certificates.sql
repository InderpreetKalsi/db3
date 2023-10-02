CREATE TABLE [dbo].[mp_rfq_special_certificates] (
    [rfq_special_certificates_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                      INT      NULL,
    [certificate_id]              INT      NULL,
    [creation_date]               DATETIME NULL,
    [ModifiedBy]                  INT      NULL,
    CONSTRAINT [PK_mp_rfq_special_certificates] PRIMARY KEY CLUSTERED ([rfq_special_certificates_id] ASC) WITH (FILLFACTOR = 90)
);

