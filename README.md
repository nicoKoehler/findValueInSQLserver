# Finding a Value in an entire SQL Server
*Note that this script may take a long time and may impact server performance. 
Execute with caution and only if you truely understand what the script is doing.*

## Files
#### Published Version
-> Includes generic Table placeholders for results and history
-> Tables are defined as 
```
CREATE TABLE [stat].[scan_TablesScanned](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[searchTerm] [nvarchar](max) NULL,
	[dbName] [nvarchar](max) NULL,
	[schemaTable] [nvarchar](max) NULL,
	[execDate] [datetime] NULL,
	[searchDescription] [nvarchar](max) NULL
) 

CREATE TABLE [stat].[scan_results](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[searchTerm] [nvarchar](max) NULL,
	[dbName] [nvarchar](max) NULL,
	[schemaTable] [nvarchar](max) NULL,
	[columnName] [nvarchar](max) NULL,
	[nbrOfHits] [nvarchar](max) NULL,
	[execDate] [datetime] NULL
)
```

## PseudoCode
> Set search term
> While there are tables in the system master database
> 	select minimum database that is greater than the last table name processed
>
>> While there are tables in that Database
>>	select minimum table that is greater than the last table name processed from Information_schema
>
>> While there are columns in that table
>>   	select minimum column that is greater than the last table name processed from Information_schema
>>   
>>> Check if the column matches the search criteria
>>>	If success, log the database, table and field to table
>
> Print out table
 
 
 ## Specifics
 + not data type specific, which increases runtime, but avoids missing values. If you know exactly the data type of potential match columns, enable data type filters
 + uses sp_executesql to utilize parameters in search criteria
 
 
 ## Measured Performance 
 #### Run-1
 + Database Size: 19.75 GB (w/o Logs)
 + Runtime: 16.8 minutes
 
 #### Run-2
 + Database Size: 2.87 GB (w/o Logs)
 + Runtime: 2.3 minutes
        
 Linear search time: ~ 1.3 minutes per GB
 Database size estimated using the query:
  
```
select
  sdb.name
  , smf.size * 8.0 / (1024*1024) as sizeInMB -- multiplication by 8 necessary as sql value represents nbr of 8KB pages
from sys.databases sdb
left join sys.master_files smf
	on smf.database_id = sdb.database_id
```
          
