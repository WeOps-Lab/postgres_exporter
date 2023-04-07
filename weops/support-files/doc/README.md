## 嘉为蓝鲸postgreSQL插件使用说明

## 使用说明

### 插件功能  
采集器会连接数据库并查询数据库中的 pg_stat_* 等视图，获取关于数据库的统计信息。  
收集的指标包括:
  - 数据库活动：活动连接数、空闲连接数、等待连接数等。
  - 事务：提交事务数、回滚事务数、长时间事务数等。
  - 锁：不同类型的锁数量。
  - 缓存：缓存命中率、缓存读取次数等。
  - 索引：索引扫描次数、索引大小等。
  - 序列：序列使用情况、序列空间使用情况等。
  - 表：表扫描次数、表行数、表大小等。
  - 背景写入器：检查点请求次数、缓冲区写入次数、脏缓冲区清理次数等。

实际收集的指标取决于数据库的配置和版本。

### 版本支持

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

PostgreSQL: `9.4`, `9.5`, `9.6`, `10`, `11`, `12`, `13`, `14`, `15`

**是否支持远程采集:**

是

### 参数说明

| **参数名**              | **含义**                                                               | **是否必填** | **使用举例**                                                           |
|----------------------|----------------------------------------------------------------------|----------|--------------------------------------------------------------------|
| DATA_SOURCE_NAME     | DSN参数，PostgreSQL数据源的环境变量，包括数据库地址、端口、数据库名、用户和密码等信息。 **注意！该参数为环境变量**   | 是        | postgresql://user:password@127.0.0.1:5432/postgres?sslmode=disable |
| --extend.query-path  | 自定义指标采集文件路径 **注意！该参数在平台层面为文件参数，进程中该参数值为采集配置文件路径(上传文件即可，平台会补充文件路径)！** | 是        | 上传内容满足规范的文件                                                        |
| --log.level          | 日志级别                                                                 | 否        | info                                                               |
| --web.listen-address | exporter监听id及端口地址                                                    | 否        | 127.0.0.1:9601                                                     |
| additional           | 额外参数，可留空内容                                                           | 否        | --disable-default-metrics                                          |

**注意**
一般连接的数据库名都需要填写为 `postgres`  

#### 额外参数说明
额外参数(additional)不需要赋值，只需要填写对应内容，作为采集器的功能或者采集指标的开关，postgreSQL插件支持的额外参数如下:
1. 不采集默认指标，只保留自定义指标采集文件中的指标   
    --disable-default-metrics
2. 不采集配置(Setting)类，pg_settings前缀开头的指标  
    --disable-settings-metrics
3. 不采集后台写入器(Bgwriter)类，pg_stat_bgwriter前缀开头的指标  
    --no-collector.bgwriter
4. 不采集复制槽信息，replication_slot前缀开头的指标  
    --no-collector.replication_slot

#### 自定义查询配置文件
使用自定义查询配置文件 (通过命令行参数 `--extend.query-path` 设置) 来采集自定义监控指标，下方是内置自定义查询文件的内容:
```yaml
pg_postmaster:  # 指标名前缀，该项下查询得到的指标都会有该前缀名
  query: "SELECT pg_postmaster_start_time as start_time_seconds from pg_postmaster_start_time()"  # 指标对应执行的sql查询语句
  master: true  # 这个参数是一个布尔值，设置这个查询是否应该只在主节点上执行。如果为true，则查询只在主节点上执行，否则在所有节点上执行。
  metrics:  # 指标列表，定义了要公开的指标名称和相应的监控类型
    - start_time_seconds:  # 指标名
        usage: "GAUGE"  # 指标类型
        description: "Time at which postmaster started"  # 指标描述
        
pg_replication:
  query: "SELECT CASE WHEN NOT pg_is_in_recovery() THEN 0 ELSE GREATEST (0, EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))) END AS lag"
  master: true
  metrics:
    - lag:
        usage: "GAUGE"
        description: "Replication lag behind master in seconds"
        
pg_stat_statements:
  query: "SELECT t2.rolname, t3.datname, queryid, calls, ( total_plan_time + total_exec_time ) / 1000 as total_time_seconds, ( min_plan_time + min_exec_time ) / 1000 as min_time_seconds, ( max_plan_time + max_exec_time ) / 1000 as max_time_seconds, ( mean_plan_time + mean_exec_time ) / 1000 as mean_time_seconds, ( stddev_plan_time + stddev_exec_time )  / 1000 as stddev_time_seconds, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time / 1000 as blk_read_time_seconds, blk_write_time / 1000 as blk_write_time_seconds FROM pg_stat_statements t1 JOIN pg_roles t2 ON (t1.userid=t2.oid) JOIN pg_database t3 ON (t1.dbid=t3.oid) WHERE t2.rolname != 'rdsadmin' AND queryid IS NOT NULL"
  master: true
  metrics:
    - rolname:
        usage: "LABEL"
        description: "Name of user"
    - datname:
        usage: "LABEL"
        description: "Name of database"
    - queryid:
        usage: "LABEL"
        description: "Query ID"
    - calls:
        usage: "COUNTER"
        description: "Number of times executed"
    - total_time_seconds:
        usage: "COUNTER"
        description: "Total time spent in the statement, in milliseconds"
    - min_time_seconds:
        usage: "GAUGE"
        description: "Minimum time spent in the statement, in milliseconds"
    - max_time_seconds:
        usage: "GAUGE"
        description: "Maximum time spent in the statement, in milliseconds"
    - mean_time_seconds:
        usage: "GAUGE"
        description: "Mean time spent in the statement, in milliseconds"
    - stddev_time_seconds:
        usage: "GAUGE"
        description: "Population standard deviation of time spent in the statement, in milliseconds"
    - rows:
        usage: "COUNTER"
        description: "Total number of rows retrieved or affected by the statement"
    - shared_blks_hit:
        usage: "COUNTER"
        description: "Total number of shared block cache hits by the statement"
    - shared_blks_read:
        usage: "COUNTER"
        description: "Total number of shared blocks read by the statement"
    - shared_blks_dirtied:
        usage: "COUNTER"
        description: "Total number of shared blocks dirtied by the statement"
    - shared_blks_written:
        usage: "COUNTER"
        description: "Total number of shared blocks written by the statement"
    - local_blks_hit:
        usage: "COUNTER"
        description: "Total number of local block cache hits by the statement"
    - local_blks_read:
        usage: "COUNTER"
        description: "Total number of local blocks read by the statement"
    - local_blks_dirtied:
        usage: "COUNTER"
        description: "Total number of local blocks dirtied by the statement"
    - local_blks_written:
        usage: "COUNTER"
        description: "Total number of local blocks written by the statement"
    - temp_blks_read:
        usage: "COUNTER"
        description: "Total number of temp blocks read by the statement"
    - temp_blks_written:
        usage: "COUNTER"
        description: "Total number of temp blocks written by the statement"
    - blk_read_time_seconds:
        usage: "COUNTER"
        description: "Total time the statement spent reading blocks, in milliseconds (if track_io_timing is enabled, otherwise zero)"
    - blk_write_time_seconds:
        usage: "COUNTER"
        description: "Total time the statement spent writing blocks, in milliseconds (if track_io_timing is enabled, otherwise zero)"
```

### 使用指引

1. 连接Postgres数据库
   输入连接指令后输入对应的密码即可进入数据库。
    ```shell
    psql -U [user] -h [host] -p [port] -d [database]
    ```

2. 创建账户及授权  
    执行下方sql可以创建具有监控权限的账户，用户名 `weops`，密码 `Weops123!`。 **注意!** 数据库版本 >= 10才需要执行 `GRANT pg_monitor TO weops; `，9.x版本无法执行该授权。 
    ```sql
    CREATE OR REPLACE FUNCTION __tmp_create_user() returns void as $$
    BEGIN
      IF NOT EXISTS (
              SELECT                       -- SELECT list can stay empty for this
              FROM   pg_catalog.pg_user
              WHERE  usename = 'weops') THEN
        CREATE USER weops;
      END IF;
    END;
    $$ language plpgsql;

    SELECT __tmp_create_user();
    DROP FUNCTION __tmp_create_user();

    ALTER USER weops WITH PASSWORD 'Weops123!';
    ALTER USER weops SET SEARCH_PATH TO weops,pg_catalog;

    GRANT CONNECT ON DATABASE postgres TO weops;

    GRANT pg_monitor TO weops;  -- 数据库版本 >= 10 才需要执行这条sql
   
    CREATE SCHEMA IF NOT EXISTS weops;
    GRANT USAGE ON SCHEMA weops TO weops;

    CREATE OR REPLACE FUNCTION get_pg_stat_activity() RETURNS SETOF pg_stat_activity AS
    $$ SELECT * FROM pg_catalog.pg_stat_activity; $$
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW weops.pg_stat_activity
    AS
      SELECT * from get_pg_stat_activity();

    GRANT SELECT ON weops.pg_stat_activity TO weops;

    CREATE OR REPLACE FUNCTION get_pg_stat_replication() RETURNS SETOF pg_stat_replication AS
    $$ SELECT * FROM pg_catalog.pg_stat_replication; $$
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW weops.pg_stat_replication
    AS
      SELECT * FROM get_pg_stat_replication();

    GRANT SELECT ON weops.pg_stat_replication TO weops;

    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
    CREATE OR REPLACE FUNCTION get_pg_stat_statements() RETURNS SETOF pg_stat_statements AS
    $$ SELECT * FROM public.pg_stat_statements; $$
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW weops.pg_stat_statements
    AS
      SELECT * FROM get_pg_stat_statements();

    GRANT SELECT ON weops.pg_stat_statements TO weops; 
    ```

### 指标简介

| **指标ID**                                     | **指标中文名**                   | **维度ID**                                                      | **维度含义**                    | **单位** |
|----------------------------------------------|-----------------------------|---------------------------------------------------------------|-----------------------------|--------|
| pg_up                                        | PostgreSQL运行状态              | -                                                             | -                           | -      |
| pg_static                                    | PostgreSQL静态信息              | server_label, short_version                                   | 服务器, 短版本号                   | -      |
| pg_postmaster_start_time_seconds             | PostgreSQL启动时间戳             | server_label                                                  | 服务器                         | s      |
| pg_stat_activity_max_tx_duration             | PostgreSQL最长事务持续时间          | application_name, datname, server_label, state, usename       | 应用名称, 数据库名称, 服务器, 状态, 用户名   | ms     |
| pg_stat_activity_count                       | PostgreSQL活动连接数             | application_name, datname, server_label, state, usename       | 应用名称, 数据库名称, 服务器, 状态, 用户名   | -      |
| pg_stat_archiver_archived_count              | PostgreSQL归档计数              | server_label                                                  | 服务器                         | -      |
| pg_stat_archiver_failed_count                | PostgreSQL归档失败计数            | server_label                                                  | 服务器                         | -      |
| pg_stat_archiver_last_archive_age            | PostgreSQL距离上一次归档时长         | server_label                                                  | 服务器                         | s      |
| pg_database_size_bytes                       | PostgreSQL数据库大小             | datname                                                       | 数据库名称                       | bytes  |
| pg_stat_database_temp_bytes                  | PostgreSQL临时文件大小            | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | bytes  |
| pg_locks_count                               | PostgreSQL锁数量               | datname, mode, server_label                                   | 数据库名称, 锁模式, 服务器             | -      |
| pg_stat_database_deadlocks                   | PostgreSQL死锁数量              | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_bgwriter_buffers_alloc_total         | PostgreSQL后台写入器缓冲区分配总数      | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_backend_total       | PostgreSQL后台写入器缓冲区总数        | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_backend_fsync_total | PostgreSQL后台写入器 fsync 缓冲区总数 | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_checkpoint_total    | PostgreSQL后台写入器检查点缓冲区总数     | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_clean_total         | PostgreSQL后台写入器清理缓冲区总数      | -                                                             | -                           | -      |
| pg_stat_bgwriter_checkpoint_sync_time_total  | PostgreSQL检查点同步时间总数         | -                                                             | -                           | ms     |
| pg_stat_bgwriter_checkpoint_write_time_total | PostgreSQL检查点写入时间总数         | -                                                             | -                           | ms     |
| pg_stat_database_blks_hit                    | PostgreSQL数据库缓存命中数          | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_blks_read                   | PostgreSQL数据库磁盘读取数          | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_conflicts                   | PostgreSQL数据库冲突数            | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_numbackends                 | PostgreSQL数据库后端数            | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_tup_deleted                 | PostgreSQL数据库删除行数           | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_tup_fetched                 | PostgreSQL数据库获取行数           | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_tup_inserted                | PostgreSQL数据库插入行数           | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_tup_returned                | PostgreSQL数据库返回行数           | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_tup_updated                 | PostgreSQL数据库更新行数           | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_xact_commit                 | PostgreSQL数据库事务提交数          | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_database_xact_rollback               | PostgreSQL数据库事务回滚数          | datid, datname, server_label                                  | 数据库ID, 数据库名称, 服务器           | -      |
| pg_stat_statements_calls                     | PostgreSQL查询执行的总次数          | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_total_time_seconds        | PostgreSQL查询总执行时间           | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | ms     |
| pg_stat_statements_mean_time_seconds         | PostgreSQL平均每次查询执行时间        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | ms     |
| pg_stat_statements_rows                      | PostgreSQL查询行数统计            | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_shared_blks_hit           | PostgreSQL共享缓存块读取的次数        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_shared_blks_read          | PostgreSQL从磁盘读取的共享缓存块数量     | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_shared_blks_dirtied       | PostgreSQL共享缓存块修改的次数        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_shared_blks_written       | PostgreSQL共享缓存块被写入到磁盘的数量    | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_local_blks_hit            | PostgreSQL本地缓存块读取的次数        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_local_blks_read           | PostgreSQL从磁盘读取的本地缓存块数量     | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_local_blks_dirtied        | PostgreSQL本地缓存块修改的次数        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_local_blks_written        | PostgreSQL本地缓存块被写入到磁盘的数量    | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_temp_blks_read            | PostgreSQL从磁盘读取的临时缓存块数量     | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_temp_blks_written         | PostgreSQL写入到磁盘的临时缓存块数量     | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | -      |
| pg_stat_statements_blk_read_time_seconds     | PostgreSQL从磁盘读取块的总时间        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | ms     |
| pg_stat_statements_blk_write_time_seconds    | PostgreSQL写入块到磁盘的总时间        | datname, queryid, rolname, server_label                       | 数据库名称, 查询ID, 数据库角色名称, 服务器   | ms     |
| pg_replication_lag                           | PostgreSQL复制延迟              | server_label                                                  | 服务器                         | s      |
| pg_stat_replication_reply_time               | PostgreSQL复制的响应时间戳          | application_name, client_addr, server_label, slot_name, state | 应用名称, 客户端地址, 服务器, 复制槽名称, 状态 | s      |
| pg_replication_slots_active                  | PostgreSQL复制槽活动状态           | datname, server_label, slot_name                              | 数据库名称, 服务器, 复制槽名称           | -      |
| pg_replication_slots_pg_wal_lsn_diff         | PostgreSQL复制槽的WAL LSN差异     | datname, server_label, slot_name                              | 数据库名称, 服务器, 复制槽名称           | bytes  |
| pg_stat_replication_pg_current_wal_lsn_bytes | PostgreSQL当前WAL LSN大小       | application_name, client_addr, server_label, slot_name, state | 应用名称, 客户端地址, 服务器, 复制槽名称, 状态 | bytes  |
| pg_stat_replication_pg_wal_lsn_diff          | PostgreSQL复制的WAL LSN差异      | application_name, client_addr, server_label, slot_name, state | 应用名称, 客户端地址, 服务器, 复制槽名称, 状态 | bytes  |
| pg_stat_replication_pg_xlog_location_diff    | PostgreSQL的XLOG位置差异         | application_name, client_addr, server_label, slot_name, state | 应用名称, 客户端地址, 服务器, 复制槽名称, 状态 | bytes  |
| pg_settings_wal_recycle                      | PostgreSQL WAL 回收设置         | server_label                                                  | 服务器                         | -      |
| pg_settings_effective_cache_size_bytes       | PostgreSQL有效缓存大小            | server_label                                                  | 服务器                         | bytes  |
| pg_settings_maintenance_work_mem_bytes       | PostgreSQL维护工作内存大小          | server_label                                                  | 服务器                         | bytes  |
| pg_settings_work_mem_bytes                   | PostgreSQL工作内存大小            | server_label                                                  | 服务器                         | bytes  |
| pg_settings_shared_buffers_bytes             | PostgreSQL共享缓冲区大小           | server_label                                                  | 服务器                         | bytes  |
| pg_settings_max_wal_size_bytes               | PostgreSQL最大WAL大小           | server_label                                                  | 服务器                         | bytes  |
| pg_settings_min_wal_size_bytes               | PostgreSQL最小WAL大小           | server_label                                                  | 服务器                         | bytes  |
| pg_settings_max_parallel_workers             | PostgreSQL最大并行工作者数          | server_label                                                  | 服务器                         | -      |
| pg_settings_max_connections                  | PostgreSQL最大连接数             | server_label                                                  | 服务器                         | -      |
| pg_settings_superuser_reserved_connections   | PostgreSQL超级用户保留连接数         | server_label                                                  | 服务器                         | -      |
| pg_settings_max_wal_senders                  | PostgreSQL最大WAL发送者数         | server_label                                                  | 服务器                         | -      |
| pg_settings_max_worker_processes             | PostgreSQL最大工作进程数           | server_label                                                  | 服务器                         | -      |
| pg_settings_random_page_cost                 | PostgreSQL随机页消耗             | server_label                                                  | 服务器                         | -      |
| pg_settings_seq_page_cost                    | PostgreSQL顺序页消耗             | server_label                                                  | 服务器                         | -      |
| process_cpu_seconds_total                    | PostgreSQL进程 CPU 使用时间总量     | -                                                             | -                           | s      |
| process_resident_memory_bytes                | PostgreSQL进程占用的物理内存大小       | -                                                             | -                           | bytes  |
| process_virtual_memory_bytes                 | PostgreSQL进程占用的虚拟内存大小       | -                                                             | -                           | bytes  |
| process_open_fds                             | PostgreSQL进程打开的文件描述符数量      | -                                                             | -                           | -      |
| pg_exporter_last_scrape_duration_seconds     | PostgreSQL监控探针最近一次抓取时长      | -                                                             | -                           | s      |
| pg_exporter_scrapes_total                    | PostgreSQL监控探针采集总次数         | -                                                             | -                           | -      |
| pg_exporter_user_queries_load_error          | PostgreSQL监控探针自定义采集状态       | filename, hashsum                                             | 文件名, 哈希值                    | -      |



### 版本日志

#### weops_postgres_exporter 3.1.2

- weops调整

添加“小嘉”微信即可获取postgres监控指标最佳实践礼包，其他更多问题欢迎咨询

<img src="https://wedoc.canway.net/imgs/img/小嘉.jpg" width="50%" height="50%">
