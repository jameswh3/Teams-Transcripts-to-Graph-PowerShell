#Example of how to browse external items in the search index
Disconnect-PnPOnline

$clientId="<your Entra App Client Id>"
$SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
$searchExternalConnectionId="<your External Connection Id>"


Connect-PnPOnline -Interactive `
    -Url $SPOAdminUrl `
    -ClientId $clientId

Get-PnpSearchExternalItem -ConnectionId $searchExternalConnectionId 