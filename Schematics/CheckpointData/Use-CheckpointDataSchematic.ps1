function Use-CheckpointDataSchematic
{
    <#
    .Synopsis
        Builds a web application according to a schematic
    .Description
        Use-Schematic builds a web application according to a schematic.
        
        Web applications should not be incredibly unique: they should be built according to simple schematics.        
    .Notes
    
        When ConvertTo-ModuleService is run with -UseSchematic, if a directory is found beneath either Pipeworks 
        or the published module's Schematics directory with the name Use-Schematic.ps1 and containing a function 
        Use-Schematic, then that function will be called in order to generate any pages found in the schematic.
        
        The schematic function should accept a hashtable of parameters, which will come from the appropriately named 
        section of the pipeworks manifest
        (for instance, if -UseSchematic Blog was passed, the Blog section of the Pipeworks manifest would be used for the parameters).
        
        It should return a hashtable containing the content of the pages.  Content can either be static HTML or .PSPAGE                
    #>
    [OutputType([Hashtable])]
    param(
    # Any parameters for the schematic
    [Parameter(Mandatory=$true)][Hashtable]$Parameter,
    
    # The pipeworks manifest, which is used to validate common parameters
    [Parameter(Mandatory=$true)][Hashtable]$Manifest,
    
    # The directory the schemtic is being deployed to
    [Parameter(Mandatory=$true)][string]$DeploymentDirectory,
    
    # The directory the schematic is being deployed from
    [Parameter(Mandatory=$true)][string]$InputDirectory
    )
    
    
    process {                             
        if (-not $Parameter.Frequency) {
            Write-Error "Must define a frequency for the checkpoint"
            return 
        }
        
        if (-not $parameter.Command) {
            Write-Error "Must define a checkpoint command"
            return
        }
                               
        $scheduler = New-Object -ComObject Schedule.Service
        $scheduler.Connect()
        $task = $scheduler.NewTask(0)
        $task.Settings.MultipleInstances = 3
        $task.Settings.RunOnlyIfNetworkAvailable = $true
        $action = $task.Actions.create(0)
        $action.path = "$pshome\powershell.exe"
        $moduleImportList = @('Pipeworks') + @($module.RequiredModules | Select-Object -ExpandProperty Name) + $module.Name
        $moduleImportList = $moduleImportList | Select-Object -Unique
        $action.arguments = "-sta -windowStyle hidden -command & { Import-Module '$($moduleImportList -join "','")'; `$cmd = Get-Command '$($Parameter.Command)'; & `$cmd } "
        $regTrigger = $task.Triggers.create(7)
        $regTrigger.Repetition.Interval = "PT$([int]([Timespan]$Parameter.Frequency).TotalMinutes)M"
        $dailyTrigger = $task.Triggers.create(2)
        $dailyTrigger.Repetition.Interval = "PT$([int]([Timespan]$Parameter.Frequency).TotalMinutes)M"
        
        if ($parameter.Jitter -as [Timespan]) {
            $dailyTrigger.RandomDelay = "PT$([int]([Timespan]$parameter.Jitter).TotalMinutes)M"
        }
        $dailyTrigger.StartBoundary = (Get-Date).ToString("s")
        $registeredTask = $scheduler.GetFolder("").RegisterTask("$($Parameter.Command)", $task.XmlText, 6, $null, $null, 3, $null)
        
    }
} 

 
