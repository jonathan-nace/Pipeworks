function Get-SQLTable
{
    <#
    .Synopsis
        Gets SQL table information
    .Description
        Gets metadata about a SQL table, including it's columns and their data types
    .Example
        Get-SqlTable "MySqlTable" -ConnectionString SqlAzureConnectionString
    .Link
        Add-SqlTable
    .Link
        Update-SQL
    .Link
        Remove-SQL
    .Link
        Select-SQL
    #>
    [OutputType([PSObject])]
    [CmdletBinding(DefaultParameterSetName='SqlServer')]
    param(
    # The name of the SQL table    
    [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
    [string]$TableName,

    # A connection string or a setting containing a connection string.    
    [Alias('ConnectionString', 'ConnectionSetting')]
    [string]$ConnectionStringOrSetting,
    
    # If set, outputs the SQL, and doesn't execute it
    [Switch]
    $OutputSQL,
    
    # If set, will use SQL server compact edition
    [Parameter(Mandatory=$true,ParameterSetName='SqlCompact')]
    [Switch]
    $UseSQLCompact,


    # The path to SQL Compact.  If not provided, SQL compact will be loaded from the GAC
    [Parameter(ParameterSetName='SqlCompact')]
    [string]
    $SqlCompactPath,

    # If set, will use SQL lite
    [Parameter(Mandatory=$true,ParameterSetName='Sqlite')]
    [Alias('UseSqlLite')]
    [switch]
    $UseSQLite,
    
    # The path to SQL Lite.  If not provided, SQL compact will be loaded from Program Files
    [Parameter(ParameterSetName='Sqlite')]
    [string]
    $SqlitePath,
    
    # The path to a SQL compact or SQL lite database
    [Parameter(Mandatory=$true,ParameterSetName='SqlCompact')]
    [Parameter(Mandatory=$true,ParameterSetName='Sqlite')]
    [Alias('DBPath')]
    [string]
    $DatabasePath,

    # If set, will use MySql to connect to the database    
    [Parameter(Mandatory=$true,ParameterSetName='MySql')]
    [Switch]
    $UseMySql,
    
    # The path to MySql's .NET connector.  If not provided, MySql will be loaded from Program Files        
    [Parameter(ParameterSetName='MySql')]
    [string]    
    $MySqlPath
    )

    begin {
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

        if (-not $OutputSQL) {

            if ($UseSQLCompact) {
                if (-not ('Data.SqlServerCE.SqlCeConnection' -as [type])) {
                    if ($SqlCompactPath) {
                        $resolvedCompactPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($SqlCompactPath)
                        $asm = [reflection.assembly]::LoadFrom($resolvedCompactPath)
                    } else {
                        $asm = [reflection.assembly]::LoadWithPartialName("System.Data.SqlServerCe")
                    }
                }
                $resolvedDatabasePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($DatabasePath)
                $sqlConnection = New-Object Data.SqlServerCE.SqlCeConnection "Data Source=$resolvedDatabasePath"
                $sqlConnection.Open()
            } elseif ($UseSqlite) {
                if (-not ('Data.Sqlite.SqliteConnection' -as [type])) {
                    if ($sqlitePath) {
                        $resolvedLitePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($sqlitePath)
                        $asm = [reflection.assembly]::LoadFrom($resolvedLitePath)
                    } else {
                        $asm = [Reflection.Assembly]::LoadFrom("$env:ProgramFiles\System.Data.SQLite\2010\bin\System.Data.SQLite.dll")
                    }
                }
                
                
                $resolvedDatabasePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($DatabasePath)
                $sqlConnection = New-Object Data.Sqlite.SqliteConnection "Data Source=$resolvedDatabasePath"
                $sqlConnection.Open()
                
            } elseif ($useMySql) {
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
            }
            

        }
    }

    process {
        $sqlParams = @{} + $psboundparameters
        foreach ($k in @($sqlParams.Keys)) {
            if ('SqlCompactPath', 'UseSqlCompact', 'SqlitePath', 'UseSqlite', 'DatabasePath', 'ConnectionStringOrSetting'. 'UseMySql', 'MySqlPath' -notcontains $k) {
                $sqlParams.Remove($k)
            }
        }
        $columns = try {
            $sqlConnection.GetSchema("columns")
        } catch {
            if (-not $sqlParams.UseSqlLite) {
                if ($TableName) {
                    Select-SQL @sqlParams -FromTable "INFORMATION_SCHEMA.COLUMNS" -Where "Table_Name='$TableName'"
                } else {
                    Select-SQL @sqlParams -FromTable "INFORMATION_SCHEMA.COLUMNS" 
                }
                
            }
            

        }

        $columns | Group-Object Table_Name |
            Where-Object {
                ($TableName -and $_.Name -like $TableName) -or (-not $TableName)
            } |
            ForEach-Object {
                $group = $_.Group
                $table = $_.Name
                $tableSchema = foreach ($_ in $group) {
                    $_.Table_Schema 
                    break
                }
                $columns = @(foreach ($_ in $group) {
                    $_.Column_Name
                 
                })
                $dataTypes= @(foreach ($_ in $group) {
                    $_.Data_Type
                 
                })

                New-Object PSObject -Property @{
                    TableName = $table
                    Columns = $columns
                    DataTypes = $dataTypes
                    TableSchema = $tableSchema
                }
            }


    }

    end {
        if ($sqlConnection) {
            $sqlConnection.Close()
            $sqlConnection.Dispose()
        }
    }
} 
