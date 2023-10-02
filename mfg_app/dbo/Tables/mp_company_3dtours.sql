CREATE TABLE [dbo].[mp_company_3dtours] (
    [company_3dtour_id] INT             IDENTITY (1, 1) NOT NULL,
    [company_id]        INT             NULL,
    [3d_tour_url]       NVARCHAR (2000) NULL,
    [title]             VARCHAR (250)   NULL,
    [description]       VARCHAR (500)   NULL,
    [is_deleted]        BIT             DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([company_3dtour_id] ASC) WITH (FILLFACTOR = 90)
);

