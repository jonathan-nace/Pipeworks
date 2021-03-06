function Send-TextMessage
{
    <#
    .Synopsis
        Sends text messages 
    .Description
        Sends text messages with twilio
    .Example
        # Looks up a phone number location and texts the url of a map to that #
        Search-WolframAlpha -For "1-206-607-6555" -ApiKeySetting WolframAlphaApiKey | 
            Select-Object -ExpandProperty Map | 
            Send-TextMessage -To "1-206-555-1212" -From "1-206-607-6555" -Body { $_ }
    .Link
        Twilio.com
    .Link
        Get-TextMessage
    #>
    [OutputType([xml])]
    param(
    # The Phone Number the text will be sent from
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    $From,
    
    # The Phone Number the text will be sent to
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    $To,
    
    # The body of the text message
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateLength(1,160)]
    [string]
    $Body,
    
    
    # The credential used to get the texts
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential,
    
    
    # A setting storing the credential
    [Parameter(ValueFromPipelineByPropertyName=$true)]       
    [string[]]
    $Setting = @("TwilioAccountKey", "TwilioAccountSecret")
    )
    
    process {
        #region Determine Twilio Credentials
        if (-not $Credential -and $Setting) {
            if ($setting.Count -eq 1) {

                $userName = Get-WebConfigurationSetting -Setting "${Setting}_UserName"
                $password = Get-WebConfigurationSetting -Setting "${Setting}_Password"
            } elseif ($setting.Count -eq 2)  {
                $userName = Get-secureSetting -Name $Setting[0] -ValueOnly
                $password= Get-secureSetting -Name $Setting[1] -ValueOnly
            }

            if ($userName -and $password) {                
                $password = ConvertTo-SecureString -AsPlainText -Force $password
                $credential  = New-Object Management.Automation.PSCredential $username, $password 
            } elseif ((Get-SecureSetting -Name "$Setting" -ValueOnly | Select-Object -First 1)) {
                $credential = (Get-SecureSetting -Name "$Setting" -ValueOnly | Select-Object -First 1)
            }
            
            
        }
        #endregion Determine Twilio Credentials
        if (-not $Credential) {
            Write-Error "No Twilio Credential provided.  Use -Credential or Add-SecureSetting TwilioAccountDefault -Credential (Get-Credential) first"               
            return
        }

        $getWebParams = @{
            WebCredential=$Credential
            Url="https://api.twilio.com/2010-04-01/Accounts/$($Credential.GetNetworkCredential().Username.Trim())/SMS/Messages.xml"
            Method="POST"
            AsXml =$true
            Parameter = @{
                From = $from
                To = $to
                Body = $body
            }
            UseWebRequest = $true
        }        
        Get-Web @getwebParams -Verbose |
            Select-Object -ExpandProperty TwilioResponse |
            Select-Object -ExpandProperty SmsMessage |
            ForEach-Object {
                $_.pstypenames.clear()
                $_.pstypenames.Add('Twilio.TextMessage')
                $_
            }
              
    }       
} 
