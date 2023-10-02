CREATE TABLE [dbo].[mp_mst_employees_count_range] (
    [employee_count_range_id] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [range]                   NVARCHAR (25) NULL,
    CONSTRAINT [PK_mp_employees_count_range] PRIMARY KEY CLUSTERED ([employee_count_range_id] ASC) WITH (FILLFACTOR = 90)
);

