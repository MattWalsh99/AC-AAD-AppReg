write-host -ForegroundColor Red "

    #################################
    #                               #  
    #                               #
    #     IVANTIIVANTIIVANTIIVA     #  ###################################
    #     NTIIVANTIIVANTIIVANTI     #  #                                 #
    #     IVANTIIVANTIIVANTIIVA     #  #  Application Control            #
    #     NTIIVANTIIVANTIIVANTI     #  #  AAD Condition Script           #  
    #     IVANTIIVANTIIVANTIIVA     #  #                                 # 
    #                 NTIIVANTI     #  #  Version 1.1                    #
    #     IVANTIIVA   IVANTIIVA     #  #                                 #
    #     NTIIVANTI   NTIIVANTI     #  #  Matt Walsh 2022                #
    #     IVANTIIVA   IVANTIIVA     #  #                                 #
    #     NTIIVANTI   NTIIVANTI     #  ###################################
    #     IVANTIIVA   IVANTIIVA     #
    #                               #
    #                               #
    #################################

"


#  Get the UPN of the logged on User
$loggedonUserUPN = whoami /upn

#####  Azure #####


$ApplicationID = ""  #  App Registration ID
$TenatDomainName = "" #  Tenant Domain Name
$AccessSecret = "" #  App Reg Client Secret (Must have the appropriate Graph API perms)

$Body = @{    
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
} 

#  Retrieve Access Token using App Registration
$ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenatDomainName/oauth2/v2.0/token" -Method POST -Body $Body
$token = $ConnectGraph.access_token

$GroupUrl = 'https://graph.microsoft.com/v1.0/Groups/'
$UsersUrl = 'https://graph.microsoft.com/v1.0/Users/'
$DevicesUrl = 'https://graph.microsoft.com/v1.0/Devices/'

$userGroupUrl = "https://graph.microsoft.com/v1.0/Users/$loggedonUserUPN/transitivememberof"


$users = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $UsersUrl -Method Get).value.userprincipalName
$devices = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $DevicesUrl -Method Get).value.displayname
$groups = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $GroupUrl -Method Get).value
$usergroups = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $userGroupUrl -Method Get).value.displayName



#  Conditions Go Here
#  **Comment / Delete as required**

#  1.  Explicit User match to a defined Azure User
#$condition = $loggedonUserUPN -eq "hank.pym@mjwlabs.onmicrosoft.com"

#  2.  Is the user a member of an 'Explicit' Azure AD Group?
#$condition = if ($userGroups -match "Azure-NestedGroup") { $true } else { $false }

#  3.  Device is part of the Azure AD Domain.
#$condition = if ($env:computername -match $devices) { $true } else { $false }

#  4.  Transitive / Recursive MemberOf Group Search
$groupID = ($groups | where {$_.displayName -eq "Azure-NestedGroup"}).id
$transitiveGrpUrl = "$GroupUrl$groupID" + "/transitiveMembers"
$groupMembers = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $transitiveGrpUrl -Method Get).value.userprincipalName  # Doesn't return group names

$condition = if ($loggedonUserUPN -match $groupMembers) { $true } else { $false }


#  Resultant Rule Condition - **DO NOT DELETE**
if ($condition)
{
    write-host "Condition Matched"
    exit 0
}
else
{
    write-host "Condition Failed"
    exit 1
}


