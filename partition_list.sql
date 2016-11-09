select o.name, i.name
	,case
		when p.index_id = 0 then 'heap'
		when p.index_id = 1 then 'clustered index'
		else 'non clustered index'
	end dataType
	,fg.name [filegroup], fg.type_desc [filegroup_type], p.data_compression_desc [compression]
	,au.type_desc unit_type
	,au.total_pages, au.used_pages, au.data_pages, p.rows
from sys.allocation_units au
	join sys.filegroups fg on au.data_space_id = fg.data_space_id
	join sys.partitions p on (p.hobt_id = au.container_id and au.type in (1, 3)) or (p.partition_id = au.container_id and au.type = 2)
	join sys.objects o on p.object_id = o.object_id
	join sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
where o.type = 'U'