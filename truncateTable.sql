declare tableCursor cursor local forward_only read_only for
with relations as
(
	select row_number() over (order by t.object_id) number
		,t.object_id id 
		,fk.parentId 
		,'[' + db_name() + '].[' + s.name + '].[' + t.name + ']' name
		,fk.referenceColumn
		,fk.name foreignKey
		,fk.parentName
		,fk.parentColumn
		,fk.deleteDefinition
		,fk.updateDefinition
	from sys.tables t
		join sys.schemas s on s.schema_id = t.schema_id
		outer apply 
		(
			select 
				fk.name, 
				'[' + db_name() + '].[' + s.name + '].[' + pt.name + ']' parentName, 
				pc.name parentColumn, 
				fkc.parent_object_id parentId, 
				'[' + db_name() + '].[' + s.name + '].[' + rt.name + ']' referenceTable, 
				rc.name referenceColumn, 
				fkc.referenced_object_id referenceId,
				case
					when fk.update_referential_action = 0 then 'no action'
					when fk.update_referential_action = 1 then 'cascade'
					when fk.update_referential_action = 2 then 'set null'
					when fk.update_referential_action = 3 then 'set default'
					else ''
				end updateDefinition,
				case
					when fk.delete_referential_action = 0 then 'no action'
					when fk.delete_referential_action = 1 then 'cascade'
					when fk.delete_referential_action = 2 then 'set null'
					when fk.delete_referential_action = 3 then 'set default'
					else ''
				end deleteDefinition
			from sys.foreign_keys fk
				join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
				join sys.tables pt on pt.object_id = fkc.parent_object_id
				join sys.columns pc on pc.column_id = fkc.parent_column_id and pc.object_id = fkc.parent_object_id
				join sys.tables rt on rt.object_id = fkc.referenced_object_id
				join sys.columns rc on rc.column_id = fkc.referenced_column_id and rc.object_id = fkc.referenced_object_id
			where t.object_id = fkc.referenced_object_id
		) fk
)
, cte as 
(
	select r.id, r.parentId, r.name, r.referenceColumn, r.foreignKey, r.parentName, r.parentColumn, r.deleteDefinition, r.updateDefinition, 0 lev
	from relations r
	where parentId is null or (r.parentId = r.id and not exists (select 1 from relations r1 where r1.id = r.id and r1.number <> r.number))

	union all

	select r.id, r.parentId, r.name, r.referenceColumn, r.foreignKey, r.parentName, r.parentColumn, r.deleteDefinition, r.updateDefinition,c.lev + 1 lev 
	from cte c 
		join relations r on r.ParentId = c.Id
	where r.ParentId != r.Id
)
select distinct 
	r.name
	,scripts.dropScript
	,scripts.createScript
	,t.lev
from cte r
	cross apply (
		select max(lev) lev
		from cte c
		where r.Id = c.Id
		group by c.Id
	) t
	outer apply (
		select 
			replace((
				select distinct 'alter table '+ s.parentName +' drop constraint ['+s.foreignKey + '];'
				from cte s 
				where s.id = r.id 
				for xml path('')
			), ';', char(13) + char(10)) dropScript
			,replace((
				select distinct 'alter table ' + s.parentName + ' add constraint [' + s.foreignKey + ']' + ' foreign key ([' + s.parentColumn + '])' + ' references ' + s.name + '([' + s.referenceColumn + '])' + ' on delete ' + s.deleteDefinition + ' on update ' + s.updateDefinition +';'
				from cte s 
				where s.id = r.id 
				for xml path('')
			), ';', char(13) + char(10)) createScript
	) scripts
order by t.lev

declare @tableName varchar(max)
declare @dropForeignKeys varchar(max)
declare @createForeignKeys varchar(max)
declare @level int

open tableCursor

fetch next from tableCursor
into @tableName, @dropForeignKeys, @createForeignKeys, @level

while @@fetch_status <> -1
begin
	print @tableName
	print @dropForeignKeys
	print 'truncate table ' + @tableName
	print @createForeignKeys

	exec(@dropForeignKeys)
	exec ('truncate table ' + @tableName)
	exec(@createForeignKeys)

	fetch next from tableCursor
	into @tableName, @dropForeignKeys, @createForeignKeys, @level
end

