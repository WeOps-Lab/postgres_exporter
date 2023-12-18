## 嘉为蓝鲸postgreSQL插件使用说明

## 使用说明

### 插件功能

采集器会连接数据库并查询数据库中的 pg_stat_* 等视图，获取关于数据库的统计信息。收集的指标包括:

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


| **参数名**                     | **含义**                          | **是否必填** | **使用举例**                  |
|-----------------------------|---------------------------------|----------|---------------------------|
| DATA_SOURCE_HOST            | 数据库主机IP(环境变量)                   | 是        | 127.0.0.1                 |
| DATA_SOURCE_PORT            | 数据库服务端口(环境变量)                   | 是        | 5432                      |
| DATA_SOURCE_USER            | 数据库用户名(环境变量)                    | 是        | postgres                  |
| DATA_SOURCE_PASS            | 数据库密码(环境变量)                     | 是        |                           |
| DATA_SOURCE_DB              | 数据库库名(环境变量)                     | 是        | postgres                  |
| --collector.postmaster      | postmaster采集器开关(开关参数)，默认关闭      | 否        |                           |
| --collector.stat_statements | stat_statements采集器开关(开关参数)，默认关闭 | 否        |                           |
| --collector.stat_statements | stat_statements采集器开关(开关参数)，默认关闭 | 否        |                           |
| --collector.xlog_location   | xlog_location采集器开关(开关参数)，默认关闭   | 否        |                           |
| --log.level                 | 日志级别                            | 否        | info                      |
| --web.listen-address        | exporter监听id及端口地址               | 否        | 127.0.0.1:9601            |
| additional                  | 额外参数，可留空内容                      | 否        | --disable-default-metrics |

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
| pg_up                                        | PostgreSQL监控插件运行状态          | -                                                             | -                           | -      |
| pg_static                                    | PostgreSQL静态信息              | server_label, short_version                                   | 服务器, 短版本号                   | -      |
| pg_postmaster_start_time_seconds             | PostgreSQL启动时间戳             | -                                                             | -                           | s      |
| pg_stat_activity_max_tx_duration             | PostgreSQL最长事务持续时间          | application_name, datname, server_label, state, usename       | 应用名称, 数据库名称, 服务器, 状态, 用户名   | ms     |
| pg_stat_activity_count                       | PostgreSQL活动连接数             | application_name, datname, server_label, state, usename       | 应用名称, 数据库名称, 服务器, 状态, 用户名   | -      |
| pg_stat_archiver_archived_count              | PostgreSQL归档计数              | server_label                                                  | 服务器                         | -      |
| pg_stat_archiver_failed_count                | PostgreSQL归档失败计数            | server_label                                                  | 服务器                         | -      |
| pg_stat_archiver_last_archive_age            | PostgreSQL距离上一次归档时长         | server_label                                                  | 服务器                         | s      |
| pg_database_size_bytes                       | PostgreSQL数据库大小             | datname                                                       | 数据库名称                       | bytes  |
| pg_stat_database_temp_bytes                  | PostgreSQL临时文件大小            | datid, datname                                                | 数据库ID, 数据库名称                | bytes  |
| pg_locks_count                               | PostgreSQL锁数量               | datname, mode                                                 | 数据库名称, 锁模式                  | -      |
| pg_stat_database_deadlocks                   | PostgreSQL死锁数量              | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_bgwriter_buffers_alloc_total         | PostgreSQL后台写入器缓冲区分配总数      | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_backend_total       | PostgreSQL后台写入器缓冲区总数        | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_backend_fsync_total | PostgreSQL后台写入器 fsync 缓冲区总数 | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_checkpoint_total    | PostgreSQL后台写入器检查点缓冲区总数     | -                                                             | -                           | -      |
| pg_stat_bgwriter_buffers_clean_total         | PostgreSQL后台写入器清理缓冲区总数      | -                                                             | -                           | -      |
| pg_stat_bgwriter_checkpoint_sync_time_total  | PostgreSQL检查点同步时间总数         | -                                                             | -                           | ms     |
| pg_stat_bgwriter_checkpoint_write_time_total | PostgreSQL检查点写入时间总数         | -                                                             | -                           | ms     |
| pg_stat_database_blks_hit                    | PostgreSQL数据库缓存命中数          | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_blks_read                   | PostgreSQL数据库磁盘读取数          | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_conflicts                   | PostgreSQL数据库冲突数            | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_numbackends                 | PostgreSQL数据库后端数            | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_tup_deleted                 | PostgreSQL数据库删除行数           | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_tup_fetched                 | PostgreSQL数据库获取行数           | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_tup_inserted                | PostgreSQL数据库插入行数           | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_tup_returned                | PostgreSQL数据库返回行数           | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_tup_updated                 | PostgreSQL数据库更新行数           | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_long_running_transactions                 | PostgreSQL长时间运行事务数量         | -                                                             | -                           | -      |
| pg_stat_database_xact_commit                 | PostgreSQL数据库事务提交数          | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_database_xact_rollback               | PostgreSQL数据库事务回滚数          | datid, datname                                                | 数据库ID, 数据库名称                | -      |
| pg_stat_statements_calls_total               | PostgreSQL查询执行的总次数          | datname, queryid, user                                        | 数据库名称, 查询ID, 用户名            | -      |
| pg_stat_statements_seconds_total             | PostgreSQL查询总执行时间           | datname, queryid, user                                        | 数据库名称, 查询ID, 数据库角色名称, 服务器   | s      |
| pg_stat_statements_rows_total                | PostgreSQL查询行数统计            | datname, queryid, user                                        | 数据库名称, 查询ID, 用户名            | -      |
| pg_stat_statements_block_read_seconds_total  | PostgreSQL从磁盘读取块的总时间        | datname, queryid, user                                        | 数据库名称, 查询ID, 用户名            | s      |
| pg_stat_statements_block_write_seconds_total | PostgreSQL写入块到磁盘的总时间        | datname, queryid, user                                        | 数据库名称, 查询ID, 用户名            | s      |
| pg_replication_lag_seconds                   | PostgreSQL复制延迟              | -                                                             | -                           | s      |
| pg_stat_replication_reply_time               | PostgreSQL复制的响应时间戳          | application_name, client_addr, server_label, slot_name, state | 应用名称, 客户端地址, 服务器, 复制槽名称, 状态 | s      |
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

### 版本日志

#### weops_postgres_exporter 3.1.2

- weops调整

#### weops_postgres_exporter 3.1.3

- DSN拆分
- 隐藏敏感参数
- process类监控指标中文名更正

#### weops_postgres_exporter 3.1.4

- 去除文件参数和自定义文件的采集方式
- up指标中文名更正
- 部分指标维度去除server_label
- pg_stat_statements_类指标优化
- 增加采集器类开关，优化性能
- 部分指标单位由ms更改为s

添加“小嘉”微信即可获取postgres监控指标最佳实践礼包，其他更多问题欢迎咨询

<img src="https://wedoc.canway.net/imgs/img/小嘉.jpg" width="50%" height="50%">
