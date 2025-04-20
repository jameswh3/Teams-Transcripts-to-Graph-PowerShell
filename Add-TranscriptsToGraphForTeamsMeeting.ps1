#region STEP 1a
    #Connect to Graph#
    $clientId="<EntraAppId that you've registered>"
    $tenantId="<Your Tenant ID - GUID>"
    $certThumbprint="<certificate thumbprint>"
    $certStore="Cert:\CurrentUser\My\" #if you are storking your certificate in a different location, update this path
    $cert=Get-ChildItem "$certStore\$certThumbprint"
    Connect-MgGraph -ClientId $clientId `
        -TenantId $tenantId `
        -Certificate $cert `
        -NoWelcome
#endregion

#region STEP 1b
#Retrieve Meeting Info#
$startDateTime="2025-02-09T00:00:00Z" #note this is UTC; update to your date range
$endDateTime="2025-02-12T11:59:59Z" #note this is UTC; update to your date range
$meetingOrganizerUPN="<UPN of the meeting organizer>"
$meetingSubject = "<subject of the meeting>"
$meetingRecordingInfo=Get-MeetingRecordingInfo `
    -meetingOrganizerUserId $meetingOrganizerUPN `
    -startDateTime $startDateTime `
    -endDateTime $endDateTime `
    -MeetingSubject $meetingSubject
#endregion

#region STEP 2
#Retrieve SharePoint File Info#
$tenant="<your tenant name>.onmicrosoft.com"
$oneDriveBaseUrl = "https://<your tenant name>-my.sharepoint.com"
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
    -transcriptFilePath "<Local Path to save Transcript File>" ` #update to your preferred location
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
$SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
$streamEndpoint="/_layouts/15/stream.aspx"
$searchExternalConnectionId="<Id of the search external connection>"
Connect-PnPOnline -Url "$SPOAdminUrl" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $certThumbprint
#endregion

#region STEP 5b
#Add Transcript Items to Graph#
$category="<add your category for this video>"
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