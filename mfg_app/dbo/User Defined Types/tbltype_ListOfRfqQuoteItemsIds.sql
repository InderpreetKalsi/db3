CREATE TYPE [dbo].[tbltype_ListOfRfqQuoteItemsIds] AS TABLE (
    [RfqQuoteItemsId] INT             NULL,
    [RfqPartId]       INT             NULL,
    [IsRfqStatus]     BIT             NULL,
    [PartStatusId]    INT             NULL,
    [Unit]            NUMERIC (18, 2) NULL,
    [Price]           NUMERIC (18, 4) NULL,
    [UnitTypeId]      INT             NULL);

