CREATE TABLE [dbo].[mp_mst_activities] (
    [activity_id] INT           IDENTITY (1, 1) NOT NULL,
    [activity]    VARCHAR (250) NULL,
    [is_active]   BIT           DEFAULT ((1)) NULL,
    [created_on]  DATETIME      DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([activity_id] ASC) WITH (FILLFACTOR = 90)
);

