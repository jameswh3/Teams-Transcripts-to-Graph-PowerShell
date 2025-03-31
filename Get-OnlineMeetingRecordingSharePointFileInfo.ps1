Function Get-OnlineMeetingRecordingSharePointFileInfo {
    [CmdletBinding(DefaultParameterSetName = 'OneDrive')]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = 'OneDrive')]
            [string]
            $OneDriveBaseUrl,
        [Parameter(Mandatory = $true,
            ParameterSetName = 'OneDrive')]
            [string]
            $OneDriveRecordingsLibraryName,
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Channel')]
            [string]
            $SharePointTeamsBaseUrl,
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Channel')]
            [string]
            $SharePointTeamsRecordingsLibraryName,
        [Parameter(Mandatory = $true)]
            [string]
            $meetingOrganizerUserUpn,
        [Parameter(Mandatory = $true)]
            [string]
            $MeetingSubject,
        [Parameter(Mandatory = $true)]
            [string]
            $CertificateThumbprint,
        [Parameter(Mandatory = $true)]
            [string]
            $ClientId,
            [Parameter(Mandatory = $true)]
            [string]
            $Tenant,
        [Parameter(Mandatory = $false)]
            [string]
            $ThreadId

    )
    BEGIN {
        if ($PSCmdlet.ParameterSetName -eq 'OneDrive') {
            $OneDriveSite = $meetingOrganizerUserUpn.Replace("@","_").Replace(".","_")
            write-host "  Processing Recordings in $OneDriveSite"
            $OneDriveSiteUrl="$OneDriveBaseUrl/personal/$OneDriveSite"
            Connect-PnPOnline -Url "$OneDriveBaseUrl/personal/$OneDriveSite" `
                -ClientId $ClientId `
                -Tenant $Tenant `
                -Thumbprint $CertificateThumbprint
            $recordingFiles=Get-PnPListItem -List $OneDriveRecordingsLibraryName -Query "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='Title' /><Value Type='Text'>$meetingSubject</Value></Eq></Where></Query></View>"
            $baseUrl=$OneDriveBaseUrl
        } else {
            #Teams Recording
            #todo - do some research on how to isolate Teams Channel Recording file
            write-host "This script doesn't yet support Teams Recordings" -ForegroundColor Red

        }        
        $RecordingFileInfo = New-Object -TypeName PSObject
    }
    PROCESS {
        #foreach file, get fileref
        foreach ($rf in $recordingFiles) {
            #we *should* only have one file b/c we are filtering by Title
            #retreive the threadid from the file info to validate that we have the correct recording
            #get and store the necessary info; can likely check threadid later to ensure it's the right file
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "Title" -Value $rf.FieldValues.Title
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "FileUrl" -Value $rf.FieldValues.FileRef
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "FileName" -Value $rf.FieldValues.FileLeafRef
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "FileType" -Value $rf.FieldValues.File_x0020_Type
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "SiteUrl" -Value $OneDriveSiteUrl #if Teams Channel, update to Channel Url
            $RecordingFileInfo | Add-Member -MemberType NoteProperty -Name "BaseUrl" -Value $baseUrl
        }
    }
    END {
        return $RecordingFileInfo
    }
}