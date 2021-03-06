function Update-Sql
{
    <#
    .Synopsis
        Updates a SQL table
    .Description
        Inserts new content into a SQL table, or updates the existing contents of a SQL table
    .Example
        Get-Counter | 
            Select-Object -ExpandProperty CounterSamples  | 
            Update-Sql -TableName Perfcounters -Force -ConnectionStringOrSetting (Get-SecureSetting SqlAzureConnectionString -ValueOnly)
    .Example
        Get-Counter | 
            Select-Object -ExpandProperty CounterSamples  | 
            Update-Sql -TableName Perfcounters -Force -ConnectionStringOrSetting (Get-SecureSetting SqlAzureConnectionString -ValueOnly) -Parallel
    .Link
        Select-Sql
    .Link
        Remove-Sql

    #>
    [OutputType([Nullable])]
    param(
    # The name of the SQL table
    [Parameter(Mandatory=$true)]
    [string]$TableName,

    # The Input Object
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [PSObject]
    $InputObject,

    # A List of Properties to add to the database.  If omitted, all properties will be added (except those excluded with -ExcludeProperty)    
    [string[]]
    $Property,

    # A List of Properties to exclude from the database.  If omitted, all properties (or the properties specified with the -Property parameter) will be added    
    [string[]]
    $ExcludeProperty,
    
    # The rowkey of the input object
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,

    # The property of the input object to use as a row    
    [string]
    $RowProperty,

    # The type of key to use for the SQL table.
    [ValidateSet('Guid', 'Hex', 'SmallHex', 'Sequential', 'Named', 'Parameter')]
    [string]$KeyType  = 'Guid',

    # A lookup table containing SQL data types
    [Hashtable[]]
    $ColumnType,


    # A lookup table containing the real SQL column names for an object
    [Hashtable[]]
    $ColumnAlias,

    # If set, will force the creation of a table.
    # If omitted, an error will be thrown if the table does not exist.
    [Switch]
    $Force,

    # The connection string or a setting containing the connection string.
    [String]
    $ConnectionStringOrSetting,

    # If set, will output SQL.  Be aware that this will only output insert statements, not update statements
    [Switch]
    $OutputSql,

    # If set, will use SQL server compact edition    
    [Switch]
    $UseSQLCompact,

    # The path to SQL Compact.  If not provided, SQL compact will be loaded from the GAC    
    [string]
    $SqlCompactPath,    
    

    # If set, will use SQL lite    
    [Alias('UseSqlLite')]
    [switch]
    $UseSQLite,
    
    # The path to SQLite.  If not provided, SQLite will be loaded from Program Files
    [Alias('SqlLitePath')]
    [string]    
    $SqlitePath,

    # If set, will use MySql to connect to the database        
    [Switch]
    $UseMySql,
    
    # The path to MySql's .NET connector.  If not provided, MySql will be loaded from Program Files            
    [string]    
    $MySqlPath,
    
    
    # The path to a SQL compact or SQL lite database    
    [Alias('DBPath')]
    [string]
    $DatabasePath,

    # If set, will skip table creation column checks
    [Switch]
    $DoNotCheckTable,

    # If set, will keep the connection open.
    [Switch]
    $KeepConnected,

    # Foreign keys in the table.    
    [Hashtable]
    $ForeignKey = @{},

    # The length of a string key.  By default, 100
    [Uint32]
    $StringKeyLength = 100,

    # If set, will run Update-SQL in parallel
    [Switch]
    $Parallel,

    # If set, will hide the progress 
    [Switch]
    $HideProgress,
    
    # If set, will output the original object.  
    [switch]
    $Passthru
    )


    begin {
        $sqlParams = @{} + $psboundparameters
        foreach ($k in @($sqlParams.Keys)) {
            if ('SqlCompactPath', 'UseSqlCompact', 'SqlitePath', 'UseSqlite', 'UseMySql', 'MySqlPath', 'DatabasePath', 'ConnectionStringOrSetting' -notcontains $k) {
                $sqlParams.Remove($k)
            }
        }        
        $params = @{} + $psboundparameters
        
        #region Get Connection String
        if ($PSBoundParameters.ConnectionStringOrSetting) {
            if ($ConnectionStringOrSetting -notlike "*;*") {
                $ConnectionString = Get-SecureSetting -Name $ConnectionStringOrSetting -ValueOnly
            } else {
                $ConnectionString =  $ConnectionStringOrSetting
            }
            $script:CachedConnectionString = $ConnectionString
        } elseif ($script:CachedConnectionString){
            $ConnectionString = $script:CachedConnectionString
        } else {
            $ConnectionString = ""
        }
        if (-not $ConnectionString -and -not ($UseSQLite -or $UseSQLCompact)) {
            throw "No Connection String"
            return
        }
        #endregion Get Connection String

        #region Connect to SQL
        if (-not $OutputSQL) {
            if ($script:CachedConnection -and $script:CachedConnection.State -eq 'Open') {
                $sqlConnection = $script:CachedConnection
            } elseif ($UseSQLCompact) {
                if (-not ('Data.SqlServerCE.SqlCeConnection' -as [type])) {
                    if ($SqlCompactPath) {
                        $resolvedCompactPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($SqlCompactPath)
                        $asm = [reflection.assembly]::LoadFrom($resolvedCompactPath)
                    } else {
                        $asm = [reflection.assembly]::LoadWithPartialName("System.Data.SqlServerCe")
                    }
                    $null = $asm
                }
                $resolvedDatabasePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($DatabasePath)
                $sqlConnection = New-Object Data.SqlServerCE.SqlCeConnection "Data Source=$resolvedDatabasePath"
                $sqlConnection.Open()

                $script:CachedConnection = $sqlConnection
            } elseif ($UseSqlite) {
                if (-not ('Data.Sqlite.SqliteConnection' -as [type])) {
                    if ($sqlitePath) {
                        $resolvedLitePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($sqlitePath)
                        $asm = [reflection.assembly]::LoadFrom($resolvedLitePath)
                    } else {
                        $asm = [Reflection.Assembly]::LoadFrom("$env:ProgramFiles\System.Data.SQLite\2010\bin\System.Data.SQLite.dll")
                    }
                    $null = $asm
                }
                
                
                $resolvedDbPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($DatabasePath)
                $sqlConnection = New-Object Data.Sqlite.SqliteConnection "Data Source=$resolvedDbPath"
                $sqlConnection.Open()
                $script:CachedConnection = $sqlConnection
            }  elseif ($useMySql) {
                if (-not ('MySql.Data.MySqlClient.MySqlConnection' -as [type])) {
                    if (-not $mySqlPath) {
                        $programDir = if (${env:ProgramFiles(x86)}) {
                            ${env:ProgramFiles(x86)}
                        } else {
                            ${env:ProgramFiles} 
                        }
                        $mySqlPath = Get-ChildItem "$programDir\MySQL\Connector NET 6.7.4\Assemblies\"| 
                            Where-Object { $_.Name -like "*v*" } | 
                            Sort-Object { $_.Name.Replace("v", "") -as [Version] } -Descending |
                            Select-object -First 1 | 
                            Get-ChildItem -filter "MySql.Data.dll" | 
                            Select-Object -ExpandProperty Fullname
                    }
                    $asm = [Reflection.Assembly]::LoadFrom($MySqlPath)
                    $null = $asm
                    
                }
                $sqlConnection = New-Object MySql.Data.MySqlClient.MySqlConnection "$ConnectionString"
                $sqlConnection.Open()
            } else {
                $sqlConnection = New-Object Data.SqlClient.SqlConnection "$connectionString"
                $sqlConnection.Open()
                $script:CachedConnection = $sqlConnection
            }
            

        }
        #endregion Connect to SQL

        
        
        $propertyMatches = @{}
        foreach ($p in $Property) {
            if ($p) {
                $propertyMatches.$p =  $p
            }
        }

        $excludeMatches = @{}
        foreach ($p in $excludeMatches) {
            if ($p) {
                $excludeMatches.$p =  $p
            }
        }

        #region Common Parameters & Procedures
        
               
        
        $GetPropertyNamesAndTypes = {
            param($object, [string[]]$PropertyList)
            $haspstypename = $false            
            
            foreach ($prop in $object.psobject.properties) {
                if (-not $prop) { continue } 
                if ($PropertyList -and $prop.Name -notcontains $PropertyList) { continue } 
                if ($propertyMatches.Count -and -not $propertyMatches[$prop]) {
                    continue
                } 

                if ($ExcludeProperty.Count -and $ExcludeProperty -contains $prop.Name) {
                    continue
                }
                # $prop.Name
                if ($prop.Name -eq 'RowError' -or $prop.Name -eq 'RowState' -or $prop.Name -eq 'Table' -or $prop.Name -eq 'ItemArray'-or $prop.Name -eq 'HasErrors') {
                    continue
                }

                if ($prop.Name -eq 'pstypename') {
                    $haspstypename = $true
                }
                    
                $sqlType = if ($columnType -and $columnType[$prop.Name]) {
                    $columnType[$prop.Name]
                } elseif ($prop.Value -ne $null) {
                    if ($prop.Value -is [String]) {
                        if ($UseSQLCompact) {
                            "ntext"
                        } elseif ($UseSQLite) {
                            "text"
                        } elseif ($useMySql) {
                            "longtext"
                        } else {
                            "varchar(max)"                            
                        }
                            
                    } elseif ($prop.Value -is [bool] -or 
                        $prop.Value -is [switch]) {
                        "bit"
                    } elseif ($Prop.Value -is [Double]) {
                        "float"
                    } elseif ($prop.Value -is [Long]) {
                        "bigint"
                    } elseif ($prop.Value -is [DateTime]) {
                        "datetime"
                    } elseif ($prop.Value -is [Byte]) {
                        "tinyint"
                    } elseif ($prop.Value -is [Int16]) {
                        "smallint"
                    } elseif ($prop.Value -is [Int]) {
                        "int"
                    } elseif ($prop.Value -is [char]) {
                        "char(1)"
                    } elseif ($prop.Value -is [BigInt]) {
                        "BIGINT"
                    } else {
                        if ($UseSQLCompact) {
                            "ntext"
                        } elseif ($UseSQLite) {
                            "text"
                        } elseif ($UseMySql) {
                            "longtext"
                        } else {
                            "varchar(max)"
                        }
                    }

                } else {
                    if ($UseSQLCompact) {
                        "ntext"
                    } elseif ($UseSQLite) {
                        "text"
                    } elseif ($UseMySql) {
                        "longtext"
                    } else {
                        "varchar(max)"
                    }
                }

                $columnName = if ($ColumnAlias -and $ColumnAlias[$prop.Name]) {
                    $ColumnAlias[$prop.Name]
                } else {
                    $prop.Name
                }



                    
                New-Object PSObject -Property @{
                    Name=$columnName 
                    Value = if ($sqlType -eq 'bit') {
                        if ($prop.Value) {
                            1 
                        } else {
                            0
                        }
                    } elseif ($sqlType -eq 'datetime') {
                        if ($useMySql) {
                            ($prop.Value -as [datetime]).ToString([Globalization.CultureInfo]::InvariantCulture.DateTimeFormat.SortableDateTimePattern)
                        } else {
                            $prop.Value
                        }
                    } else {
                        ($prop.Value -as [string]).Replace("'", "''")
                    }
                    SqlType = $sqlType
                }
            }

            if ($haspstypename -or ($PropertyList -and $propertyList -notcontains 'pstypename') -or 
                ($object.pstypenames[0] -like "*.PSCustomObject" -or 
                $object.pstypenames[0] -like "*Selected.*")) {
            } else {
                New-Object PSObject -Property @{
                    Name="pstypename"
                    Value = $object.pstypenames -join '|'
                    SqlType = if ($UseSQLCompact) {
                                "ntext"
                            } elseif ($UseSQLite) {
                                "text"
                            } elseif ($useMySql) {
                                "longtext"
                            } else {
                                "varchar(max)"
                            }
                }
            }
        }

        #endregion Common Parameters & Procedures
        if (-not $DoNotCheckTable) {
            $columnsInfo = 
                Get-SqlTable -TableName $TableName @sqlParams
        
            if (-not $columnsInfo) {
                # Table Doesn't Exist Yet, mark it for creation 
                if (-not $Force) {
                    Write-Error "$tableName does not exist"
                }    
                    
            }
            $Local:DoNotRetry = $false
        }

        $AccumulatedInput = New-Object Collections.ArrayList
    }


    process {                
        # If there are no columns, and -Force  is not set
        if (-not $columnsInfo -and -not $force) {
            
            return
        }

        
        
        $params = @{} + $psboundparameters
        $null = $AccumulatedInput.Add($params)
        
        #endregion Attempt SQL Insert 
    }

    end {         
        $total= $AccumulatedInput.Count
        $counter =0 
        $progressId = Get-Random
        if ($Parallel -and $AccumulatedInput.Count -gt 9) {
            $first, $rest = @($AccumulatedInput)
            $first.Remove("Parallel")
            $first.HideProgress = $true 
            Update-Sql @first 
            foreach ($in in $rest) {
                $in.Remove("Parallel")
                $in.Passthru = $true 
                $in.HideProgress = $true 
            }
            $sb = [ScriptBlock]::Create("
`$m = New-Module -Name Pipeworks {
function Update-SQL
{
$((Get-Command Update-SQL).Definition)
}
function Select-SQL {
$((Get-Command Select-SQL).Definition)
}
function Get-SQLTable {
$((Get-Command Get-SqlTable).Definition)
}
function Add-SQLTable {
$((Get-Command Add-SqlTable).Definition)
}
function Get-SecureSetting{
$((Get-Command Get-SecureSetting).Definition)
}

}
`$generalParameters = @{} + `$args[0]
`$generalParameters.Remove('InputObject')
`$inputObjects = foreach (`$a in `$args) { `$a.InputObject } 
`$inputObjects | Update-SQL @generalParameters 
")
            
            
            $total = $AccumulatedInput.Count
            $counter = 1
            Invoke-Parallel -InputObject $rest -Command $sb |
                ForEach-Object {
                    if ($_ -isnot [Management.Automation.ErrorRecord]) {
                        $counter++
                        $perc  = $counter * 100 / $total
                        if (-not $hideProgress) {
                            Write-Progress -Id $progressId -PercentComplete $perc "Updating $TableName" "$counter of $total"
                        }
                    } else {
                        $_ | Write-Error
                    }
                    
                } -End {
                    if (-not $hideProgress) {
                        Write-Progress -Id $progressId -Completed "Updating $TableName" "$counter of $total"
                    }
                }
                    
            return
        }


        foreach ($in in $AccumulatedInput) {
            $counter++
            $perc = $counter * 100 / $total
            if (-not $HideProgress) {
                Write-Progress "Updating $TableName" "$counter of $total" -PercentComplete $perc -Id $progressId
            }
            foreach ($kv in $in.GetEnumerator()) {
                Set-Variable -Name $kv.Key -Value $kv.Value 
            }

            

            $objectSqlInfo = & $GetPropertyNamesAndTypes $inputObject 

            # There are no columns, create the table
            if (-not $columnsInfo -and (-not $Local:DoNotRetry) -and -not $DoNotCheckTable) {
                $extraSqlParams = @{StringKeyLength = $StringKeyLength}

                if ($ForeignKey -and $ForeignKey.Count) {
                    $extraSqlParams["ForeignKey"] = $ForeignKey
                }
                
            
                if ($RowProperty) {
                    Add-SqlTable -KeyType $keyType -TableName $TableName -Column (
                        $objectSqlInfo | 
                            Where-Object { $_.Name -ne $RowProperty } | 
                            Select-Object -ExpandProperty Name
                    ) -DataType (
                        $objectSqlInfo | 
                            Where-Object { $_.Name -ne $RowProperty } | 
                            Select-Object -ExpandProperty SqlType
                    ) @sqlParams -RowKey $RowProperty @extraSqlParams
            
                } else {
                    Add-SqlTable -KeyType $keyType -TableName $TableName -Column (
                        $objectSqlInfo | 
                            Where-Object { $_.Name -ne 'RowKey' } | 
                            Select-Object -ExpandProperty Name
                    ) -DataType (
                        $objectSqlInfo | 
                            Where-Object { $_.Name -ne 'RowKey' } | 
                            Select-Object -ExpandProperty SqlType
                    ) @sqlParams @extraSqlParams
                }

            
            
                if (-not $DoNotCheckTable) {
                    $columnsInfo = Get-SQLTable -TableName $TableName @sqlParams
                }
        
            }

            # If there's still no columns info the table could not be created, and we should bounce
            if (-not $columnsInfo -and -not $DoNotCheckTable) {
                $Local:DoNotRetry = $true
                return

            }
            $updated = $false


            # It's quicker, and involves less simultaneous connections, to attempt an insert before attempting an update

            #region Attempt SQL Insert
            $row = 
                if ($psBoundParameters.RowKey -and -not $updated) {
                    $psBoundParameters.RowKey
                } elseif ($psBoundParameters.RowProperty -and $inputObject.$rowProperty) {
                    $inputObject.$rowProperty
                } elseif ($KeyType -eq 'GUID') {
                    [GUID]::NewGuid()
                } elseif ($KeyType -eq 'Hex') {
                    "{0:x}" -f (Get-Random)
                } elseif ($KeyType -eq 'SmallHex') {
                    "{0:x}" -f ([int](Get-Random -Maximum 512kb))
                } elseif ($KeyType -eq 'Sequential') {
                    # Seqential keys should be handled by SQL
                    #if ($row -ne $null -and $row -as [Uint32]) {
                    #    $row + 1  
                    #} else {                    
                        #Select-SQL -FromTable $TableName -Property "COUNT(*)" @sqlParams | 
                        #    Select-Object -ExpandProperty Column1                    
                    #}
                }
            $insertColumns = @($objectSqlInfo | 
                Where-Object { $_.Name -ne 'RowKey'} | 
                Where-Object { 
                    if ($RowProperty) {
                        $_.Name -ne $RowProperty 
                    } elseif ($_.Name -ne 'RowKey') {
                        $_
                    }
                } |
                Select-Object -ExpandProperty Name)

            $insertData = @($objectSqlInfo | 
                Where-Object { $insertColumns -contains $_.Name } |                               
                Foreach-Object { $_.Value })
            $isUpdate = $false
            $insertNames = if ($UseMySql) {
                $insertColumns  -join ", "
            } else {
                $insertColumns  -join "`", `""
            }
            
            $insertInfo=  $insertData -join "', '"
            if ($params.RowKey ) { 
                $sqlInsert = 
                    if ($UseMySql) {
                        "INSERT INTO $TABLEName (RowKey, $insertNames) VALUES ('$Row','$insertInfo')"
                    } else {
                        "INSERT INTO $TABLEName (`"RowKey`", `"$insertNames`") VALUES ('$Row','$insertInfo')"
                    }
                    
            } else {
                $rowKeyInfo = if ($KeyType -ne 'Sequential' -and $row) {
                    if ($UseMySql) {
                        if ($RowProperty) {
                            "$rowProperty,"
                        } else {
                            "RowKey,"
                        }
                    } else {
                        if ($RowProperty) {
                            "`"$rowProperty`","
                        } else {
                            "`"RowKey`","
                        }
                    }
                    
                }

                if ($keyType -eq 'Sequential') {
                    if ($inputObject.$rowProperty -or $psboundparameters.RowKey)  {
                        $isUpdate = $true
                    }
                
                }
                
                $rowKeyValue = if ($KeyType -ne 'Sequential' -and $row) {
                    "'$Row',"
                }
                
                $sqlInsert = 
                    if ($UseMySql) {
                        "INSERT INTO $TABLEName ($rowKeyInfo $insertNames) VALUES ($rowKeyValue '$(
                            $insertInfo)')"
                    } else {
                        "INSERT INTO $TABLEName ($rowKeyInfo `"$insertNames`") VALUES ($rowKeyValue '$(
                            $insertInfo)')"
                    }
                    
            }
            if (-not $isUpdate) {
                Write-Verbose $sqlInsert
            }

            $sqlStatement = $sqlInsert
            $shouldKeepTrying = $true
            do {
                try {
                    $sqlStatement = $sqlInsert
                    if ($outputSql) {
                        $sqlStatement
                    } elseif ($isupdate) {
                        throw "It's an update"
                    } elseif ($UseSQLCompact) {
                        $sqlAdapter= New-Object "Data.SqlServerCE.SqlCeDataAdapter" ($sqlStatement, $sqlConnection)
                    
                        $dataSet = New-Object Data.DataSet
                        $rowCount = $sqlAdapter.Fill($dataSet)
                        
                    } elseif ($UseSQLite) {
                        $sqlAdapter= New-Object "Data.SQLite.SQLiteDataAdapter" ($sqlStatement, $sqlConnection)
                    
                        $dataSet = New-Object Data.DataSet
                        $rowCount = $sqlAdapter.Fill($dataSet)
                        $null = $rowCount
                    } elseif ($UseMySql) {
                        $sqlAdapter= New-Object "MySql.Data.MySqlClient.MySqlDataAdapter" ($sqlStatement, $sqlConnection)
                        $sqlAdapter.SelectCommand.CommandTimeout = 0
                        $dataSet = New-Object Data.DataSet
                        $rowCount = $sqlAdapter.Fill($dataSet)
                    } else {
                        $sqlAdapter= New-Object "Data.SqlClient.SqlDataAdapter" ($sqlStatement, $sqlConnection)
                    
                        $dataSet = New-Object Data.DataSet
                        $rowCount = $sqlAdapter.Fill($dataSet)                        
                    }
                    $null = $rowCount
                    $shouldKeepTrying = $false    
                } catch {
                    $insertError = $_ 
                    $null = $insertError
                    if ($_.Exception.InnerException.Message -like "*invalid column name*" -or 
                        $_.Exception.InnerException.Message -like "*no column named*" -or
                        $_.Exception.InnerException.Message -like "*column name is not valid*" -or 
                        $_.Exception.InnerException.Message -like "Unknown Column*") {
                    
                        $columnName  = if ($_.Exception.InnerException.Message -like "*invalid*") {
                                ($_.Exception.InnerException.Message -split "'")[1]
                        } elseif ($_.Exception.InnerException.Message -like "*no column named*") {
                                ($_.Exception.InnerException.Message -split " ")[-1]
                        } elseif ($_.Exception.InnerException.Message -like "*column name is not valid*") {
                            ($_.Exception.InnerException.Message -split "[ =\]]" -ne '')[-1]
                        }  elseif ($_.Exception.InnerException.Message -like "Unknown column*") {
                            ($_.Exception.InnerException.Message -split "'" -ne '')[1]
                        }

                        $columnInfo = & $GetPropertyNamesAndTypes $inputObject -propertyList $columnName
                    
                        $sqlAlter=  "ALTER TABLE $TableName ADD $ColumnName $($columnInfo.SqlType)"
                        $sqlStatement = $sqlAlter
                        try {
                            if ($UseSQLCompact) {
                                $sqlAdapter= New-Object "Data.SqlServerCE.SqlCeDataAdapter" ($sqlStatement, $sqlConnection)
                                $sqlAdapter.SelectCommand.CommandTimeout = 0
                                $dataSet = New-Object Data.DataSet
                                $rowCount = $sqlAdapter.Fill($dataSet)
                            } elseif ($UseSQLite) {
                                $sqlAdapter= New-Object "Data.SQLite.SQLiteDataAdapter" ($sqlStatement, $sqlConnection)
                                $sqlAdapter.SelectCommand.CommandTimeout = 0
                                $dataSet = New-Object Data.DataSet
                                $rowCount = $sqlAdapter.Fill($dataSet)
                            } elseif ($useMySql) {
                                $sqlAdapter= New-Object "MySql.Data.MySqlClient.MySqlDataAdapter" ($sqlStatement, $sqlConnection)
                                $sqlAdapter.SelectCommand.CommandTimeout = 0
                                $dataSet = New-Object Data.DataSet
                                $rowCount = $sqlAdapter.Fill($dataSet)
                            } else {
                                $sqlAdapter= New-Object "Data.SqlClient.SqlDataAdapter" ($sqlStatement, $sqlConnection)
                                $sqlAdapter.SelectCommand.CommandTimeout = 0
                                $dataSet = New-Object Data.DataSet
                                $rowCount = $sqlAdapter.Fill($dataSet)
                            }   
                        
                        } catch {
                            $shouldKeepTrying = $false
                            Write-Error $_
                            Write-Debug $_
                        } 
                                        
                    } elseif ($_.Exception.HResult -eq '-2146233087' -or $_.Exception.Hresult -eq '-2146233087' -or $isUpdate) {
                        # It's a duplicate, so update instead of create
                    
                        $sqlUpdate =  "UPDATE $TABLEName SET "
                        $sqlUpdate += (
                                    ($objectSqlInfo | 
                                    Where-Object { 
                                        $insertColumns -contains $_.Name       
                                    } | 
                                    Foreach-Object { 
                                        if ($UseMySql) {
                                            $_.Name + '=' + "'$($($_.Value))'" 
                                        } else {
                                            '[' + $_.Name + ']=' + "'$($($_.Value))'" 
                                        }
                                        
                                    
                                    }) -join ", ")
                            
                        $sqlupdate+= " WHERE " +$(
                                        if ($params.RowKey) { 
                                            "RowKey='$RowKey'" 
                                        } elseif (
                                            $InputObject.$RowProperty) {
                                                "$RowProperty ='$($inputObject.$RowProperty)'"
                                        })
                        Write-Verbose $SqlUpdate


                        $shouldKeepTrying = $true
                        do {
                            try {
                                $sqlStatement = $sqlUpdate
                                if ($outputSql) {
                                    $sqlStatement
                                } elseif ($UseSQLCompact) {
                                    $sqlAdapter= New-Object "Data.SqlServerCE.SqlCeDataAdapter" ($sqlStatement, $sqlConnection)
                    
                                    $dataSet = New-Object Data.DataSet
                                    $rowCount = $sqlAdapter.Fill($dataSet)
                                } elseif ($UseSQLite) {
                                    $sqlAdapter= New-Object "Data.SQLite.SQLiteDataAdapter" ($sqlStatement, $sqlConnection)
                    
                                    $dataSet = New-Object Data.DataSet
                                    $rowCount = $sqlAdapter.Fill($dataSet)
                                } elseif ($UseMySql) {
                                    $sqlAdapter= New-Object "MySql.Data.MySqlClient.MySqlDataAdapter" ($sqlStatement, $sqlConnection)
                                    $sqlAdapter.SelectCommand.CommandTimeout = 0
                                    $dataSet = New-Object Data.DataSet
                                    $rowCount = $sqlAdapter.Fill($dataSet)
                                } else {
                                    $sqlAdapter= New-Object "Data.SqlClient.SqlDataAdapter" ($sqlStatement, $sqlConnection)
                    
                                    $dataSet = New-Object Data.DataSet
                                    $rowCount = $sqlAdapter.Fill($dataSet)
                                }
                                $shouldKeepTrying = $false      
                            } catch {
                                if ($_.Exception.InnerException.Message -like "*invalid column name*" -or 
                                    $_.Exception.InnerException.Message -like "*no column named*" -or
                                    $_.Exception.InnerException.Message -like "*column name is not valid*") {
                    
                                    $columnName  = if ($_.Exception.InnerException.Message -like "*invalid*") {
                                         ($_.Exception.InnerException.Message -split "'")[1]
                                    } elseif ($_.Exception.InnerException.Message -like "*no column named*") {
                                         ($_.Exception.InnerException.Message -split " ")[-1]
                                    } elseif ($_.Exception.InnerException.Message -like "*column name is not valid*") {
                                        ($_.Exception.InnerException.Message -split "[ =\]]" -ne '')[-1]
                                    }

                                    $columnInfo = & $GetPropertyNamesAndTypes $inputObject -propertyList $columnName
                    
                                    $sqlAlter=  "ALTER TABLE $TableName ADD $ColumnName $($columnInfo.SqlType)"
                                    $sqlStatement = $sqlAlter
                                    try {
                                        if ($UseSQLCompact) {
                                            $sqlAdapter= New-Object "Data.SqlServerCE.SqlCeDataAdapter" ($sqlStatement, $sqlConnection)
                                            $sqlAdapter.SelectCommand.CommandTimeout = 0
                                            $dataSet = New-Object Data.DataSet
                                            $rowCount = $sqlAdapter.Fill($dataSet)
                                        } elseif ($UseSQLite) {
                                            $sqlAdapter= New-Object "Data.SQLite.SQLiteDataAdapter" ($sqlStatement, $sqlConnection)
                                            $sqlAdapter.SelectCommand.CommandTimeout = 0
                                            $dataSet = New-Object Data.DataSet
                                            $rowCount = $sqlAdapter.Fill($dataSet)
                                        } elseif ($UseMySql) {
                                            $sqlAdapter= New-Object "MySql.Data.MySqlClient.MySqlDataAdapter" ($sqlStatement, $sqlConnection)
                                            $sqlAdapter.SelectCommand.CommandTimeout = 0
                                            $dataSet = New-Object Data.DataSet
                                            $rowCount = $sqlAdapter.Fill($dataSet)
                                        } else {
                                            $sqlAdapter= New-Object "Data.SqlClient.SqlDataAdapter" ($sqlStatement, $sqlConnection)
                                            $sqlAdapter.SelectCommand.CommandTimeout = 0
                                            $dataSet = New-Object Data.DataSet
                                            $rowCount = $sqlAdapter.Fill($dataSet)
                                        }   
                        
                                    } catch {
                                        $shouldKeepTrying = $false
                                        Write-Error $_
                                        Write-Debug $_
                                    }                                                                          
                                } else {
                                    $shouldKeepTrying = $false
                                    Write-Debug $_
                                    Write-Error $_
                                }
                            }
                        } while ($shouldKeepTrying)
                        
                    
                    } else {
                        $shouldKeepTrying = $false
                        Write-Debug $_
                        Write-Error $_
                    }


                
                }
            } while ($shouldKeepTrying)
            if ($Passthru) {
                $InputObject
            }
        }
        if (-not $HideProgress) {
            Write-Progress "Updating $TableName" "Completed" -Completed -Id $progressId

        }
        if ($sqlConnection -and -not $keepConnected) {
            $sqlConnection.Close()
            $sqlConnection.Dispose()
        }        
    }
} 


