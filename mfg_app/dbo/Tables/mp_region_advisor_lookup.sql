CREATE TABLE [dbo].[mp_region_advisor_lookup] (
    [region_id]         INT           NOT NULL,
    [region]            VARCHAR (150) NULL,
    [region_code]       CHAR (5)      NULL,
    [location]          VARCHAR (10)  NULL,
    [location_supplier] VARCHAR (10)  NULL,
    PRIMARY KEY CLUSTERED ([region_id] ASC) WITH (FILLFACTOR = 90)
);

