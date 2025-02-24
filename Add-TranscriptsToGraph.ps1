#STEP 1
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

#STEP 2
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

#STEP 3
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

#STEP 4
#Retrieve Transcript File#
$transcriptFile=Get-MeetingTranscript `
    -meetingOrganizerUserId $meetingRecordingInfo.MeetingHostId `
    -meetingId $meetingRecordingInfo.MeetingId `
    -meetingSubject $meetingRecordingInfo.MeetingSubject `
    -transcriptFilePath "<Local Path to save Transcript File>" ` #update to your preferred location
    -ContentCorrelationId $meetingRecordingInfo.ContentCorrelationId

#STEP 5
#Parse Transcript File#
$transcriptData=Format-TeamsTranscriptByTime `
    -TranscriptFile $transcriptFile `
    -TimeIncrement 30

#STEP 6
#Connect to SharePoint Admin#
$SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
$streamEndpoint="/_layouts/15/stream.aspx"
$searchExternalConnectionId="<Id of the search external connection>"
Connect-PnPOnline -Url "$SPOAdminUrl" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $certThumbprint

#STEP 7
#Add Transcript Items to Graph#
Add-TranscriptItemsToGraph -TranscriptItems $transcriptData `
    -StreamEndpoint $streamEndpoint `
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