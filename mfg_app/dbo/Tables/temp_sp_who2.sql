CREATE TABLE [dbo].[temp_sp_who2] (
    [SPID]        INT            NULL,
    [Status]      VARCHAR (1000) NULL,
    [Login]       [sysname]      NULL,
    [HostName]    [sysname]      NULL,
    [BlkBy]       [sysname]      NULL,
    [DBName]      [sysname]      NULL,
    [Command]     VARCHAR (1000) NULL,
    [CPUTime]     INT            NULL,
    [DiskIO]      BIGINT         NULL,
    [LastBatch]   VARCHAR (1000) NULL,
    [ProgramName] VARCHAR (1000) NULL,
    [SPID2]       INT            NULL,
    [RequestId]   INT            NULL
);

