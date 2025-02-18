# Teams Transcripts to Graph PowerShell

This repository contains PowerShell scripts to manage and process Microsoft Teams meeting transcripts and recordings, and add them to Microsoft Graph. The master script is `Add-TranscriptionItemsToGraph.ps1`, which orchestrates the entire process.

## Prerequisites

- PowerShell 7.0 or later
- Modules:
  - `PnP.PowerShell`
  - `Microsoft.Graph`
  - `MicrosoftTeams`


## Scripts Overview

### 1. `Add-TranscriptionItemsToGraph.ps1`

This is the master script that connects to Microsoft Graph, retrieves meeting information, SharePoint file info, and transcripts, formats the transcript data, and adds it to Microsoft Graph.

#### Sample Usage

```ps1
# Connect to Graph
$clientId="<EntraAppId that you've registered>"
$tenantId="<Your Tenant ID - GUID>"
$certThumbprint="<certificate thumbprint>"
$certStore="Cert:\CurrentUser\My\"
$cert=Get-ChildItem "$certStore\$certThumbprint"
Connect-MgGraph -ClientId $clientId `
    -TenantId $tenantId `
    -Certificate $cert `
    -NoWelcome

# Retrieve Meeting Info
$startDateTime="2025-02-09T00:00:00Z"
$endDateTime="2025-02-12T11:59:59Z"
$meetingOrganizerUPN="<UPN of the meeting organizer>"
$meetingSubject = "<subject of the meeting>"
$meetingRecordingInfo=Get-MeetingRecordingInfo -meetingOrganizerUserId $meetingOrganizerUPN `
    -startDateTime $startDateTime `
    -endDateTime $endDateTime `
    -MeetingSubject $meetingSubject

# Retrieve SharePoint File Info
$tenant="<your tenant name>.onmicrosoft.com"
$oneDriveBaseUrl = "https://<your tenant name>-my.sharepoint.com"
$recordingLibraryName = 'Documents'
$recordingFileInfo=Get-OnlineMeetingRecordingSharePointFileInfo -meetingOrganizerUserUpn $meetingOrganizerUPN `
    -OneDriveBaseUrl $oneDriveBaseUrl `
    -MeetingSubject $meetingSubject `
    -ClientId $clientId `
    -Tenant $tenant `
    -OneDriveRecordingsLibraryName $recordingLibraryName `
    -CertificateThumbprint $certThumbprint

# Retrieve Transcript File
$transcriptFile=Get-MeetingTranscript -meetingOrganizerUserId $meetingRecordingInfo.MeetingHostId `
    -meetingId $meetingRecordingInfo.MeetingId `
    -meetingSubject $meetingRecordingInfo.MeetingSubject `
    -transcriptFilePath "c:\temp" `
    -ContentCorrelationId $meetingRecordingInfo.ContentCorrelationId

# Parse Transcript File
$transcriptData=Format-TranscriptByTime -TranscriptFile $transcriptFile `
    -TimeIncrement 30

# Connect to SharePoint Admin
$SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
$streamEndpoint="/_layouts/15/stream.aspx"
$searchExternalConnectionId="<Id of the search external connection>"
Connect-PnPOnline -Url "$SPOAdminUrl" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $certThumbprint

# Add Transcript Items to Graph
Add-TranscriptItemsToGraph -TranscriptItems $transcriptData `
    -MeetingRecordingInfo $meetingRecordingInfo `
    -RecordingFileInfo $recordingFileInfo `
    -StreamEndpoint $streamEndpoint `
    -SearchExternalConnectionId $searchExternalConnectionId
```

### 2. `Get-MeetingRecordingInfo.ps1`

This script retrieves information about Microsoft Teams meeting recordings, including the meeting host, meeting ID, and content correlation ID.

#### Inputs

- `-meetingOrganizerUserId`: The UPN of the meeting organizer.
- `-startDateTime`: The start date and time for the meeting search range.
- `-endDateTime`: The end date and time for the meeting search range.
- `-MeetingSubject`: The subject of the meeting.

#### Outputs

- `meetingRecordingInfo`: An object containing the meeting host, meeting ID, and content correlation ID.

#### Sample Usage

```ps1
# Retrieve Meeting Info
$startDateTime="2025-02-09T00:00:00Z"
$endDateTime="2025-02-12T11:59:59Z"
$meetingOrganizerUPN="<UPN of the meeting organizer>"
$meetingSubject = "<subject of the meeting>"
$meetingRecordingInfo=Get-MeetingRecordingInfo -meetingOrganizerUserId $meetingOrganizerUPN `
    -startDateTime $startDateTime `
    -endDateTime $endDateTime `
    -MeetingSubject $meetingSubject
```

### 3. `Get-OnlineMeetingRecordingSharePointFileInfo.ps1`

This script retrieves information about the SharePoint file associated with a Microsoft Teams meeting recording.

#### Inputs

- `-meetingOrganizerUserUpn`: The UPN of the meeting organizer.
- `-OneDriveBaseUrl`: The base URL of the OneDrive site.
- `-MeetingSubject`: The subject of the meeting.
- `-ClientId`: The client ID for authentication.
- `-Tenant`: The tenant name.
- `-OneDriveRecordingsLibraryName`: The name of the OneDrive recordings library.
- `-CertificateThumbprint`: The thumbprint of the certificate used for authentication.

#### Outputs

- `recordingFileInfo`: An object containing information about the SharePoint file associated with the meeting recording.

#### Sample Usage

```ps1
# Retrieve SharePoint File Info
$tenant="<your tenant name>.onmicrosoft.com"
$oneDriveBaseUrl = "https://<your tenant name>-my.sharepoint.com"
$recordingLibraryName = 'Documents'
$recordingFileInfo=Get-OnlineMeetingRecordingSharePointFileInfo -meetingOrganizerUserUpn $meetingOrganizerUPN `
    -OneDriveBaseUrl $oneDriveBaseUrl `
    -MeetingSubject $meetingSubject `
    -ClientId $clientId `
    -Tenant $tenant `
    -OneDriveRecordingsLibraryName $recordingLibraryName `
    -CertificateThumbprint $certThumbprint
```

### 4. `Get-MeetingTranscript.ps1`

This script retrieves the transcript file for a Microsoft Teams meeting.

#### Inputs

- `-meetingOrganizerUserId`: The UPN of the meeting organizer.
- `-meetingId`: The ID of the meeting.
- `-meetingSubject`: The subject of the meeting.
- `-transcriptFilePath`: The local path where the transcript file will be saved.
- `-ContentCorrelationId`: The content correlation ID of the meeting.

#### Outputs

- `transcriptFile`: The path to the downloaded transcript file.

#### Sample Usage

```ps1
# Retrieve Transcript File
$transcriptFile=Get-MeetingTranscript -meetingOrganizerUserId $meetingRecordingInfo.MeetingHostId `
    -meetingId $meetingRecordingInfo.MeetingId `
    -meetingSubject $meetingRecordingInfo.MeetingSubject `
    -transcriptFilePath "c:\temp" `
    -ContentCorrelationId $meetingRecordingInfo.ContentCorrelationId
```

### 5. `Format-TranscriptByTime.ps1`

This script formats the transcript data by time increments.

#### Inputs

- `-TranscriptFile`: The path to the transcript file.
- `-TimeIncrement`: The time increment in minutes for formatting the transcript data.

#### Outputs

- `transcriptData`: An object containing the formatted transcript data.

#### Sample Usage

```ps1
# Parse Transcript File
$transcriptData=Format-TranscriptByTime -TranscriptFile $transcriptFile `
    -TimeIncrement 30
```

### 6. `Add-TranscriptItemsToGraph.ps1`

This script adds the formatted transcript items to Microsoft Graph.

#### Inputs

- `-TranscriptItems`: The formatted transcript data.
- `-MeetingRecordingInfo`: The meeting recording information.
- `-RecordingFileInfo`: The SharePoint file information for the meeting recording.
- `-StreamEndpoint`: The endpoint for the stream.
- `-SearchExternalConnectionId`: The ID of the search external connection.

#### Outputs

- None

#### Sample Usage

```ps1
# Add Transcript Items to Graph
Add-TranscriptItemsToGraph -TranscriptItems $transcriptData `
    -MeetingRecordingInfo $meetingRecordingInfo `
    -RecordingFileInfo $recordingFileInfo `
    -StreamEndpoint $streamEndpoint `
    -SearchExternalConnectionId $searchExternalConnectionId
```