DECLARE @SearchStr nvarchar(max)

-- DECLARE PARAMETERS
DECLARE @TableName nvarchar(max), @ColumnName nvarchar(max), @SearchStr2 nvarchar(max), @dbName nvarchar(max)
declare @from nvarchar(max) = ''
declare @tableTmp nvarchar(max)
declare @coltmp nvarchar(max) = ''
declare @countRes int = 0
declare @SearchDesc nvarchar(max)
declare @write bit 

-- SET INITIAL VALUES
SET  @TableName = ''
set @dbName = ''

--SET SEARCH STRING
SET @SearchStr2 = '%151B3027%'

-- SET SEARCH JUSTIFICATION
set @SearchDesc = 'test>partNo'

print 'Start'

--GET DATABASE TO LOOP THROUGH
while @dbName is not null
begin
	set @TableName = ''
	set @dbName =
	(
	select MIN(QUOTENAME([name]))
	from master.sys.databases with (nolock)
	where QUOTENAME([name]) > @dbName
	)

	-- WHILE TABLES CAN BE FETCHED
	WHILE @dbName is not null and @TableName IS NOT NULL

	BEGIN
		set @from = @dbName+'.INFORMATION_SCHEMA.TABLES '
		set @write = 1
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
		

		-- DETERMINE IF SEARCH HAS BEEN DONE IN TABLE BEFORE
		if (select COUNT(*) from analytics.stat.scan_TablesScanned where schemaTable = @TableName and searchTerm = @SearchStr2) > 0
		begin
			-- SKIP ROW; SET WRITE CHARACTER TO FALSE, SO BELOW RECORD STATEMENT IS SKIPPED
			set @write = 0
			continue
		end

		-- AS LONG AS COLUMN EXISTS
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

			
			IF @ColumnName IS NOT NULL
			
			BEGIN
				set @countRes = 0
				set @from = @dbName+'.'+@TableName
				
				-- COUNT RESULTS FOR SEARCH IN TARGET TABLE OF DB+SCHEMA+TABLE+COLUMN
				declare @searchSQL nvarchar(max) = N'SELECT @countRes = count(*) FROM '+@from+ N' with (nolock) where '+@ColumnName+' LIKE @SearchStr2' 
					
				exec sp_executesql @searchSQL, N'@ColumnName nvarchar(max), @SearchStr2 nvarchar(max), @countRes int OUTPUT', @ColumnName=@ColumnName, @SearchStr2=@SearchStr2, @countRes=@countRes OUTPUT

				-- IF RESULTS FOUND, WRITE TO RESULTS TABLE
				if @countRes > 0
				begin
					insert into [yourBaseDB].[schema].[resultsTable] (searchTerm, dbName, schemaTable, columnName, nbrOfHits) values(@SearchStr2, @dbName, @TableName, @ColumnName, @countRes)
				end

			END
		END 

		-- LOG EVERY TABLE THAT HAS BEEN SEARCHED, UNLESS TABLE HAS BEEN SEARCHED BEFORE
		if @write = 1
		begin
			insert into [yourBaseDB].[schema].[resultsTable] (searchTerm, dbName, schemaTable, searchDescription) values(@SearchStr2, @dbName, @TableName, @SearchDesc)
		end
	END
end

 
SELECT * 
FROM analytics.stat.scan_results
 
