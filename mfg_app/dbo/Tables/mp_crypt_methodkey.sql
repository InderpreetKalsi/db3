CREATE TABLE [dbo].[mp_crypt_methodkey] (
    [crypt_methodkey_id]    INT           IDENTITY (1, 1) NOT NULL,
    [crypt_methodkey_value] VARCHAR (200) NOT NULL,
    [crypt_method_id]       INT           NOT NULL,
    [modification_date]     SMALLDATETIME NOT NULL,
    [status_id]             INT           NOT NULL,
    CONSTRAINT [PK_mp_crypt_methodkey] PRIMARY KEY CLUSTERED ([crypt_methodkey_id] ASC) WITH (FILLFACTOR = 90)
);

