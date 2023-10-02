CREATE TABLE [dbo].[mp_qms_quote_part_certificates] (
    [qms_quote_part_certificate_id] INT      IDENTITY (1, 1) NOT NULL,
    [qms_quote_part_id]             INT      NOT NULL,
    [certificate_id]                INT      NOT NULL,
    [creation_date]                 DATETIME DEFAULT (getutcdate()) NULL,
    [created_by]                    INT      NULL,
    CONSTRAINT [PK_mp_qms_quote_part_certificates] PRIMARY KEY CLUSTERED ([qms_quote_part_id] ASC, [qms_quote_part_certificate_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_part_certificates_mp_qms_quote_parts] FOREIGN KEY ([qms_quote_part_id]) REFERENCES [dbo].[mp_qms_quote_parts] ([qms_quote_part_id]) ON DELETE CASCADE ON UPDATE CASCADE
);

