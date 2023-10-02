CREATE TABLE [dbo].[mp_crypt_method] (
    [crypt_method_id]   INT           IDENTITY (1, 1) NOT NULL,
    [crypt_method_name] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_mp_crypt_method] PRIMARY KEY CLUSTERED ([crypt_method_id] ASC) WITH (FILLFACTOR = 90)
);

