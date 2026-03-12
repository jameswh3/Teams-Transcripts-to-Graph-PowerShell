#region ENV
    # Load variables from a .env file in the same directory as this script.
    # The .env file should contain KEY=VALUE pairs (one per line).
    # Lines starting with # are treated as comments and ignored.
    # Expected keys (copy .env.example to .env and fill in your values).
    # Keys shared with Add-TranscriptsToGraphForTeamsMeeting.ps1 are marked [Both].
    #
    #   CLIENT_ID=<EntraAppId that you've registered>                    [Both]
    #   TENANT=<your tenant name, e.g. contoso.onmicrosoft.com>         [Both]
    #   CERT_THUMBPRINT=<certificate thumbprint for app-only auth>       [Both]
    #   SPO_ADMIN_URL=https://<your tenant name>-admin.sharepoint.com   [Both]
    #   SEARCH_EXTERNAL_CONNECTION_ID=<Id of the search connection>      [Both]
    #   CATEGORY=<category label to apply to transcript items>           [Both]
    #   STREAM_ENDPOINT=/_layouts/15/stream.aspx                         [Both]
    #   SITE_URL=https://<your tenant>.sharepoint.com/sites/<your site>/
    #   DOCUMENT_LIBRARY=Videos
    #   SHAREPOINT_FOLDER=<optional subfolder within the library>
    #   DESTINATION_FOLDER=C:\Temp

    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } `
                 elseif ($MyInvocation.MyCommand.Path) { Split-Path $MyInvocation.MyCommand.Path } `
                 else { $PWD.Path }
    $envFile = Join-Path $scriptDir ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.*)\s*$') {
                Set-Variable -Name $Matches[1] -Value $Matches[2]
            }
        }
    } else {
        Write-Warning ".env file not found at '$envFile'. Falling back to values defined in the script."
    }

    # Map .env keys to the variable names used throughout this script
    $clientId                  = if ($CLIENT_ID)                   { $CLIENT_ID }                   else { $clientId }
    $siteUrl                   = if ($SITE_URL)                    { $SITE_URL }                    else { $siteUrl }
    $SPOAdminUrl               = if ($SPO_ADMIN_URL)               { $SPO_ADMIN_URL }               else { $SPOAdminUrl }
    $Tenant                    = if ($TENANT)                      { $TENANT }                      else { $Tenant }
    $certThumbprint            = if ($CERT_THUMBPRINT)             { $CERT_THUMBPRINT }             else { $certThumbprint }
    $searchExternalConnectionId = if ($SEARCH_EXTERNAL_CONNECTION_ID) { $SEARCH_EXTERNAL_CONNECTION_ID } else { $searchExternalConnectionId }
    $category                  = if ($CATEGORY)                    { $CATEGORY }                    else { $category }
    $streamEndpoint            = if ($STREAM_ENDPOINT)             { $STREAM_ENDPOINT }             else { "/_layouts/15/stream.aspx" }
    $destinationFolder         = if ($DESTINATION_FOLDER)          { $DESTINATION_FOLDER }          else { "C:\Temp" }
    $documentLibrary           = if ($DOCUMENT_LIBRARY)            { $DOCUMENT_LIBRARY }            else { "Videos" }
    $sharePointFolder          = if ($SHAREPOINT_FOLDER)           { $SHAREPOINT_FOLDER }           else { $null }
#endregion

#region DEPENDENCIES
    . (Join-Path $scriptDir "Get-StreamTranscriptViaSharePoint.ps1")
    . (Join-Path $scriptDir "Get-WebVTTContent.ps1")
    . (Join-Path $scriptDir "Add-TranscriptItemsToGraph.ps1")
#endregion

#region STEP 1
    #Connect to SharePoint and Get File Info#

    $pnpWebConnection=Connect-PnPOnline -Url $siteUrl `
                    -ClientId $clientId `
                    -Interactive `
                    -ForceAuthentication `
                    -ReturnConnection

    #Call Script; if you have a subfolder, you can add the -Folder parameter
    $transcriptFile=Get-StreamTranscriptViaSharePoint -SiteUrl $siteUrl `
        -DocumentLibrary $documentLibrary `
        -SharePointFolder $sharePointFolder `
        -PnPWebConnection $pnpWebConnection `
        -DestinationFolder $destinationFolder
#endregion

#region STEP 2
    #Parse Transcript File#
    $transcriptData=Get-WebVTTContent `
        -TranscriptFile $transcriptFile `
        -SegmentSize 30
#endregion

#region STEP 3a
    #Connect to SharePoint Admin#
    Connect-PnPOnline -Url "$SPOAdminUrl" `
                    -ClientId $ClientId `
                    -Tenant $Tenant `
                    -Thumbprint $certThumbprint
#endregion

#region STEP 3b
    #Add Transcript Items to Graph#
    Add-TranscriptItemsToGraph -TranscriptItems $transcriptData `
        -StreamEndpoint $streamEndpoint `
        -Category $category `
        -SearchExternalConnectionId $searchExternalConnectionId `
        -MeetingStartDateTime $meetingRecordingInfo.StartDateTime `
        -MeetingEndDateTime $meetingRecordingInfo.EndDateTime `
        -MeetingSubject $meetingRecordingInfo.MeetingSubject `
        -MeetingOrganizer $meetingRecordingInfo.MeetingHostId `
        -FileName $recordingFileInfo.FileName `
        -FileExtension $recordingFileInfo.FileType `
        -LastModifiedDateTime $meetingRecordingInfo.EndDateTime `
        -FileUrl $recordingFileInfo.FileUrl `
        -SiteUrl $recordingFileInfo.SiteUrl
#endregion