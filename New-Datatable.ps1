function New-DataTable
{
    <#
    .Synopsis
        Creates a new datatable
    .Description
        Creates a new datatable, with optional column information
    .Example
        $dt = New-DataTable -ColumnName Name, Age -ColumnType ([string]), ([int]) -KeyColumn Name
        New-Object PSObject -Property @{
            Name = "James"
            Age = 32
        } |
            Update-Datatable $dt
    .Link
        Update-DataTable
    .Link
        Select-DataTable
    #>
    [OutputType([Data.Datatable])]
    param(
    # The names of the columns
    [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $ColumnName,

    # The types of the columns.  
    # Be aware: complex types might not be serializable, and the table might not be able to be saved because of it.
    # To avoid this, use only simple types: 'System.Boolean', 'System.Byte[]', 'System.Byte', 'System.Char', 'System.Datetime', 'System.Decimal', 'System.Double', 'System.Guid', 'System.Int16', 'System.Int32', 'System.Int64', 'System.Single', 'System.UInt16', 'System.UInt32', 'System.UInt64'
    [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
    [Type[]]
    $ColumnType,

    # The names of the key columns
    [Parameter(Position=2,ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $KeyColumn
    )

    process {
        $dt = New-Object Data.Datatable        

        $index =0 
        foreach ($c in $ColumnName) {
            $ct = if ($ColumnType[$index]) {
                $ColumnType[$index]
            } else {
                'System.Object'
            }
            $dt.Columns.Add((
                New-Object Data.DataColumn -Property @{
                    ColumnName = $c
                    DataType = $ct.FullName
                }
            ))
            $index++
        }

        if ($KeyColumn) {
            $dt.PrimaryKey = @(foreach( $k in $KeyColumn) {
                $dt.Columns.Item($k)
            })            
        }

        , $dt 
    }
} 
