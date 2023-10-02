CREATE TYPE [dbo].[tbltype_ImportQMSContacts] AS TABLE (
    [company]   VARCHAR (150) NULL,
    [firstname] VARCHAR (150) NULL,
    [lastname]  VARCHAR (150) NULL,
    [email]     VARCHAR (150) NULL,
    [phone]     VARCHAR (50)  NULL,
    [address]   VARCHAR (500) NULL,
    [city]      VARCHAR (150) NULL,
    [state]     VARCHAR (150) NULL,
    [country]   VARCHAR (150) NULL,
    [zipcode]   VARCHAR (50)  NULL);

