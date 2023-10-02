CREATE TABLE [dbo].[mp_rfq_release_closed_date_range] (
    [RFQId]            INT  NULL,
    [FirstReleaseDate] DATE NULL,
    [ClosedDate]       DATE NULL,
    [RFQDateRange]     DATE NULL,
    [UniqueSuppliers]  INT  DEFAULT ((0)) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_release_closed_date_range_RFQId_RFQDateRange]
    ON [dbo].[mp_rfq_release_closed_date_range]([RFQId] ASC, [RFQDateRange] ASC) WITH (FILLFACTOR = 90);

