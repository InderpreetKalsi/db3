CREATE TABLE [dbo].[mp_mst_geocode_data] (
    [geocode_id] INT            IDENTITY (1, 1) NOT NULL,
    [zipcode]    NVARCHAR (100) NULL,
    [latitude]   FLOAT (53)     NULL,
    [longitude]  FLOAT (53)     NULL,
    [country]    VARCHAR (50)   NULL,
    [state]      VARCHAR (50)   NULL,
    [city]       VARCHAR (50)   NULL,
    [country_Id] INT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([geocode_id] ASC) WITH (FILLFACTOR = 90)
);

