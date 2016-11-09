use TestDB

if exists (select * from sys.sysfiles where name = 'TestDB_messages_queue')
	alter database TestDB remove file TestDB_messages_queue
if exists (select * from sys.filegroups where name = 'fg_memory_optimized')
	alter database TestDB remove filegroup fg_memory_optimized
go

alter database TestDB 
	add filegroup fg_memory_optimized contains memory_optimized_data
print '- added memory optimized filegroup fg_messages_queue;'
alter database TestDB 
	add file (name='fg_memory_optimized', filename='c:\data\f_memory_optimized') 
	to filegroup fg_memory_optimized
print '- added file c:\data\f_memory_optimized to filegroup fg_memory_optimized'
go

if exists (select * from sys.filegroups where name = 'fg_messages_log')
	alter database TestDB remove filegroup fg_messages_log
alter database TestDB add filegroup fg_messages_log
go
if exists (select * from sys.sysfiles where name = 'TestDB_messages_log')
	alter database TestDB remove file TestDB_messages_log
alter database TestDB 
add file (name='TestDB_messages_log', filename='C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\TestDB_messages_log.mdf')
to filegroup fg_messages_log
go
if exists (select * from sys.partition_functions where name = 'pf_messages_state')
	drop partition function pf_messages_state
--create partition function pf_messages_state(tinyint) as range left for values (0, 1)
go
if exists (select * from sys.partition_schemes where name = 'ps_messages')
	drop partition scheme ps_messages
--create partition scheme ps_messages as partition pf_messages_state to (fg_messages_queue, fg_messages_queue, fg_messages_log)
go

if object_id('messages_stats') is not null
	drop table messages_stats
if object_id('messages_log') is not null
	drop table messages_log
if object_id('messages') is not null
	drop table messages

create table messages (
	id int not null					-- message id
		primary key clustered identity(1,1),

	-- constant fields
	text nvarchar(255) not null,	-- message text
	target varchar(20) not null,	-- target contact id
	source varchar(20) not null,	-- source contact id
	gateway int						-- gateway which send message
		index ix_messages_gateway nonclustered,		
	created datetime not null		-- creation date
		default(getdate()),

	-- updated fields
	status tinyint			-- processing status
		not null default(0),-- (0 - wait, 1 - ready, 2 - sending, 3 - sent)
	attempt tinyint			-- sending attempts count
		not null default(0),
	result tinyint,			-- sending result 
							-- (success = 0, not valid destination = 1, not valid source = 2, error = 3)
	updated datetime,		-- last update date
) on ps_messages(status)
go
-- index for processing messages
create nonclustered index ix_messages_queue on messages(status) 
include(text, target, source, gateway) where status in (0, 1)
on fg_messages_queue
go

create table messages_log (
	id int not null				-- log id
		primary key clustered,
	messageId int not null		-- message id
		foreign key references messages(id),
	time datetime not null,		-- last message update
	operation tinyint not null,	-- operation type (0 - created, 1 - updated, 2 - deleted)
	gateway int,				-- gateway which send message

	status tinyint,
	result tinyint,
	attempt tinyint,

	index ix_messages_log_message_id_time nonclustered (messageId, time desc)
)

create table messages_stats (
	gateway int not null primary key clustered,

	status_0_count int default(0),
	status_1_count int default(0),
	-- status_2_count int, ignore status

	result_0_count int default(0),
	result_1_count int default(0),
	result_2_count int default(0),
	result_3_count int default(0)
)
go

