#======================================================================
#Script Name: Change_Local_Computer_Description.ps1
#Script Author: Phung, John
#Script Purpose: Script will update the local computer description field and sync with AD
#Script Creation Date:	09/25/2018
#Script Last Modified Date:	09/26/2018
#Script Notes: 
#======================================================================

#Import Necessary PS Modules
Import-Module ActiveDirectory

$script:regKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
$script:regString = "srvcomment"

function endScript
{
    Write-Host ""
    Read-Host -Prompt "Press Enter to end script"
    exit
}

function getComputerName
{
    $Script:computerName = Read-Host "`nWhat computer name do you want to update?" 
    $Script:computerName = $Script:computerName.Replace(' ','')
    $Script:computerName = $Script:computerName.ToUpper()
    $Script:computerName
    checkADComputer
}

function checkADComputer
{
    $computerExists = (Get-ADComputer -LDAPFilter "(name=$Script:computerName)")
    If ($computerExists -ne $Null)
        {
        testConnection
        }
    else
        {
        Write-Host "`n$Script:computerName does not exist in AD."
        testComputerAgain
        }
}

function testComputerAgain
{
    $title = ""
    $message = "Do you want to try another computer name?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Try another computer name."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "End script."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $script:result = $host.ui.PromptForChoice($title, $message, $options, 0)
    switch ($result)
        {
            0 {getComputerName}
            1 {endScript}
        }
}

function testConnection
{
    if (Test-Connection $Script:computerName -Quiet)
       {
       getLocalDescription
       setLocalDescription
       setADDescription
       }
    else
        {systemOffline}
}

function getLocalDescription
{
    $Script:LocalDescription = Read-Host "Enter New PC Description"
}

function setLocalDescription
{
    Invoke-Command -ComputerName $Script:computerName -ScriptBlock $remoteScriptBlock
}

function systemOffline
{
    Write-Output "$Script:computerName is Offline"
}

function getDescription
{
$Script:LocalDescription = (Get-WmiObject -ComputerName $script:computerName -Class win32_operatingsystem).Description
#Write-Output "$script:computerName - $Script:LocalDescription"
}

function setADDescription
{
getDescription
Set-ADComputer $script:computerName -Description $Script:LocalDescription
}

$remoteScriptBlock = {
function checkRegistryString
{
    if (Get-ItemProperty -Path $Using:regKey | Select-Object -ExpandProperty $Using:regString)
       {
       #echo "true"
       Set-ItemProperty -Path $Using:regKey -Name $Using:regString -Value $Using:LocalDescription
       }
    else
       {
       #echo "false"
       New-ItemProperty -Path $Using:regKey -Name $Using:regString -PropertyType "String" -Value $Using:LocalDescription
       }
}
    checkRegistryString
}

getComputerName

endScript