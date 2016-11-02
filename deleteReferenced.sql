declare @batchCount int
declare @table varchar(128)
declare @column varchar(128)
declare @value sql_variant

select i.object_id, t.name, i.name, c.name, ic.index_column_id, i.is_primary_key
from sys.tables t
	join sys.indexes i on i.object_id = t.object_id
	join sys.index_columns ic on ic.object_id = i.object_id and ic.index_id = i.index_id
	join sys.columns c on c.object_id = ic.object_id and c.column_id = ic.column_id
where i.is_primary_key = 1

select distinct userId from TaxonomyOrganizationUsers

declare @select_ids table (id int not null)
declare @select_count int = 1
declare @user_ids table (id int not null, index pk_id clustered)

insert into @user_ids 
select distinct userId 
from TaxonomyOrganizationUsers 
where @select_count = 0 
	or id in (select id from @select_ids)

delete from Users 
where id in (select id from @user_ids)

