CREATE TABLE [dbo].[mp_message_file] (
    [id]         INT    IDENTITY (1, 1) NOT NULL,
    [MESSAGE_ID] INT    NOT NULL,
    [FILE_ID]    BIGINT NOT NULL,
    CONSTRAINT [PK_mp_message_file] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

