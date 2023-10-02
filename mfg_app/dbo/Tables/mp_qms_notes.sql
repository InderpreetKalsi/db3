CREATE TABLE [dbo].[mp_qms_notes] (
    [qms_note_id]             INT            IDENTITY (1, 1) NOT NULL,
    [supplier_contact_id]     INT            NOT NULL,
    [qms_quote_id]            INT            NOT NULL,
    [qms_notes_title]         NVARCHAR (250) NULL,
    [qms_notes]               NVARCHAR (MAX) NULL,
    [qms_notes_date]          DATETIME       CONSTRAINT [DF__mp_qms_no__qms_n__6D15245A] DEFAULT (getutcdate()) NULL,
    [is_hidden]               BIT            CONSTRAINT [DF__mp_qms_no__is_hi__6E094893] DEFAULT ((0)) NOT NULL,
    [qms_notes_modified_date] DATETIME       NULL,
    CONSTRAINT [pk_mp_qms_notes] PRIMARY KEY CLUSTERED ([qms_note_id] ASC, [qms_quote_id] ASC) WITH (FILLFACTOR = 90)
);

