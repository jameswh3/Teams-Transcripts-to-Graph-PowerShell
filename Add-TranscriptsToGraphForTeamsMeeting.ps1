#region ENV
    # Load variables from a .env file in the same directory as this script.
    # The .env file should contain KEY=VALUE pairs (one per line).
    # Lines starting with # are treated as comments and ignored.
    # Expected keys (copy .env.example to .env and fill in your values).
    # Keys shared with Add-TranscriptsToGraphForStreamUpload.ps1 are marked [Both].
    #
    #   CLIENT_ID=<EntraAppId that you've registered>                    [Both]
    #   TENANT=<your tenant name, e.g. contoso.onmicrosoft.com>         [Both]
    #   CERT_THUMBPRINT=<certificate thumbprint>                         [Both]
    #   SPO_ADMIN_URL=https://<your tenant name>-admin.sharepoint.com   [Both]
    #   SEARCH_EXTERNAL_CONNECTION_ID=<Id of the search connection>      [Both]
    #   CATEGORY=<category label to apply to transcript items>           [Both]
    #   STREAM_ENDPOINT=/_layouts/15/stream.aspx                         [Both]
    #   TENANT_ID=<Your Tenant ID - GUID>
    #   CERT_STORE=Cert:\CurrentUser\My\
    #   ONEDRIVE_BASE_URL=https://<your tenant name>-my.sharepoint.com
    #   MEETING_ORGANIZER_UPN=<UPN of the meeting organizer>
    #   MEETING_SUBJECT=<subject of the meeting>
    #   START_DATETIME=2025-02-09T00:00:00Z
    #   END_DATETIME=2025-02-12T11:59:59Z
    #   TRANSCRIPT_FILE_PATH=C:\Temp

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
    $clientId                   = if ($CLIENT_ID)                    { $CLIENT_ID }                    else { $clientId }
    $tenantId                   = if ($TENANT_ID)                    { $TENANT_ID }                    else { $tenantId }
    $tenant                     = if ($TENANT)                       { $TENANT }                       else { $tenant }
    $certThumbprint             = if ($CERT_THUMBPRINT)              { $CERT_THUMBPRINT }              else { $certThumbprint }
    $certStore                  = if ($CERT_STORE)                   { $CERT_STORE }                   else { "Cert:\CurrentUser\My\" }
    $SPOAdminUrl                = if ($SPO_ADMIN_URL)                { $SPO_ADMIN_URL }                else { $SPOAdminUrl }
    $oneDriveBaseUrl            = if ($ONEDRIVE_BASE_URL)            { $ONEDRIVE_BASE_URL }            else { $oneDriveBaseUrl }
    $searchExternalConnectionId = if ($SEARCH_EXTERNAL_CONNECTION_ID){ $SEARCH_EXTERNAL_CONNECTION_ID} else { $searchExternalConnectionId }
    $category                   = if ($CATEGORY)                     { $CATEGORY }                     else { $category }
    $streamEndpoint             = if ($STREAM_ENDPOINT)              { $STREAM_ENDPOINT }              else { "/_layouts/15/stream.aspx" }
    $meetingOrganizerUPN        = if ($MEETING_ORGANIZER_UPN)        { $MEETING_ORGANIZER_UPN }        else { $meetingOrganizerUPN }
    $meetingSubject             = if ($MEETING_SUBJECT)              { $MEETING_SUBJECT }              else { $meetingSubject }
    $startDateTime              = if ($START_DATETIME)               { $START_DATETIME }               else { $startDateTime }
    $endDateTime                = if ($END_DATETIME)                 { $END_DATETIME }                 else { $endDateTime }
    $transcriptFilePath         = if ($TRANSCRIPT_FILE_PATH)         { $TRANSCRIPT_FILE_PATH }         else { "C:\Temp" }
#endregion

#region DEPENDENCIES
    . (Join-Path $scriptDir "Get-MeetingRecordingInfo.ps1")
    . (Join-Path $scriptDir "Get-OnlineMeetingRecordingSharePointFileInfo.ps1")
    . (Join-Path $scriptDir "Get-MeetingTranscript.ps1")
    . (Join-Path $scriptDir "Get-WebVTTContent.ps1")
    . (Join-Path $scriptDir "Add-TranscriptItemsToGraph.ps1")
#endregion

#region STEP 1a
    #Connect to Graph#
    $certStore = if ($certStore) { $certStore } else { "Cert:\CurrentUser\My\" } #if you are storing your certificate in a different location, update CERT_STORE in .env
    $cert=Get-ChildItem "$certStore\$certThumbprint"
    Connect-MgGraph -ClientId $clientId `
        -TenantId $tenantId `
        -Certificate $cert `
        -NoWelcome
#endregion

#region STEP 1b
#Retrieve Meeting Info#
# $startDateTime, $endDateTime, $meetingOrganizerUPN, and $meetingSubject are loaded from .env (note: datetimes are UTC)
$meetingRecordingInfo=Get-MeetingRecordingInfo `
    -meetingOrganizerUserId $meetingOrganizerUPN `
    -startDateTime $startDateTime `
    -endDateTime $endDateTime `
    -MeetingSubject $meetingSubject
#endregion

#region STEP 2
#Retrieve SharePoint File Info#
# $tenant and $oneDriveBaseUrl are loaded from .env
$recordingLibraryName = 'Documents' #always documents if OneDrive
$recordingFileInfo=Get-OnlineMeetingRecordingSharePointFileInfo `
    -meetingOrganizerUserUpn $meetingOrganizerUPN `
    -OneDriveBaseUrl $oneDriveBaseUrl `
    -MeetingSubject $meetingSubject `
    -ClientId $clientId `
    -Tenant $tenant `
    -OneDriveRecordingsLibraryName $recordingLibraryName `
    -CertificateThumbprint $certThumbprint
#endregion

#region STEP 3
#Retrieve Transcript File#
$transcriptFile=Get-MeetingTranscript `
    -meetingOrganizerUserId $meetingRecordingInfo.MeetingHostId `
    -meetingId $meetingRecordingInfo.MeetingId `
    -meetingSubject $meetingRecordingInfo.MeetingSubject `
    -transcriptFilePath $transcriptFilePath `
    -ContentCorrelationId $meetingRecordingInfo.ContentCorrelationId
#endregion

#region STEP 4
#Parse Transcript File#
$transcriptData=Get-WebVTTContent `
    -TranscriptFile $transcriptFile `
    -TimeIncrement 30
#endregion

#region STEP 5a
#Connect to SharePoint Admin#
# $SPOAdminUrl, $searchExternalConnectionId, and $streamEndpoint are loaded from .env
Connect-PnPOnline -Url "$SPOAdminUrl" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $certThumbprint
#endregion

#region STEP 5b
#Add Transcript Items to Graph#
# $category is loaded from .env
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