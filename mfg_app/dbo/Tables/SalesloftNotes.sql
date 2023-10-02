CREATE TABLE [dbo].[SalesloftNotes] (
    [salesloft_notes_id] INT            IDENTITY (1, 1) NOT NULL,
    [id]                 INT            NOT NULL,
    [content]            VARCHAR (5000) NULL,
    [created_at]         DATETIME       NULL,
    [updated_at]         DATETIME       NULL,
    [user_id]            INT            NULL,
    [associated_with_id] INT            NULL,
    [call_id]            INT            NULL,
    [is_processed]       BIT            NULL,
    CONSTRAINT [PK_SalesloftNotes_Salesloft_Notes_Id] PRIMARY KEY CLUSTERED ([salesloft_notes_id] ASC)
);

