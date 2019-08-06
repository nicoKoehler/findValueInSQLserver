DECLARE @SearchStr nvarchar(100)
SET @SearchStr = '329B0199'


if OBJECT_ID('tempdb..#Results') is not null
begin
	drop table #Results
end

CREATE TABLE #Results (ColumnName nvarchar(370), ColumnValue nvarchar(3630))
 
 
DECLARE @TableName nvarchar(max), @ColumnName nvarchar(max), @SearchStr2 nvarchar(110), @dbName nvarchar(max)
SET  @TableName = ''
SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')
set @dbName = ''
declare @from nvarchar(max) = ''
declare @tableTmp nvarchar(max)
declare @coltmp nvarchar(max) = ''
declare @countRes int = 0


print 'Start'

while @dbName is not null
begin
	set @TableName = ''
	set @dbName =
	(
	select MIN(QUOTENAME([name]))
	from master.sys.databases with (nolock)
	where QUOTENAME([name]) > @dbName
	and [name] = 'lake'
	)


	WHILE @dbName is not null and @TableName IS NOT NULL

	BEGIN
		set @from = @dbName+'.INFORMATION_SCHEMA.TABLES with (nolock)'

		SET @ColumnName = ''
		set @tableTmp = ''
		declare @sql nvarchar(max) =(N'SELECT @tableTmp = MIN(QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME)) 
								FROM '+@from+N' 
								WHERE TABLE_TYPE = ''BASE TABLE''
									AND    QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME) > @TableName
									AND    coalesce(OBJECTPROPERTY(
												OBJECT_ID(
													QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME)
													), ''IsMSShipped''), 0) = 0
													')
		

		exec sp_executesql @sql,N'@TableName nvarchar(max), @tableTmp nvarchar(max) OUTPUT' , @TableName=@TableName,@tableTmp=@TableName OUTPUT
		
		print @TableName
		
		WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
         
		BEGIN
			set @from = @dbName+'.INFORMATION_SCHEMA.COLUMNS with (nolock)'
			set @coltmp = ''
			declare @colSQL nvarchar(max) = N'SELECT @coltmp = MIN(QUOTENAME(COLUMN_NAME))
												FROM     '+@from+N'
												WHERE         TABLE_SCHEMA    = PARSENAME(@TableName, 2)
													AND    TABLE_NAME    = PARSENAME(@TableName, 1)
													AND    DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'', ''int'', ''decimal'')
													AND    QUOTENAME(COLUMN_NAME) > @ColumnName'
			

			exec sp_executesql @colSQL, N'@ColumnName nvarchar(max), @TableName nvarchar(max), @coltmp nvarchar(max) OUT', @TableName=@TableName, @ColumnName=@ColumnName, @coltmp=@ColumnName OUT
			

			--GOTO Theend
			
 
			IF @ColumnName IS NOT NULL
			
			BEGIN
				set @countRes = 0
				print '---------------------------------'


				declare @searchSQL nvarchar(max) = N' SELECT @countRes = count(*) FROM '+@from+' where @ColumName = @SearchStr2'
					
				exec sp_executesql @searchSQL, N'@ColumnName nvarchar(max) @countRes int OUT', @ColumnName=@ColumnName, @countRes=@countRes OUT

				print @countRes

				if @countRes > 0
				begin
					GOTO TheEnd
				end
			END
		END   
	END
end

TheEnd:
 
SELECT ColumnName, ColumnValue FROM #Results
 
DROP TABLE #Results

