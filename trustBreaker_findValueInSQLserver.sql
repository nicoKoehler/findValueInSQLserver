DECLARE @SearchStr nvarchar(max)



if OBJECT_ID('tempdb..#Results') is not null
begin
	drop table #Results
end

CREATE TABLE #Results (databaseName nvarchar(max), ColumnName nvarchar(max), ColumnValue nvarchar(max), nbrOfMatches int)
 
 
DECLARE @TableName nvarchar(max), @ColumnName nvarchar(max), @SearchStr2 nvarchar(max), @dbName nvarchar(max)
SET  @TableName = ''
--SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')
SET @SearchStr2 = '%329B0254%'
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
		set @from = @dbName+'.INFORMATION_SCHEMA.TABLES '

		SET @ColumnName = ''
		set @tableTmp = ''
		declare @sql nvarchar(max) =(N'SELECT @tableTmp = MIN(QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME)) 
								FROM '+@from+N' with (nolock) 
								WHERE TABLE_TYPE = ''BASE TABLE''
									AND    QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME) > @TableName
									AND    coalesce(OBJECTPROPERTY(
												OBJECT_ID(
													QUOTENAME(TABLE_SCHEMA)+''.''+QUOTENAME(TABLE_NAME)
													), ''IsMSShipped''), 0) = 0
													')
		

		exec sp_executesql @sql,N'@TableName nvarchar(max), @tableTmp nvarchar(max) OUTPUT' , @TableName=@TableName,@tableTmp=@TableName OUTPUT
		
		WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
         
		BEGIN
			set @from = @dbName+'.INFORMATION_SCHEMA.COLUMNS'
			set @coltmp = ''

			declare @colSQL nvarchar(max) = N'SELECT @coltmp = MIN(QUOTENAME(COLUMN_NAME))
												FROM     '+@from+ N' with (nolock)
												WHERE         TABLE_SCHEMA    = PARSENAME(@TableName, 2)
													AND    TABLE_NAME    = PARSENAME(@TableName, 1)
													--AND    DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'', ''int'', ''decimal'')
													AND    QUOTENAME(COLUMN_NAME) > @ColumnName'
			

			exec sp_executesql @colSQL, N'@ColumnName nvarchar(max), @TableName nvarchar(max), @coltmp nvarchar(max) OUT', @TableName=@TableName, @ColumnName=@ColumnName, @coltmp=@ColumnName OUT


			--GOTO Theend
			
 
			IF @ColumnName IS NOT NULL
			
			BEGIN
				set @countRes = 0
				set @from = @dbName+'.'+@TableName

				declare @searchSQL nvarchar(max) = N'SELECT @countRes = count(*) FROM '+@from+ N' with (nolock) where '+@ColumnName+' LIKE @SearchStr2' 
					
				exec sp_executesql @searchSQL, N'@ColumnName nvarchar(max), @SearchStr2 nvarchar(max), @countRes int OUTPUT', @ColumnName=@ColumnName, @SearchStr2=@SearchStr2, @countRes=@countRes OUTPUT

				if @countRes > 0
				begin
					insert into #Results values(@dbName, @TableName, @ColumnName, @countRes)
				end

			END
		END   
	END
end

 
SELECT* FROM #Results
 
DROP TABLE #Results

