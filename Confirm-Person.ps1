function Confirm-Person
{
    <#
    .Synopsis
        Confirms that the person actually exists
    .Description
        Confirms that a person actually exists and modifies users records.        
    .Example
        # Confirm-Person is automatically called within a web site in the following manner
        Confirm-Person -WebsiteUrl 'http://MyPipeworksSite.com/'
    .Link
        Get-Person
    #>
    [CmdletBinding(DefaultParameterSetName="ConfirmOnlineUser")]
    [OutputType([string], [PSObject])]
    param(
    # Confirms that a facebook access token allows access to facebook
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByFacebookAccessToken')]
    [string]$FacebookAccessToken,

    # Confirms that a live ID user exists by an access token.
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByLiveIDAccessToken')]
    [string]$LiveIDAccessToken,

    # The Live Connect code.  Used when confirming that a live ID user exists by an OAuth code, appID, and redirectURL.
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByLiveIDCodeAndRedirectUrl')]
    [string]$LiveConnectCode,


    # The Live Connect secret setting.  Used when confirming that a live ID user exists by an OAuth code, appID, and redirectURL.
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByLiveIDCodeAndRedirectUrl')]
    [string]$LiveConnectSecretSetting,


    # The Live Connect redirect URL.  Used when confirming that a live ID user exists by code, clientID, and redirectURL.
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByLiveIDCodeAndRedirectUrl')]
    [string]$LiveConnectRedirectUrl,

    # The Live Connect ClientID.  Used when confirming that a live ID user exists by code, clientID, and redirectURL.
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByLiveIDCodeAndRedirectUrl')]
    [string]$LiveConnectAppID,

    # The FaceBook app ID
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmByFacebookAccessToken')]
    [string]$FacebookAppId,
    
    # The user table where the account record is stored
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByApiKey')]
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByEmail')]
    [String]$UserTable,
    

    # The ConnectionSetting.  This is used to handle the connection string for a User Database
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByApiKey')]
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByEmail')]
    [Alias('ConnectionString')]
    [String]$ConnectionSetting,
    
    # The user partition where the account record is stored
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]

    [String]$UserPartition = "Users",
    
    # The lockout balance (the point at which users can no longer log in)
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByApiKey')]
    [Double]$LockoutBalance = -10.00,

    # The initial balance attached to a user account when it is created
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter( ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByApiKey')]
    [Double]$InitialBalance = 0,
    
    # The Azure storage key setting
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter(ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]
    [string]$StorageAccountSetting = "AzureStorageAccountName",
    
    # The Azure storage key setting
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [string]$StorageKeySetting = "AzureStorageAccountKey",
    
    # The email with changes to the account
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByEmail')]
    [string]$Email,   
    
    # The phone number used to confirm the account
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [string]$PhoneNumber,   
    
    # The ApiKey used to confirm the account
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKey')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndExchange')]
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByApiKey')]
    [string]$ApiKey,          
    
    # If set, will confirms the api key via email (if not already done on this machine)
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndExchange')]
    [Switch]$ConfirmByEmail,       
    
    # The email server used to send the confirmation mails
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [string]$SmtpServer,  
    
    # The email address used to send confirmation mails (in a pure email based user system)
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [string]$FromEmail,       
    
    # The setting containing the SMTP email used to send confirmation mails (in a pure email based user system)
    [Parameter( 
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [string]$SmtpEmailSetting = "SmtpEmail",
    
    # The setting containing the SMTP password used to send confirmation mails (in a pure email based user system)
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByApiKeyAndSmtp')]
    [string]$SmtpPasswordSetting = "SmtpPassword",           
            
    # If set, the number will be treated as a mobile phone, and confirmation will occur via Text
    [Parameter(ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Switch]$IsMobilePhone,   
    
    # The Person Object
    [Parameter(ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByPhone')]
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInAzureByEmail')]
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ConfirmPersonInSQLByEmail')]
    [PSObject]
    $PersonObject,
    
    
    
    # The URL for the website
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$WebsiteUrl,
    
    # Determines if the user is logged in as a fixed set of options.
    [Parameter(ParameterSetName='ConfirmIdentityFromFixedListOrTable')]
    [string[]]$IfLoggedInAs,
    
    # A partition in table storage that contains user groupings
    [Parameter(ParameterSetName='ConfirmIdentityFromFixedListOrTable')]
    [string]$ValidUserPartition,
    
    # If set, will validate that they are a specific user, not just a user
    [Parameter(Mandatory=$true,ParameterSetName='ConfirmIdentityFromFixedListOrTable')]    
    [Switch]$CheckId)
    
    process {
        $sitename = 
            if ($module -and $module.Name) {
                $module.Name
            } else {
                "Website"
            }


        $finalUrl = if ($WebSiteUrl -like "*Module.ashx") {
            $WebSiteUrl 
        } else {
            $websiteUrl = "$WebSiteUrl".TrimEnd("/") + "/Module.ashx"
        }
        
        if ($psCmdlet.ParameterSetName -eq 'ConfirmOnlineUser') {
            # The default parameter set tries to be "smart".  
            # If it's called locally (without $Request, $Response, and $Session)
            # It will barf, but if called within a module, will check the appropriate cookies 
            # to log the user in or display the appropriate prompts                                                                                                                       
            
            
            
            
            
            if ($session -and $session['User']) {
                # If they're already logged in, simply show it
                
                "Logged in as <a href='/Profile/'>$($session['User'].Name)</a>"
            
            } elseif ($Request -and $Request["REMOTE_USER"]) {
                # Logged on via some integrated authentication mechanism
                $parts = @($request["REMOTE_USER"] -split "[\\/]")
                $alias = $parts[-1]
                $domain = $parts[0]
                $personExists =Get-Person -Alias $alias -domain $domain # -ErrorAction SilentlyContinue
                
                
                if ($personExists) {
                    $personExists.pstypenames.clear()
                    $personExists.pstypenames.add('http://schema.org/Person')
                    $uid = if ($personExists.Sid) {
                        ($personExists| 
                            Select-Object -ExpandProperty Sid | 
                            ForEach-Object { "{0:x}" -f $_ })-join ''
                    } elseif ($personExists.ObjectSid) {
                        ($personExists| 
                            Select-Object -ExpandProperty ObjectSid | 
                            ForEach-Object { "{0:x}" -f $_ })-join ''
                    }
                    $session['User'] = $personExists |
                        Add-Member NoteProperty UserId $uid -force -PassThru
                    
                    "Logged in as <a href='/Profile/'>$($session['User'].Name)</a>"
                    
                    # If they've supplied a user table, we need to create a record here or 
                    # various things within the system will break
                    if ($pipeworksManifest.UserDB.Name -and $pipeworksManifest.UserDB.ConnectionSetting) {
                        $connSetting = $pipeworksManifest.UserDB.ConnectionSetting
                        $userExists = 
                            Select-SQL -FromTable $pipeworksManifest.UserDB.Name -Where "UserID = '$uid'" -ConnectionStringOrSetting $connSetting -ErrorAction SilentlyContinue

                        if ($userExists) {
                            # Update them
                            $primaryApiKey = $userExists.PrimaryApiKey
                            $secondaryApiKey = $userExists.SecondaryApiKey                                                
                    
                
                            $lockedOut = $false
                            $lockOutReason =  ""
                            if ($LockoutBalance) {
                                # If there's a lockout balance and they have exceeed it, bounce
                                
                                if (($userExists.Balance -as [Double]) -lt ($LockoutBalance -as [Double])) {
                                    # Locked out    
                                    $lockedOut = $true
                                    $lockOutReason  = "You owe $($userExists.balance)"
                                }
                            }
                
                            if (-not $lockedOut) {                                        
                                $session["User"] = $personExists |                         
                                    Add-Member NoteProperty UserId "$Uid" -PassThru -Force | 
                                    Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force |
                                    Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -PassThru -Force
                                
                                $session["User"] |
                                    Update-Sql -Force -TableName $pipeworksManifest.UserDB.Name -ConnectionStringOrSetting $connSetting -RowProperty UserID 
                            }                                                            
                        } else {
                            # Create them
                            $primaryApiKey = [Guid]::NewGuid()
                            $secondaryApiKey = [Guid]::NewGuid()
                            $session["User"] = $personExists |
                                Add-Member NoteProperty UserId "$Uid" -PassThru -Force | 
                                Add-Member NoteProperty PrimaryApiKey "$primaryApiKey" -PassThru -Force | 
                                Add-Member NoteProperty SecondaryApiKey "$SecondaryApiKey" -PassThru -Force |                                 
                                Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force  |
                                Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -Force -PassThru 
                            
                            if ($InitialBalance) {
                                $session["User"] = $session["User"] | 
                                    Add-Member NoteProperty Balance $InitialBalance -Force -PassThru
                            } 
                                
                            $session["User"] |
                                Update-Sql -Force -TableName $pipeworksManifest.UserDB.Name -ConnectionStringOrSetting $connSetting -RowProperty UserID
                        }
                    } elseif ($pipeworksManifest.UserTable.Name) {
                        
                        $azureStorageAccount = Get-SecureSetting $pipeworksManifest.UserTable.StorageAccountSetting -ValueOnly
                        $azureStorageKey= Get-SecureSetting $pipeworksManifest.UserTable.StorageKeySetting   -ValueOnly
                        $userTable = $pipeworksManifest.UserTable.Name                                                 
                        $userExists = 
                            Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -Filter "PartitionKey eq '$($pipeworksManifest.UserTable.Partition)' and RowKey eq '$uid'" -StorageAccount $azureStorageAccount -StorageKey $azureStorageKey
                        
                        if ($userExists) {
                            # Update them
                            $session["User"] = $userExists
                            $primaryApiKey = $userExists.PrimaryApiKey
                            $secondaryApiKey = $userExists.SecondaryApiKey                                                
                    
                
                            $lockedOut = $false
                            $lockOutReason =  ""
                            if ($LockoutBalance) {
                                # If there's a lockout balance and they have exceeed it, bounce
                                
                                if (($userExists.Balance -as [Double]) -lt ($LockoutBalance -as [Double])) {
                                    # Locked out    
                                    $lockedOut = $true
                                    $lockOutReason  = "You owe $($userExists.balance)"
                                }
                            }
                
                            if (-not $lockedOut) {                                        
                                $session["User"] = $userExists |                         
                                    Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force |
                                    Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -PassThru -Force
                                
                                $session["User"] |
                                    Update-AzureTable -TableName $UserTable -Value  {$_ }
                            }                                                            
                        } else {
                            # Create them
                            $primaryApiKey = [Guid]::NewGuid()
                            $secondaryApiKey = [Guid]::NewGuid()
                            $session["User"] = $personExists |
                                Add-Member NoteProperty UserId "$Uid" -PassThru -Force | 
                                Add-Member NoteProperty PrimaryApiKey "$primaryApiKey" -PassThru -Force | 
                                Add-Member NoteProperty SecondaryApiKey "$SecondaryApiKey" -PassThru -Force |                                 
                                Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force  |
                                Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -Force -PassThru 
                            
                            if ($InitialBalance) {
                                $session["User"] = $session["User"] | 
                                    Add-Member NoteProperty Balance $InitialBalance -Force -PassThru
                            } 
                                
                            $session["User"] = $session["User"] |
                                Set-AzureTable -TableName $pipeworksManifest.UserTable.Name -PartitionKey $pipeworksManifest.UserTable.Partition -RowKey $uid  -PassThru
                        }
                        
                    }
                
                                                                
                    
                    
                }
                
            } elseif ($Request -and $request["AppKey"]) {
                $appKey = $Request["AppKey"]

                if ($pipeworksManifest.UserDB.Name) {
                        $connSetting = $pipeworksManifest.UserDB.ConnectionSetting
                        $userExists = 
                            Select-SQL -FromTable $pipeworksManifest.UserDB.Name -Where "SecondaryApiKey = '$AppKey'" -ConnectionStringOrSetting $connSetting -ErrorAction SilentlyContinue

                        if ($userExists) {
                            # Update them
                            $primaryApiKey = $userExists.PrimaryApiKey
                            $secondaryApiKey = $userExists.SecondaryApiKey                                                
                    
                
                            $lockedOut = $false
                            $lockOutReason =  ""
                            if ($LockoutBalance) {
                                # If there's a lockout balance and they have exceeed it, bounce
                                
                                if (($userExists.Balance -as [Double]) -lt ($LockoutBalance -as [Double])) {
                                    # Locked out    
                                    $lockedOut = $true
                                    $lockOutReason  = "You owe $($userExists.balance)"
                                }
                            }
                
                            if (-not $lockedOut) {                                        
                                $session["User"] = $userExists |                         
                                    Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force |
                                    Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -PassThru -Force
                                
                                $session["User"] |
                                    Update-Sql -Force -TableName $pipeworksManifest.UserDB.Name -ConnectionStringOrSetting $connSetting -RowProperty UserID
                            }                                                            
                        } else {
                            # Create them
                            $primaryApiKey = [Guid]::NewGuid()
                            $secondaryApiKey = [Guid]::NewGuid()
                            $session["User"] = $personExists |
                                Add-Member NoteProperty UserId "$Uid" -PassThru -Force | 
                                Add-Member NoteProperty PrimaryApiKey "$primaryApiKey" -PassThru -Force | 
                                Add-Member NoteProperty SecondaryApiKey "$SecondaryApiKey" -PassThru -Force |                                 
                                Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force  |
                                Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -Force -PassThru 
                            
                            if ($InitialBalance) {
                                $session["User"] = $session["User"] | 
                                    Add-Member NoteProperty Balance $InitialBalance -Force -PassThru
                            } 
                                
                            $session["User"] |
                                Update-Sql -Force -TableName $pipeworksManifest.UserDB.Name -ConnectionStringOrSetting $connSetting -RowProperty UserID
                        }
                    } elseif ($pipeworksManifest.UserTable -and 
                    $pipeworksManifest.UserTable.StorageAccountSetting -and
                    $pipeworksManifest.UserTable.StorageKeySetting)  {
                    $storageAccountSetting = $pipeworksManifest.UserTable.StorageAccountSetting
                    $StorageKeySetting = $pipeworksManifest.UserTable.StorageKeySetting


                    $azureStorageAccount = Get-SecureSetting $pipeworksManifest.UserTable.StorageAccountSetting -ValueOnly
                    $azureStorageKey= Get-SecureSetting $pipeworksManifest.UserTable.StorageKeySetting   -ValueOnly
                    $userTable = $pipeworksManifest.UserTable.Name                                                 
                    $userExists = 
                        Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -Filter "PartitionKey eq '$($pipeworksManifest.UserTable.Partition)' and SecondaryApiKey eq '$AppKey'" -StorageAccount $azureStorageAccount -StorageKey $azureStorageKey

                    if ($userExists) {
                        # Update them
                        $primaryApiKey = $userExists.PrimaryApiKey
                        $secondaryApiKey = $userExists.SecondaryApiKey                                                
                    
                
                        $lockedOut = $false
                        $lockOutReason =  ""
                        if ($LockoutBalance) {
                            # If there's a lockout balance and they have exceeed it, bounce
                                
                            if (($userExists.Balance -as [Double]) -lt ($LockoutBalance -as [Double])) {
                                # Locked out    
                                $lockedOut = $true
                                $lockOutReason  = "You owe $($userExists.balance)"
                            }
                        }
                
                        if (-not $lockedOut) {                                        
                            $session["User"] = $userExists |                         
                                Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force |
                                Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -PassThru -Force
                                
                            $session["User"] |
                                Update-AzureTable -TableName $UserTable -Value  {$_ } 
                        }                                                            
                    }
                }
                
                
             } elseif ($Request -and 
                $pipeworksManifest.Facebook.AppId -and 
                $request.Cookies["FBAT_For_$($pipeworksManifest.Facebook.AppId)"]) {
                
                
                # If facebook login is allowed, and an AccessToken exists, try that                
                
                $fbat = $request.Cookies["FBAT_For_$($pipeworksManifest.Facebook.AppId)"]                                
                Confirm-Person -FacebookAccessToken $fbat -FacebookAppId $pipeworksManifest.Facebook.AppId -WebsiteUrl $websiteUrl
                
   
            } elseif ($Request -and 
                $pipeworksManifest.LiveConnect.ClientId -and 
                $request.Cookies["LiveConnectAccessToken_For_$($pipeworksManifest.LiveConnect.ClientId)"]) {
                
                
                # If facebook login is allowed, and an AccessToken exists, try that                
                
                $lat = $request.Cookies["LiveConnectAccessToken_For_$($pipeworksManifest.LiveConnect.ClientId)"]
                Confirm-Person -LiveIDAccessToken $lat -WebsiteUrl $WebsiteUrl
                
   
            } elseif ($Request -and 
                $pipeworksManifest.LiveConnect.ClientId -and 
                $request["LiveConnectAccessToken"]) {
                
                
                
                Confirm-Person -LiveIDAccessToken $request["LiveConnectAccessToken"] -WebsiteUrl $WebsiteUrl
                
   
            } elseif ($Request -and 
                $pipeworksManifest.LiveConnect.ClientId -and 
                $request.Cookies -and 
                $request.Cookies["LiveConnectCode_For_$($pipeworksManifest.LiveConnect.ClientID)"]) {


                $code = $request.Cookies["LiveConnectCode_For_$($pipeworksManifest.LiveConnect.ClientID)"]

                $redirectUrl = if ($pipeworksManifest.LiveConnect.RedirectUrl) {
                    $pipeworksManifest.LiveConnect.RedirectUrl
                } else {
                    $WebsiteUrl
                }

                $secretSetting = if ($pipeworksManifest.LiveConnect.ClientSecretSetting) {
                    $pipeworksManifest.LiveConnect.ClientSecretSetting
                } else {
                    " "
                }

                Confirm-Person -LiveConnectCode $code -LiveConnectRedirectUrl $redirectUrl -LiveConnectAppID $pipeworksManifest.LiveConnect.ClientId -LiveConnectSecretSetting $secretSetting -WebsiteUrl $WebsiteUrl
            } elseif ($Request -and ($PipeworksManifest.Facebook.AppId -or $pipeworksManifest.LiveConnect)) {

                if ($pipeworksManifest.LiveConnect.ClientID) {
                    $scope = if ($pipeworksManifest -and $pipeworksManifest.LiveConnect.Scope) {
                        @($pipeworksManifest.LiveConnect.Scope) + "wl.emails" + "wl.signin" | 
                            Select-Object -Unique
                    } else {
                        "wl.emails", "wl.signin"
                    }


                    $liveServiceUrl = if ($pipeworksManifest.LiveConnect.RedirectUrl) {
                        $pipeworksManifest.LiveConnect.RedirectUrl
                    } else {
                        $WebsiteUrl
                    }

                    Write-Link -ToLiveConnectLogin -LiveConnectScope $scope -ModuleServiceUrl $liveServiceUrl -LiveConnectClientId $pipeworksManifest.LiveConnect.ClientID
                } elseif ($PipeworksManifest.Facebook.AppId) {
                    # Alternatively, if we have the appId, let's try making a login link
                    
                    $scope = if ($pipeworksManifest -and $pipeworksManifest.Facebook.Scope) {
                        @($pipeworksManifest.Facebook.Scope) + "email" + "user_birthday" | 
                            Select-Object -Unique
                    } else {
                        "email", "user_birthday"
                    }


                    if ($pipeworksManifest.Facebook.AppSecretSetting) {
                        Write-Link -ToFacebookLogin -FacebookAppId $PipeworksManifest.Facebook.AppId -FacebookLoginScope $scope -ModuleServiceUrl $WebsiteUrl -UseOAuth
                    } else {
                        Write-Link -ToFacebookLogin -FacebookAppId $PipeworksManifest.Facebook.AppId -FacebookLoginScope $scope -ModuleServiceUrl $WebsiteUrl 
                    }
                }
                
                
                
                                
                
            
            } elseif ($Request -and 
                $request.Cookies["${sitename}_ConfirmationCookie"]) {
                $confirmCookie = $request.Cookies["${sitename}_ConfirmationCookie"]
                
                # If they have a confirmation cookie, then it's an email based system.
                # Try logging in with that cookie
                
                $userTable = @{} + $pipeworksManifest.UserTable
                $userTable.Remove("Name")
                $userTable.UserTable = $pipeworksManifest.UserTable.Name

                New-Object PSObject -Property $userTable |
                    Confirm-Person -WebsiteUrl $websiteUrl -ApiKey "$($confirmCookie.Values['Key'])" -ConfirmByEmail
            } elseif ($PipeworksManifest.UserTable.SmtpServer) {
                # SMTP based membership system with no login information found
                $userTable = @{} + $pipeworksManifest.UserTable
                $userTable.Remove("Name")
                $userTable.UserTable = $pipeworksManifest.UserTable.Name
                if (-not $userTable.WebsiteUrl) {
                    $userTable.WebsiteUrl = $websiteUrl
                }
                
                
                $signup = New-Object PSObject -Property $userTable | 
                    Join-Website 
                    
                New-Region -LayerID LoginToOrJoinWebsite -AsPopdown -Style @{
                    "float" = "right"
                } -Layer @{
                    "Login / Sign Up" = $signup 
                }                
            }
            
            if ($Request -and $request.Params["ReturnTo"]) {
                $returnUrl = [Web.HttpUtility]::UrlDecode($request.Params["ReturnTo"])
                New-WebPage -title "Welcome to $($module.Name)" -RedirectTo $returnUrl |
                    Out-HTML -WriteResponse
            }
                        
            
            
        } elseif ('ConfirmIdentityFromFixedListOrTable' -eq $psCmdlet.ParameterSetName) {
            
            
            $okIf = @()
            # ValidateUserTable preceeds IfLoggedInAs, and $ok is set first.
            # this way, logins in tables work as well as specific whitelists                                        
            if ($ValidUserPartition) {
                $storageAccount = Get-SecureSetting $pipeworksManifest.UserTable.StorageAccountSetting -ValueOnly
                $storageKey = Get-SecureSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting -ValueOnly
                $okUserList = 
                    Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -Filter "PartitionKey eq '$($ValidUserPartition)' and IfLoggedInAs ne ''" -StorageAccount $storageAccount -StorageKey $storageKey  
                $okUserIf = $okUserList | 
                    Select-Object -ExpandProperty IfLoggedInAs
                
                $okIf += $okUserIf    
            }
            
            if ($IfLoggedInAs) {
                $okIf += $IfLoggedInAs                    
            }
            
            if ($okIf) {
                $ok = $false
                foreach ($if in $okIf) {
                    if ($if -eq '*') {
                        if ($session["User"]) {
                            $ok = $true
                            break
                        }
                    }
                    if ($if -like "*@*") {
                        # Email
                        if ($session["User"].UserEmail -like $if)  {
                            $ok = $true
                            break
                        }
                    }  elseif ($if -like "*:*") {
                        $ifParts = $if -split ':'
                        if ($ifParts[0] -ieq 'memberOf') {
                            if ($session['User'].MemberOf -and $session['User'].MemberOf -like "*$($ifParts[1])*") {
                                $ok = $true
                                break
                            }
                            $global:notOkReason = "Not Member Of $($ifParts[1])"
                        } elseif ($ifParts[0] -ieq 'notMemberOf') {
                            if ($session['User'].MemberOf -and $session['User'].MemberOf -notlike "*$($ifParts[1])*") {
                                $ok = $true
                                break
                            }
                            $global:notOkReason = "Member Of $($ifParts[1])"
                        } elseif ($ifParts[0] -ieq 'awarded') {
                            $awards = $session["User"].Awards -split ';'
                            if ($awards -like "$($ifParts[1])") {
                                $ok = $true
                                break
                            }
                        } elseif ($ifParts[0] -ieq 'notAwarded') {
                            $awards = $session["User"].Awards -split ';'
                            
                            if (-not ($awards -like "$($ifParts[1])")) {
                                $ok = $true
                                break
                            }
                        } elseif ($ifParts[0] -ieq 'interactionCount') {
                            $interactionCountOperations = if ($ifParts[1] -like "*>=*") {
                                if ($session['User'].InteractionCount) {
                                    $interactionCountData = ConvertFrom-StringData -StringData "$($session['User'].InteractionCount)".Replace(':', '=') -ErrorAction SilentlyContinue
                                    $equation = $ifParts[1] -split "\>="

                                    if (($interactionCountData[$equation[0].Trim()] -as [double]) -ge ($equation[1] -as [double])) {
                                        $ok=$true
                                        break
                                    }
                                } 
                                
                                
                            } elseif ($ifParts[1] -like "*>*") {
                                if ($session['User'].InteractionCount) {
                                    $interactionCountData = ConvertFrom-StringData -StringData "$($session['User'].InteractionCount)".Replace(':', '=') -ErrorAction SilentlyContinue
                                    $equation = $ifParts[1] -split "\>"

                                    if (($interactionCountData[$equation[0].Trim()] -as [double]) -gt ($equation[1] -as [double])) {
                                        $ok=$true
                                        break
                                    }
                                } 
                                
                                
                            } if ($ifParts[1] -like "*<=*") {
                                if ($session['User'].InteractionCount) {
                                    $interactionCountData = ConvertFrom-StringData -StringData "$($session['User'].InteractionCount)".Replace(':', '=') -ErrorAction SilentlyContinue
                                    $equation = $ifParts[1] -split "\<="

                                    if (($interactionCountData[$equation[0].Trim()] -as [double]) -le ($equation[1] -as [double])) {
                                        $ok=$true
                                        break
                                    }
                                }                                                                 
                            } elseif ($ifParts[1] -like "*<*") {
                                if ($session['User'].InteractionCount) {
                                    $interactionCountData = ConvertFrom-StringData -StringData "$($session['User'].InteractionCount)".Replace(':', '=') -ErrorAction SilentlyContinue
                                    $equation = $ifParts[1] -split "\<"

                                    if (($interactionCountData[$equation[0].Trim()] -as [double]) -lt ($equation[1] -as [double])) {
                                        $ok=$true
                                        break
                                    }
                                }
                            }
                        }
                    } else {
                        if ($session["User"].UserId -eq $if) {
                            $ok = $true
                            break
                        }
                    }
                }
                
                if (-not $ok) {  return } 
            }
                                    
            
            return $ok        
        } elseif ('ConfirmIdentityFromTable' -eq $psCmdlet.ParameterSetName) {
            
        } elseif ('ConfirmPersonInAzureByEmail', 
            'ConfirmPersonInAzureByPhone',
            'ConfirmPersonInAzureByApiKey',
            'ConfirmPersonInAzureByApiKeyAndSmtp',
            'ConfirmPersonInAzureByApiKeyAndExchange',
            'ConfirmPersonInSqlByApiKey', 
            'ConfirmPersonInSqlByEmail'-contains $pscmdlet.ParameterSetName) {


            if ($psCmdlet.ParameterSetName -like "*azure*") {
                $azureStorageAccount = Get-SecureSetting -Name $StorageAccountSetting -ValueOnly
                $azureStorageKey= Get-SecureSetting -Name $StorageKeySetting -ValueOnly
            
                $findUser = @{
                    TableName = $UserTable
                    Filter = 
                        "PartitionKey eq '$($UserPartition)'"
                    storageAccount=
                        $azureStorageAccount
                    StorageKey=
                        $azureStorageKey
                }
            
                if ($Email) {
                    $FindUser.Filter += " and UserEmail eq '$($Email)'"
                } elseif ($PhoneNumber) {
                    $FindUser.Filter += " and PhoneNumber eq '$($PhoneNumber)'"
                } elseif ($ApiKey) {
                    $FindUser.Filter += " and SecondaryApiKey eq '$($ApiKey)'"
                }
            
            
            
                $userExists = 
                    Search-AzureTable @findUser
            } elseif ($psCmdlet.ParameterSetName -eq "ConfirmPersonInSqlByApiKey") {
                $userExists =
                    Select-SQL -Query "Select * From $UserTable Where SecondaryAPIKey = '$($apiKey.Replace("'","''").TrimEnd("\").TrimEnd("/").Replace(';',''))'" -ConnectionStringOrSetting $ConnectionSetting -ErrorAction SilentlyContinue
            } elseif ($psCmdlet.ParameterSetName -eq "ConfirmPersonInSqlByEmail") {
                $userExists =
                    Select-SQL -Query "Select * From $UserTable Where UserEmail = '$($Email.Replace("'","''").TrimEnd("\").TrimEnd("/").Replace(';',''))'" -ConnectionStringOrSetting $ConnectionSetting -ErrorAction SilentlyContinue
            }
            
            
            if ($userExists) {
                            
                # Update them
                $primaryApiKey = $userExists.PrimaryApiKey
                $secondaryApiKey = $userExists.SecondaryApiKey                                                
                    
                
                $lockedOut = $false
                $lockOutReason =  ""
                if ($LockoutBalance) {
                    # If there's a lockout balance and they have exceeed it, bounce
                    
                    if (($userExists.Balance -as [Double]) -lt ($LockoutBalance -as [Double])) {
                        # Locked out    
                        $lockedOut = $true
                        $lockOutReason  = "You owe $($userExists.balance)"
                    }
                }


                # Add on existing properties from the person object
                foreach ($property in $personObject.psobject.Properties) {
                    if ($property.Name -and $property.Value) {
                        
                        Add-Member NoteProperty -InputObject $userExists -Name $property.Name -Value $property.Value -Force 
                    }
                }

                $userExists.pstypenames.clear()
                $userExists.pstypenames.add('http://schema.org/Person')
                
                if (-not $lockedOut) {
                    if ($session) {
                        
                        $session["User"] = $userExists |                         
                            Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force |
                            Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -PassThru -Force
                        
                        if ($psCmdlet.ParameterSetName -like "*azure*") {
                            $session["User"] |
                                Update-AzureTable -TableName $UserTable -Value  {$_ }
                        } elseif ($psCmdlet.ParameterSetName -like "*sql*") {
                            $session["User"] |
                                Update-Sql -TableName $UserTable -ConnectionStringOrSetting $ConnectionSetting -Force -RowProperty UserID
                        }
                        
                    
                    } else {
                        if ($psCmdlet.ParameterSetName -like "*azure*") {
                            $session["User"] |
                                Update-AzureTable -TableName $UserTable -Value  {$_ }
                        } elseif ($psCmdlet.ParameterSetName -like "*sql*") {
                            $session["User"] |
                                Update-Sql -TableName $UserTable -ConnectionStringOrSetting $ConnectionSetting -Force -RowProperty UserID
                        }
                    }
                }
                
                
                if ($apiKey -and 
                    $request -and
                    ('ConfirmPersonInAzureByApiKeyAndSmtp', 'ConfirmPersonInAzureByApiKeyAndExchange' -contains $psCmdlet.ParameterSetName)) {
                    
                    $userIsConfirmed = $userFound |
                        Where-Object {
                            $_.Confirmed -ilike "*$true*" 
                        }
                        
                    $userIsConfirmedOnThisMachine = $userIsConfirmed |
                        Where-Object {
                            $_.ConfirmedOn -ilike "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })"
                        }
                        
                    $sendMailParams = @{
                        BodyAsHtml = $true
                        To = $newUserObject.UserEmail
                    }
                    
                    $sendMailCommand = 
                        if ($psCmdlet.ParameterSetName -eq 'ConfirmPersonInAzureByApiKeyAndSmtp') {
                            $($ExecutionContext.InvokeCommand.GetCommand("Send-MailMessage", "All"))
                            $un  = Get-WebConfigurationSetting -Setting $SmtpEmailSetting
                            $pass = Get-WebConfigurationSetting -Setting $SmtpPasswordSetting
                            $pass = ConvertTo-SecureString $pass  -AsPlainText -Force 
                            if (-not $FromEmail) {
                                $FromEmail = $un
                            }
                            
                            $cred = 
                                New-Object Management.Automation.PSCredential ".\$un", $pass 
                            
                            $sendMailParams += @{
                                SmtpServer = $SmtpServer 
                                From = $FromEmail
                                Credential = $cred
                                UseSsl = $useSsl
                            }
                            
                        } elseif ($psCmdlet.ParameterSetName -eq 'ConfirmPersonInAzureByApiKeyAndExchange') {
                            $($ExecutionContext.InvokeCommand.GetCommand("Send-Email", "All"))
                            $sendMailParams += @{
                                UseWebConfiguration = $true
                                AsJob = $true
                            }
                        }
                            
                    if (-not $userIsConfirmedOnThisMachine) {
                        $confirmCode = [guid]::NewGuid()
                        Add-Member -MemberType NoteProperty -InputObject $userIsConfirmed -Name ConfirmCode -Force -Value "$confirmCode"
                        
                        
                        $introMessage = if ($pipeworksManifest.UserTable.IntroMessage) {
                            $pipeworksManifest.UserTable.IntroMessage + "<br/> <a href='${finalUrl}?confirmUser=$confirmCode'>Confirm Email Address</a>"
                        } else {
                            "<br/> <a href='${finalUrl}?confirmUser=$confirmCode'>Confirm Email Address</a>"
                        }
                        
                        $sendMailParams += @{
                            Subject= "Welcome to $($module.Name)"
                            Body = $introMessage
                        }                    
                        
                        
                        & $sendMailcommand @sendMailParams

                        # Send-Email -To $userIsConfirmed.UserEmail -UseWebConfiguration -Subject  -Body $introMessage -BodyAsHtml -AsJob
                        $partitionKey = $userIsConfirmed.PartitionKey
                        $rowKey = $userIsConfirmed.RowKey
                        $tableName = $userIsConfirmed.TableName
                        $userIsConfirmed.psobject.properties.Remove('PartitionKey')
                        $userIsConfirmed.psobject.properties.Remove('RowKey')
                        $userIsConfirmed.psobject.properties.Remove('TableName')                    
                        $userIsConfirmed |
                            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
                        
                        "User Not confirmed on this machine/ IPAddress.  A confirmation mail has been sent to $($userFound.UserEmail)"
                        
                        return
                    } else {
                        $session['User'] = $userIsConfirmedOnThisMachine
                        $session['UserId'] = $userIsConfirmedOnThisMachine.UserId
                        $welcomeBackMessage = $(
                            if ($userIsConfirmedOnThisMachine.Name) {
                                $userIsConfirmedOnThisMachine.Name
                            } else {
                                $userIsConfirmedOnThisMachine.UserEmail
                            }
                        )
                        
                        $secondaryApiKey = "$($confirmCookie.Values['Key'])"                    
                        
                        if ($request.Params["ReturnTo"]) {
                            $returnUrl = [Web.HttpUtility]::UrlDecode($request.Params["ReturnTo"])
                            New-WebPage -title "Welcome to $($module.Name)" -RedirectTo $returnUrl |
                                Out-HTML -WriteResponse
                        }            
                        

                        $partitionKey = $userIsConfirmedOnThisMachine.PartitionKey
                        $rowKey = $userIsConfirmedOnThisMachine.RowKey
                        $tableName = $userIsConfirmedOnThisMachine.TableName
                        $userIsConfirmedOnThisMachine.psobject.properties.Remove('PartitionKey')
                        $userIsConfirmedOnThisMachine.psobject.properties.Remove('RowKey')
                        $userIsConfirmedOnThisMachine.psobject.properties.Remove('TableName')                    
                        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogon -Force -Value (Get-Date)
                        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogonFrom -Force -Value "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })"
                        $userIsConfirmedOnThisMachine |
                            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
                            
                        $session['User'] = $userIsConfirmedOnThisMachine

                        

                        return $welcomeBackMessage 
                        
                                                       
                    }                    
                }
                
                
                
            } else {
                # If they are trying to log in with an ApiKey and the user does not exist, 
                # We don't create a user.  Instead (paradoxically), we create a login cookie,
                # set to expire almost immediately.
                if ($psCmdlet.ParameterSetName -like 'ConfirmPersonInAzureByApiKeyAnd*' -and $Response) {
                    $secondaryApiKey = $session["$($module.Name)_ApiKey"]
                    $confirmCookie = New-Object Web.HttpCookie "$($module.Name)_ConfirmationCookie"
                    $confirmCookie["Key"] = "$secondaryApiKey"
                    $confirmCookie["CookiedIssuedOn"] = (Get-Date).ToString("r")
                    $confirmCookie.Expires = (Get-Date).AddDays(-365)                    
                    $response.Cookies.Add($confirmCookie)
                    $response.Flush()
                    
                    $response.Write("User $($confirmCookie | Out-String) Not Found, ConfirmationCookie Set to Expire")                                                        
                    return
                }
                
                
                
                # Create them
                $primaryApiKey = [Guid]::NewGuid()
                $secondaryApiKey = [Guid]::NewGuid()
                            
                            
                            
                $userId = [Guid]::NewGuid()
                
                if (-not $PersonObject) {
                    $personObject = New-Object PSObject 
                    $personObject.pstypenames.clear()
                    $personObject.pstypenames.add('http://schema.org/Person')
                    
                    if ($email) {
                        $personObject | 
                            Add-Member NoteProperty UserEmail $Email -Force
                    } elseif ($PhoneNumber) {
                        $personObject | 
                            Add-Member NoteProperty PhoneNumber $PhoneNumber -Force
                    }
                }
                
                $PersonObject.pstypenames.clear()
                $PersonObject.pstypenames.add('http://schema.org/Person')
                $session["User"] = $personObject |
                    Add-Member NoteProperty UserId "$UserId" -PassThru -Force | 
                    Add-Member NoteProperty PrimaryApiKey "$primaryApiKey" -PassThru -Force | 
                    Add-Member NoteProperty SecondaryApiKey "$SecondaryApiKey" -PassThru -Force | 
                    Add-Member NoteProperty UserEmail $email -Force -PassThru |
                    Add-Member NoteProperty LastLogon (Get-Date) -PassThru -Force  |
                    Add-Member NoteProperty LastLogonFrom "$(if ($Request) { $Request['REMOTE_ADDR'] + '/' + $request['REMOTE_HOST'] })" -Force -PassThru 
                
                if ($InitialBalance) {
                    $session["User"] = $session["User"] | 
                        Add-Member NoteProperty Balance $InitialBalance -Force -PassThru
                } 
                if ($psCmdlet.ParameterSetName -like "*azure*") {
                    $session["User"] |
                        Set-AzureTable -TableName $pipeworksManifest.UserTable.Name -PartitionKey $pipeworksManifest.UserTable.Partition -RowKey $userId -StorageAccount $azureStorageAccount -StorageKey $azureStorageKey -PassThru
                } elseif ($psCmdlet.ParameterSetName -like "*sql*") {
                    $session["User"] |
                        Update-Sql -TableName $UserTable -Force -RowProperty UserId -ConnectionStringOrSetting $ConnectionSetting
                }                
                
            }
        } elseif ($psCmdlet.ParameterSetName -eq 'ConfirmByLiveIDCodeAndRedirectUrl') {
            $code = $LiveConnectCode

            $appId = $LiveConnectAppID
            $appSecret = Get-SecureSetting $LiveConnectSecretSetting -ValueOnly

            $redirectUri = $LiveConnectRedirectUrl
            $getWebParameters = @{
                url="https://login.live.com/oauth20_token.srf"
                RequestBody = "client_id=$([Web.HttpUtility]::UrlEncode($appId))&redirect_uri=$([Web.HttpUtility]::UrlEncode($redirectUri))&client_secret=$([Web.HttpUtility]::UrlEncode($appSecret.Trim()))&code=$([Web.HttpUtility]::UrlEncode($code.Trim()))&grant_type=authorization_code"
                UseWebRequest  = $true
                Method = "POST"
                AsJson = $true
            }
            
            $result = Get-Web @getWebParameters                
            $token = $result.access_token
            . Confirm-Person -LiveIDAccessToken $token -WebsiteUrl $WebsiteUrl
        } elseif ($psCmdlet.ParameterSetName -eq 'ConfirmByLiveIDAccessToken') {
            $livePerson = Get-Person -LiveIDAccessToken $LiveIDAccessToken
            if ($livePerson) {
                $livePerson | 
                    Add-Member NoteProperty LiveIDAccessToken $LiveIDAccessToken -Force
                
                if ($pipeWorksManifest.UserDB) {
                    $userDBObject = @{} + $pipeworksManifest.UserDb
                    $userDBObject.Remove("Name")
                    $userDBObject.UserTable = $pipeworksManifest.UserDB.Name
                    $userDBObject.ConnectionString = $pipeworksManifest.UserDB.ConnectionString
                        
                    $preferredEmail = 
                        $livePerson | 
                            Select-Object -ExpandProperty Emails | 
                            Select-Object -expandProperty Preferred

                    try {
                    $confirmedUserAccount = 
                        New-Object PSObject -Property $userDBObject  |
                            Confirm-Person -WebsiteUrl $websiteUrl -PersonObject $livePerson -Email $preferredEmail
                    } catch {
                        if ($Response) {
                            $Response.Write("$($_|Out-String)")
                        }
                    }
                } elseif ($pipeworksManifest.UserTable.Name) {
                    # Confirm the user and set the cookie
                    # $request.Cookies["FBAT_For_$($pipeworksManifest.Facebook.AppId)"]                        
                        
                    $userTableObject = @{} + $pipeworksManifest.UserTable
                    $userTableObject.Remove("Name")
                    $userTableObject.UserTable = $pipeworksManifest.UserTable.Name
                    $UserTableObject 
                    $preferredEmail = 
                        $livePerson | 
                            Select-Object -ExpandProperty Emails | 
                            Select-Object -expandProperty Preferred

                    $confirmedUserAccount = 
                        New-Object PSObject -Property $userTableObject |
                            Confirm-Person -WebsiteUrl $websiteUrl -PersonObject $livePerson -Email $preferredEmail
                        
                        
                    
                }

                if ($confirmedUserAccount) {
                    $confirmedUserAccount.pstypenames.clear()
                    $confirmedUserAccount.pstypenames.add('http://schema.org/Person')        
                    if ($session) {
                        # If $session is found (we're running in a web app) log them in
                        $session["User"] = $confirmedUserAccount 
                    }
                }
                                        
                
                                
                if ($session) {
                    
                    
                } else{
                     return $livePerson
                }                 
            }
        } elseif ($psCmdlet.ParameterSetName -eq 'ConfirmByFacebookAccessToken') {
            # Get the record associated with the access token.  
            
            $fbUserInfo = Get-Person -FacebookAccessToken $FacebookAccessToken 
            $fbUserInfo.pstypenames.clear()
            $fbUserInfo.pstypenames.add('http://schema.org/Person')
            if ($Response) {
                # set a cookie
                $fbatCookie = New-Object Web.HttpCookie "FBAT_For_$($module.Name)"
                $fbatCookie.Value  =$FacebookAccessToken
                $fbatCookie.Expires = (Get-Date).AddHours(1)
                $response.Cookies.Add($fbatCookie)
                #$response.Flush()
            }
            
            
            
            if ($fbUserInfo) {
                $fbUserInfo | 
                    Add-Member NoteProperty FacebookAccessToken $FacebookAccessToken -Force
                                        
                # If $session is found (we're running in a web app) "log" them in
                if ($session) {
                    # If there is a user session, then do the following:
                    # - Make sure that the user can be logged in:                    
                    # - Set the Current user object in the session
                    # - See if users are permanently tracked. If so, create or save the user object
                    
                    
                    # - Check if the user can log in
                    if ($pipeworksManifest.Facebook.Owner) {
                        if (@($pipeworksManifest.Facebook.Owner) -notcontains $authenticated.Id) {
                            throw "Not site owner, cannot login"
                            return
                        }
                    }
                    

                    if (-not $pipeworksManifest.UserTable.Name) {
                        # Confirm the user and set the cookie
                        # $request.Cookies["FBAT_For_$($pipeworksManifest.Facebook.AppId)"]                        
                        $session["User"] = $fbUserInfo
                    } else {
                        $userTable = @{} + $pipeworksManifest.UserTable
                        $userTable.Remove("Name")
                        $userTable.UserTable = $pipeworksManifest.UserTable.Name
                        
                        $confirmedUserAccount = 
                            New-Object PSObject -Property $userTable |
                                Confirm-Person -WebsiteUrl $websiteUrl -PersonObject $fbUserInfo -Email $fbUserInfo.Email.Replace("\u0040", "@")
                        
                        $confirmedUserAccount.pstypenames.clear()
                        $confirmedUserAccount.pstypenames.add('http://schema.org/Person')        
                        
                        if ($confirmedUserAccount) {
                            $session["User"] = $confirmedUserAccount 
                        }
                    }
                } else {
                    # Output the facebook user
                    return $fbUserInfo
                }
            }
        }
    }
} 
