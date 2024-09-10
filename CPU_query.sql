-- High CPU queries (that are either finished or still running)
--
if  object_id ('tempdb.dbo.#query_stats') is not null drop table #query_stats
select getdate() runtime, * into #query_stats from

(SELECT query_stats.query_hash,   
    SUM(query_stats.total_worker_time) 'total_worker_time',
	SUM(query_stats.execution_count) 'execution_count',
	sum(total_logical_reads) 'total_logical_reads',
    REPLACE (REPLACE (MIN(query_stats.statement_text),  CHAR(10), ' '), CHAR(13), ' ') AS "Statement_Text"  
FROM   
    (SELECT QS.*,   
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
    ((CASE statement_end_offset   
        WHEN -1 THEN DATALENGTH(ST.text)  
        ELSE QS.statement_end_offset END   
            - QS.statement_start_offset)/2) + 1) AS statement_text  
     FROM sys.dm_exec_query_stats AS QS  
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats  
	 group by query_hash) t

	 while 1 = 1
	 begin

	 waitfor delay '0:5:0'
	insert into #query_stats select getdate() runtime, * from
	(SELECT query_stats.query_hash,   
    SUM(query_stats.total_worker_time) 'total_worker_time',
	SUM(query_stats.execution_count) 'execution_count',
	sum(total_logical_reads) 'total_logical_reads',
    REPLACE (REPLACE (MIN(query_stats.statement_text),  CHAR(10), ' '), CHAR(13), ' ') AS "Statement_Text"  
	FROM   
		(SELECT QS.*,   
		SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
		((CASE statement_end_offset   
        WHEN -1 THEN DATALENGTH(ST.text)  
        ELSE QS.statement_end_offset END   
            - QS.statement_start_offset)/2) + 1) AS statement_text  
     FROM sys.dm_exec_query_stats AS QS  
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats  
	 group by query_hash) t
	 print 'For the past 5 minutes, the following are top 10 CPU consuming queries.  Stats are captured for finished queries only.  For Running queries, see next snapshot'
	 print '--High CPU Queries (Delta)--' 
	 select  top 10 t2.runtime, t2.query_hash,
	 cast((t2.total_worker_time - (case when t1.total_worker_time is null then 0 else t1.total_worker_time end)  )/1000.00 as bigint) 'Total_Worker_Time_Ms',
	 (t2.total_logical_reads - (case when t1.total_logical_reads is null then 0 else t1.total_logical_reads end)  ) 'Total_Logical_Reads',
	 (t2.execution_count - (case when t1.execution_count is null then 0 else t1.execution_count end)  ) 'Total_Execution_Count',
	 t2.Statement_Text
	 from
	(select * from #query_stats  where runtime = (select max(runtime) from #query_stats)) t2
	left join 
	(select * from #query_stats  where runtime = (select min(runtime) from #query_stats)) t1
	on t2.query_hash=t1.query_hash
	order by (t2.total_worker_time - (case when t1.total_worker_time is null then 0 else t1.total_worker_time end) ) desc
	RAISERROR (' ', 0, 1) WITH NOWAIT

	print 'The following are top 10 CPU consuming queries that have not finished running at the time of this snapshot capture'
	print '--Active CPU Consuming Queries--' 
	SELECT top 10 getdate() runtime, query_hash,   
		cpu_time ,
		logical_reads ,
		start_time ,
		substring (REPLACE (REPLACE ((txt.text),  CHAR(10), ' '), CHAR(13), ' '), 1, 256) AS "Statement_Text"  
		from sys.dm_exec_requests req
		cross apply sys.dm_exec_sql_text(req.sql_handle) txt
		order by cpu_time desc


	 RAISERROR (' ', 0, 1) WITH NOWAIT
	 delete #query_stats where runtime < (select max(runtime) from #query_stats)
	 end
