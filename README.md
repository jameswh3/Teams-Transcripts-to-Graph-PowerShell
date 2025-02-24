# Teams Transcripts to Graph PowerShell

This repository contains PowerShell scripts to manage and process Microsoft Teams meeting transcripts and recordings, and add them to Microsoft Graph. The master script is `Add-TranscriptionsToGraph.ps1`, which orchestrates the entire process.

## Prerequisites

- PowerShell 7.0 or later
- Modules:
  - `PnP.PowerShell`
  - `Microsoft.Graph`
  - `MicrosoftTeams`
- Entra App Registration with Appropriate permissions (details below)

** If you run into issues with conflicts between PnP.PowerShell and Microsoft.Graph, check out https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Resolve-TAPnPPowerShellConflicts.md for a way to address that issue. **

## Scripts Overview

| Script Name| Description  |
| --- |---|
| `Add-TranscriptionItemsToGraph.ps1` | Adds the formatted transcript items to Microsoft Graph. |
| `Get-MeetingRecordingInfo.ps1` | Retrieves information about Microsoft Teams meeting recordings. |
| `Get-OnlineMeetingRecordingSharePointFileInfo.ps1` | Retrieves information about the SharePoint file associated with a Microsoft Teams meeting recording. |
| `Get-MeetingTranscript.ps1` | Retrieves the transcript file for a Microsoft Teams meeting. |
| `Format-TeamsTranscriptByTime.ps1` | Formats the transcript data by time increments.|
| `Add-TranscriptItemsToGraph.ps1` | This is the main script that calls the other scripts in series.|
| `Get-StreamTranscriptViaSharePoint.ps1` | Retrieves the transcript files for Microsoft Stream videos stored in a SharePoint document library. |
| `Get-WebVTTContent.ps1` | Processes WebVTT files and extracts transcript data, optionally grouping sentences into segments. This can accomodate both Teams Recording Transcripts and Stream transcripts created when uploading files to SharePoint. |

### 1. `Get-MeetingRecordingInfo.ps1`

This script retrieves information about Microsoft Teams meeting recordings, including the meeting host, meeting ID, and content correlation ID.

#### Required Permissions
|API|Type|Permission|Note|
|---|---|---|---|
| Microsoft Graph | Application | User.Read.All | - |
| Microsoft Graph | Application | OnlineMeetingRecording.Read.All | - |


#### Inputs
| Input Name | Type | Notes |
|--- | --- | --- |
| meetingOrganizerUserId | String | Organizer's UPN or Entra ID |
| startDateTime | String | Start Time of the Search Range |
| endDateTime | String | End Time of the Search Range |
| MeetingSubject | String | Subject of the Meeting |

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

### 2. `Get-OnlineMeetingRecordingSharePointFileInfo.ps1`

This script retrieves information about the SharePoint file associated with a Microsoft Teams meeting recording.

#### Required Permissions
|API|Type|Permission|Note|
|---|---|---|---|
| SharePoint | Application | Sites.Read.All | - |


#### Inputs
| Input Name | Type | Notes |
|--- | --- | --- |
| OneDriveBaseUrl | String | BaseUrl of OneDrive (e.g. https://\<tenant name\>-my.sharepoint.com/personal/); Part of OneDrive Parameter Set |
| OneDriveRecordingsLibraryName | String | Libray Name where Recordings are stored (typically Documents for OneDrive); Part of OneDrive Parameter Set |
| SharePointTeamsBaseUrl | String | BaseUrl of the SharePoint site hosting Recordings (e.g. https://\<tenant name\>.sharepoint.com/sites/teamsite); Part of Channel Parameter Set |
| SharePointTeamsRecordingsLibraryName | String | Libray Name where Recordings are stored; Part of OneDrive Parameter Set |
| meetingOrganizerUserUpn | String | UPN of the Meeting Organizer |
| MeetingSubject | String | Subject of the Meeting |
| CertificateThumbprint | String | Thumbrpint of the Certificate Used for Authentication |
| ClientId | String | Entra App Id for the App Registration |
| Tenant | String | Tenant in the form of \<tenant name\>.onmicrosoft.com |
| ThreadId | String | Not Used Today |

#### Outputs

`recordingFileInfo`: An object containing information about the SharePoint file associated with the meeting recording:
- Title - Title of the File/Subject of the Meeting
- FileUrl - URL of the Recording
- FileName - File Name of the Recording
- FileType - File Type of the Recording
- SiteUrl - Site Url hosting the Recording
- BaseUrl - Base Url of the Recording


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

### 3. `Get-MeetingTranscript.ps1`

This script retrieves the transcript file for a Microsoft Teams meeting.

#### Required Permissions
|API|Type|Permission|Note|
|---|---|---|---|
| Microsoft Graph | Application | User.Read.All | - |
| Microsoft Graph | Application | OnlineMeetingRecording.Read.All | - |
| Microsoft Graph | Application | OnlineMeetingTranscript.Read.All | - |


#### Inputs

| Input Name | Type | Notes |
|--- | --- | --- |
| meetingOrganizerUserId | String | The UPN of the meeting organizer. |
| meetingId | String | The ID of the meeting. |
| meetingSubject | String | The subject of the meeting. |
| transcriptFilePath | String | The local path where the transcript file will be saved. |
| ContentCorrelationId | String | The content correlation ID of the meeting. |


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

### 4. `Get-WebVTTContent.ps1`

This script formats the transcript data by time increments.

#### Required Permissions
This processes locally, so there are no explicit permissions required.

#### Inputs

| Input Name | Type | Notes |
|--- | --- | --- |
| TranscriptFile | String | Local Path to Transcript file (e.g. c:\temp\transcript.txt) |
| TimeIncrement | Int | Time increment (in seconds) used to chunk the transcript for loading into the Graph |
| Speakers | Array | Optional if you want to override the Speakers list for the Entire Transcript of if you don't have speakers in the VTT file. |


#### Outputs

- `sentences` or `groupedSentences`: An object containing the formatted transcript data with the following properties:
    - Sentence - sentence or groupped sentences as an array 
    - StartTime - start time of sentence in seconds
    - EndTime - end time of sentence in seconds
    - Speakers - array of speaker names for this segment

#### Sample Usage

```ps1
# Parse Transcript File
$transcriptData=Get-WebVTTContent.ps1 -TranscriptFile <path to your transcript file> `
    -TimeIncrement 30 -Speakers "Speaker1","Speaker2"
```
### 5. `Add-TranscriptionItemsToGraph.ps1`

This script loads transcript information into the Graph and is the last step in the sequence.

#### Inputs
| Input Name | Type | Input Notes |
| --- | --- | ---|
| TranscriptItems | PSObject | Custom PS Object that contains the following fields: <ul><li>Sentence - array of sentences</li><li>StartTime - start time of sentece segment in seconds</li><li>EndTime - end time of sentence segement in seconds</li><li>Speakers - array of speakers during this segement</li></ul> |
| MeetingStartDateTime | DateTime | Start Time of the Meeting |
| MeetingEndDateTime | DateTime | End Time of the Meeting |
| MeetingSubject | String | Subject of the Meeting |
| MeetingOrganizer | String | Organizer of the Meeting |
| FileName | String | File Name of the Recording |
| FileExtension | String | File Extension of the Recording |
| FileUrl | String | File Url of the Recording |
| SiteUrl | String | Site Url where Recording is Hosted |
| LastModifiedDateTime | DateTime | Last Modified Date of Recording |
| StreamEndpoint | String | Stream Endpoint |
| SearchExternalConnectionId | String | Connection Id of the Microsoft Graph External Connection created to host these files |

#### Required Permissions

|API|Type|Permission|Note|
|---|---|---|---|
| Microsoft Graph | Application | ExternalItem.ReadWrite.All | If the app is authorized to write to a specific Graph Connector, you could use ExternalItem.ReadWrite.OwnedBy |

#### Sample Usage

```ps1
#Connect to SharePoint Admin
Connect-PnPOnline -Url "$SPOAdminUrl" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $certThumbprint

#Add Items to the Graph
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
```

### `Get-StreamTranscriptViaSharePoint.ps1`

This script retrieves the transcript files for Microsoft Stream videos stored in a SharePoint document library, and can be used to grab those if the recording was not made in Teams.

Thanks to https://www.techmikael.com/2021/01/microsoft-graph-encoding-and-decoding.html for the pointer on how to construct the Drive Id!

#### Required Permissions
|API|Type|Permission|Note|
|---|---|---|---|
| SharePoint | User | Read | ... |

#### Inputs

- `-SiteUrl`: The URL of the SharePoint site.
- `-DocumentLibrary`: The name of the document library containing the videos.
- `-SharePointFolder`: The folder within the document library (optional).
- `-DestinationFolder`: The local folder where the transcript files will be saved.
- `-PnPWebConnection`: The PnP PowerShell connection object.

#### Outputs

- Transcript files saved to the specified local folder.

#### Sample Usage

```ps1
# Update Values below to Get Stream Transcripts Via SharePoint file APIs
$clientId = "<your Entra App Id>"
$siteUrl = "https://<yourtenant>.sharepoint.com/sites/<yoursite>/" # Note that if your site uses something other than /sites/ as the path, you need to update that as well

# Connect to PnP Online
$pnpWebConnection=Connect-PnPOnline -Url $siteUrl `
                  -ClientId $clientId `
                  -Interactive `
                  -ForceAuthentication `
                  -ReturnConnection

# Call Script; if you have a subfolder, you can add the -Folder parameter
Get-StreamTranscriptViaSharePoint -SiteUrl $siteUrl `
    -DocumentLibrary "<your document library>" `
    -PnPWebConnection $pnpWebConnection `
    -DestinationFolder "<output location>" # e.g. c:\temp
```