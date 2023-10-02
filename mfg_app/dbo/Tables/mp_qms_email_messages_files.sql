CREATE TABLE [dbo].[mp_qms_email_messages_files] (
    [mp_qms_email_messages_file_id] INT IDENTITY (1, 1) NOT NULL,
    [qms_email_message_id]          INT NOT NULL,
    [file_id]                       INT NOT NULL,
    CONSTRAINT [pk_mp_qms_email_messages_files] PRIMARY KEY CLUSTERED ([mp_qms_email_messages_file_id] ASC, [qms_email_message_id] ASC) WITH (FILLFACTOR = 90)
);

