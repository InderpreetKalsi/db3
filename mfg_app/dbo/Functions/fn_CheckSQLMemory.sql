CREATE FUNCTION dbo.fn_CheckSQLMemory()
RETURNS @Sql_MemStatus TABLE 
 (
   SQLServer_Start_DateTime datetime, 
   SQL_current_Memory_usage_mb int,
   SQL_Max_Memory_target_mb int,
   OS_Total_Memory_mb int,
   OS_Available_Memory_mb int)
AS
BEGIN
   declare @strtSQL datetime
   declare @currmem int
   declare @smaxmem int
   declare @osmaxmm int
   declare @osavlmm int 
 
   -- SQL memory
   SELECT 
      @strtSQL = sqlserver_start_time,
      @currmem = (committed_kb/1024),
      @smaxmem = (committed_target_kb/1024)           
   FROM sys.dm_os_sys_info;
   
   --OS memory
   SELECT 
      @osmaxmm = (total_physical_memory_kb/1024),
      @osavlmm = (available_physical_memory_kb/1024) 
   FROM sys.dm_os_sys_memory;
   
   INSERT INTO @Sql_MemStatus values (@strtSQL, @currmem, @smaxmem, @osmaxmm, @osavlmm)
 
   RETURN 
END
