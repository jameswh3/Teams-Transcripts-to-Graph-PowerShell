#Example of how to browse external items in the search index
Disconnect-PnPOnline

$clientId="<your Entra App Client Id>"
$SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
$searchExternalConnectionId="<your External Connection Id>"


Connect-PnPOnline -Interactive `
    -Url $SPOAdminUrl `
    -ClientId $clientId

Get-PnpSearchExternalItem -ConnectionId $searchExternalConnectionId 

<#
    #this will clear items in the external search index
    $clearGraphData=$false
    if ($clearGraphData) {
        Get-PnPSearchExternalItem -ConnectionId $searchExternalConnectionId | Select-Object Id | ForEach-Object { Remove-PnPSearchExternalItem -ConnectionId $searchExternalConnectionId -ItemId $_.Id }
    }
#>