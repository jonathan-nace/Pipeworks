function Use-StagePageSchematic
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
    
        if (-not $Parameter.Stages) {
            Write-Error "No scenes found"
            return
        }
        
        if (-not $Parameter.CurtainColor) {
            Write-Error "Stage must have a curtain color"
            return
        }
        
        if (-not $Parameter.BackgroundColor) {
            Write-Error "Stage must have a background color"
            return
        }
        
        if (-not $parameter.StageColor) {
            Write-Error "Stage must have a stage color"
            return
        }
        
                               
        
        $stagesInTables = 
            $parameter.Stages.GetEnumerator() | 
                Where-Object { 
                    $_.Name -eq 'Scenes' -and $_.Value.GetEnumerator() |
                        Where-Object { $_.Id } 
                } 
        
        if ($stagesInTables) {
            if (-not $Manifest.Table.Name) {
                Write-Error "No table found in manifest"
                return
            }
            
            if (-not $Manifest.Table.StorageAccountSetting) {
                Write-Error "No storage account name setting found in manifest"
                return
            }
            
            if (-not $manifest.Table.StorageKeySetting) {
                Write-Error "No storage account key setting found in manifest"
                return
            }
        }
        
        
        $outputPages = @{}
        
        $orgName = $parameter.Organization.Name
        
        
        $orginfo = if ($parameter.Organization) {
            $parameter.Organization
        } else {
            @{}
        }
        
        
        foreach ($stage in @($parameter.Stages)) 
        {
            $stagePage = New-Object PSOBject -Property $stage
            $pageName = $stagePage.Name
            $pageHeaderImage = $stagePage.pageHeaderImage
                
            $pageIsDynamic = $stagesInTables -as [bool]
            
            $pageScript = "
`$pageTitle = '$pageName';
`$sceneOrder = '$(($stagePage.SceneOrder | foreach-object { $_.Replace("'","''") }) -join "','")'
`$pageHeaderImage = '$pageHeaderImage';
`$curtainColor = '$($parameter.curtainColor)';`
`$stageColor ='$($parameter.StageColor)';
`$bgColor = '$($parameter.BackgroundColor)';
`$fontName = '$(if ($parameter.FontName) {  $parameter.FontName }else { 'Gisha' } )'
`$scenes = $(Write-PowerShellHashtable -InputObject $parameter.Scenes)
`$orginfo= $(Write-PowerShellHashtable -InputObject $orginfo )
" + {
                           
$headerContent = 
    if ($pageHeaderImage) {
        "<img src='Assets/$pageHeaderImage' style='width:100%' />        
        "    
    } else {
        "<h1 style='text-align:center;font-size:xx-large;backgroundcolor:$curtainColor'>        
            $pageTitle
        </h1>
        "
    }
        
        
$showCommandOutputIfLoggedIn = {
    param($cmdName, [Hashtable]$CmdParameter = @{}) 
    if ($session['User']) {
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        $commandInfo = Get-Command $cmdName        
        & $commandInfo @CmdParameter | Out-HTML
    } elseif ($request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        Write-Link -Caption "Login as $($request.Cookies["$($module.Name)_ConfirmationCookie"]["Email"])?" -Url "Module.ashx?Login=true" |
        New-Region -LayerId "ShouldILogin_For_$cmdName" -Style @{
            'margin-left' = $MarginPercentLeftString
            'margin-right' = $MarginPercentRightString
        }
    } else { @"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@
    }
}

$showCommandInputIfLoggedIn = { param($cmdName) 
    if ($session['User']) {
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        Request-CommandInput -CommandMetaData (Get-Command $cmdName) -Action "$cmdName/?" 
    } elseif ($request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        $out = ""
        $out += Write-Link -Caption "Login as $($request.Cookies["$($module.Name)_ConfirmationCookie"]["Email"])?" -Url "Module.ashx?Login=true" |
            New-Region -LayerId "ShouldILogin_For_$cmdName" -Style @{
                'margin-left' = $MarginPercentLeftString
                'margin-right' = $MarginPercentRightString
            }
        $out
    } else { @"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@
    }
}


$editProfileIfLoggedIn = { 
    if ($session['User']) {
        @"
<div id='editProfileHolder'>    
    
</div>
<script>
    query = 'Module.ashx?editProfile=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#editProfileHolder').html(data);
            } 
        })
    })
</script>
"@
    } elseif ($request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        $out = ""
        $out += Write-Link -Caption "Login as $($request.Cookies["$($module.Name)_ConfirmationCookie"]["Email"])?" -Url "Module.ashx?Login=true" |
            New-Region -LayerId "ShouldILogin_For_$cmdName" -Style @{
                'margin-left' = $MarginPercentLeftString
                'margin-right' = $MarginPercentRightString
            }
        $out
    } else { @"
<div id='loginToEditProfile'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            success: function(data){     
                `$('#loginToEditProfile').html(data);
            } 
        })
    })
</script>
"@
    }
}
    
$header = 
    $headerContent |
        New-Region -LayerID InnerHeader -Style @{
            "margin-left" = "auto"
            "margin-right" = "auto"
            "background-color" = $curtainColor
            "color" = $bgColor
            "width" = '100%'
        } | 
        New-Region -LayerID OuterHeader -Style @{                
            "margin-left" = "5%"
            "margin-right" = "5%"
        } 


$layers = @{}
foreach ($scene in $scenes.GetEnumerator()) {
    $layers[$scene.Key] = 
        if ($scene.Value.Id) {
            $storageAccount = Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageAccountSetting
            $storageKey = Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageKeySetting
            $part, $row = $scene.Value.Id -split ":"
            Show-WebObject -Table $pipeworksManifest.Table.Name -Part $part -Row $row
        } elseif ($scene.Value.Content) {        
            $scene.Value.Content
        } elseif ($scene.Value.Command) {
            $cmdObj = Get-Command $scene.Value.Command
            if ($scene.Value.CollectInput) {
                if ($pipeworksManifest.WebCommand.($cmdObj.Name).RequireLogin -or 
                    $scene.Value.RequireLogin) {
                    
                    & $showCommandInputIfLoggedIn ($cmdObj.Name) 
                } else {
                    Request-CommandInput -CommandMetaData $cmdObj.Name -Action "$($cmdObj.Name)/" -DenyParameter $pipeworksManifest.WebCommand.($cmdObj.Name)       
                }
            } else {
                $getParameters = @{}
                if ($scene.Value.QueryParameter) {   
                    
                    foreach ($qp in $scene.Value.QueryParameter.GetEnumerator()) {
                        
                        if ($request[$qp.Key]) {
                            $getParameters += @{$qp.Value.Trim()=$request[$qp.Key].Trim()}
                        }
                        
                    }        
                    
                }
                
                if ($scene.Value.DefaultParameter) {
                    
                    foreach ($qp in $scene.Value.DefaultParameter.GetEnumerator()) {
                        $getParameters += @{$qp.Key=$qp.Value}                        
                    }
                }
                
                if ($getParameters.Count) {
                    if ($pipeworksManifest.WebCommand.($cmdObj.Name).RequiresLogin -or 
                        $kv.Value.RequireLogin) {
                        & $showCommandOutputIfLoggedIn ($cmdObj.Name) $getParameters | Out-HTML
                    } else {            
                        & $cmdObj @getParameters | Out-HTML
                    }
                } else {
                    ''
                }                
            }
           
            
               
        } elseif ($scene.Value.EditProfile -and $session['User']) {
            $displayName = $scene.Value.EditProfile
            $layers.Layer[$displayName] = & $editProfileIfLoggedIn        
        }
}



$style = @{
    border = "1px $curtainColor solid"
    'background-color' = "$stageColor"
    "margin-left" = "5%"
    "margin-right" = "5%"
    
}

$browserSpecificStyle =
    if ($Request.UserAgent -clike "*IE*") {
        @{'height'='60%';"margin-top"="-5px"}
    } else {
        @{'min-height'='60%'}
    }  
    
$style += $browserSpecificStyle

$LayerOrder = if ($sceneOrder) {
    $sceneOrder
} else {
    $layers.Keys | Sort-Object
}

$content = 
    New-Region -LayerID MainContent -AsPopIn -Order $layerOrder -Layer $layers -MenuBackgroundColor $curtainColor -Style $style

$footer = if ($orgInfo.Count) {
    "<p text-align='center' style='background-color:$curtainColor'>
<span itemprop='Address'>$($orgInfo.Address)</span> | <span itemprop='telephone'>$($orgInfo.telephone)</span><br><span style='font-size:xx-small'><span itemprop='name'>$($orgInfo.Name)</span> | Copyright $((Get-Date).Year)
</span></p>"
} else {
    " "
}

$footer = $footer| 
    New-Region -LayerID Footer -ItemType http://schema.org/Organization -Style @{
        "margin-left" = "5%"
        "margin-right" = "5%"  
        
        "background-color" = $curtaincolor
        "Color" = $stageColor
        "padding" = "10px"          
        "text-align" = "center"
    }
    
    
    
$header, $content, $footer | 
    New-WebPage -Css @{
        Body = @{
            "background-color" = $bgColor
            "font" = $fontName
        }
    } -Title "$pageTitle"
            
            } 
            
            if (-not $ouputPages.Count) {
                $outputPages["default.pspage"] = "<| $pageScript  |>"
            }
            $outputPages["$pageName.pspage"] = "<| $pageScript  |>"
                        
        }       
        
        $outputPages                         
        
        
                                           
    }        
} 
 

