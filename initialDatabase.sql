set nocount on
go
if object_id('table1') is not null
	drop table table1
go
if object_id('table2') is not null
	drop table table2
go
if object_id('table3') is not null
	drop table table3
go
create table table1 (
	id int not null,
	ref int
)
go
create table table2 (
	id int not null,
	ref int
)
go
create table table3 (
	id int not null,
	ref int
)
go
alter table table1 add constraint pk_table1 primary key (id) 
go
alter table table2 add constraint pk_table2 primary key (id) 
go
alter table table3 add constraint pk_table3 primary key (id) 
go
alter table table1 add constraint fk_table1_table2 foreign key (ref) references table2(id) on update no action on delete cascade
go
alter table table2 add constraint fk_table2_table3 foreign key (ref) references table3(id) on update no action on delete no action
go
insert into table3 (id, ref)
values (1, 1), (2, 2), (3, 3), (4, 4)
insert into table2 (id, ref)
values (1, null), (2, 3), (3, 4), (4, null)
insert into table1 (id, ref)
values (1, null), (2, 3), (3, 4), (4, null)
go
	print '-------'
	print 'table1 => table2 => table3'
	print 'table1(ref) => table2(id), table2(ref) => table3(id)'
	print '-------'
	declare @tableString varchar(max)
	set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table1 for xml path('')),1,1,'')
	print 'table1:' + @tableString
	set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table2 for xml path('')),1,1,'')
	print 'table2:' + @tableString
	set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table3 for xml path('')),1,1,'')
	print 'table3:' + @tableString
go
begin
--	print '-------'
--	declare @tableString varchar(max)
--	begin try
--		print 'delete table2 = 1 (no references)'
--		delete from table2 where id = 1
--		print 'success'

--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table1 for xml path('')),1,1,'')
--		print 'table1:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table2 for xml path('')),1,1,'')
--		print 'table2:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table3 for xml path('')),1,1,'')
--		print 'table3:' + @tableString
--	end try
--	begin catch
--		print 'error '
--	end catch
--	print '-------'
--	begin try
--		print 'delete table2 = 2 (references table3)'
--		delete from table2 where id = 2
--		print 'success'

--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table1 for xml path('')),1,1,'')
--		print 'table1:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table2 for xml path('')),1,1,'')
--		print 'table2:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table3 for xml path('')),1,1,'')
--		print 'table3:' + @tableString
--	end try
--	begin catch
--		print 'error '
--	end catch
--	print '-------'
--	begin try
--		print 'delete table2 = 3 (references table3 and referenced by table1)'
--		delete from table2 where id = 3
--		print 'success'

--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table1 for xml path('')),1,1,'')
--		print 'table1:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table2 for xml path('')),1,1,'')
--		print 'table2:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table3 for xml path('')),1,1,'')
--		print 'table3:' + @tableString
--	end try
--	begin catch
--		print 'error '
--	end catch
--	print '-------'
--	begin try
--		print 'delete table2 = 4 (referenced by table1)'
--		delete from table2 where id = 4
--		print 'success'

--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table1 for xml path('')),1,1,'')
--		print 'table1:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table2 for xml path('')),1,1,'')
--		print 'table2:' + @tableString
--		set @tableString = stuff((select ',('+cast(id as varchar(10))+', '+isnull(cast(ref as varchar(10)),'n')+')' from table3 for xml path('')),1,1,'')
--		print 'table3:' + @tableString
--	end try
--	begin catch
--		print 'error '
--	end catch
	print '-------'
end
go
