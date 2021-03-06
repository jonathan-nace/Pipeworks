function Get-Deployment
{
    <#
    .Synopsis
        Gets Pipeworks deployments
    .Description
        Gets PowerShell Pipeworks deployment
    .Example
        Get-Deployment
    .Link
        Import-Deployment
    .Link
        Push-Deployment
    .Link
        Publish-Deployment
    #>
    [CmdletBinding(DefaultParameterSetName='AllDeployments')]
    [OutputType('Pipeworks.Deployment')]
    param(
    # The name of the module 
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='SpecificDeployments')]
    [string[]]
    $Name
    )

    begin {
        $existingDeployments = Get-SecureSetting -Name "PipeworksDeployments" -ValueOnly
        if (-not $existingDeployments) {
            $existingDeployments = @{}
        }

        $expandDeployment = {

            $deployment = New-Object PSObject -Property $_.Value
            $deployment.pstypenames.clear()
            $deployment.pstypenames.add('Pipeworks.Deployment')
            $deployment
        }

    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'AllDeployments') {
            $existingDeployments.GetEnumerator() |
                Sort-Object Key | 
                ForEach-Object $expandDeployment
        } else {
            $existingDeployments.GetEnumerator() |
                Where-Object { 
                    foreach ($n in $name) {
                        $_.Key -like $n
                    }
                } |
                ForEach-Object $expandDeployment
        }
    }
} 
