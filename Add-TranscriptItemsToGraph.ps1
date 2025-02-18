function Add-TranscriptItemsToGraph {
    param(
        $TranscriptItems,
        $MeetingRecordingInfo,
        $RecordingFileInfo,
        $StreamEndpoint,
        $SearchExternalConnectionId
    )
    BEGIN {
        write-host "  Adding Transcript Items to Graph"

        $meetingStartDateTime=[System.DateTime]($MeetingRecordingInfo.StartDateTime)
        $meetingEndDateTime=[System.DateTime]($MeetingRecordingInfo.EndDateTime)
        $meetingSubject=$MeetingRecordingInfo.MeetingSubject
        
        $fileName=$RecordingFileInfo.FileName
        $fileExtension=$RecordingFileInfo.FileType
        $lastModifiedDateTime=[System.DateTime]$meetingEndDateTime
        $meetingOrganizer=$MeetingRecordingInfo.MeetingHostId

    }
    PROCESS {
        foreach ($transcriptItem in $TranscriptItems.GetEnumerator()) {
            $segmentId=$meetingSubject + "-" + $transcriptItem.Key
            $segmentTitle=$meetingSubject + "-" + $transcriptItem.Key
            $segmentStart=$transcriptItem.Value.StartTime
            $segmentEnd=$transcriptItem.Value.EndTime

            $encodedFileRef=[URI]::EscapeUriString($($recordingFileInfo.FileUrl)).replace("/","%2F")
            $playbackOptions=[URI]::EscapeUriString("&nav={""playbackOptions"":{""startTimeInSeconds"":$segmentStart}}")
            $fullUrl="$($RecordingFileInfo.SiteUrl)$StreamEndpoint"+"?id=$encodedFileRef"+"$playbackOptions"

            $speakerNames=$transcriptItem.Value.Speakers -join ","
            $segmentText=$transcriptItem.Value.TranscriptText | Out-String
            
            Set-PnPSearchExternalItem -ConnectionId $SearchExternalConnectionId `
            -ItemId (new-guid) `
            -Properties @{
                "segmentId" = "$segmentId";
                "segmentTitle"= "$segmentTitle";
                "segmentStart" = "$segmentStart";
                "segmentEnd" = "$segmentEnd"
                "meetingSubject" = "$meetingSubject";
                "meetingStartDateTime" = $meetingStartDateTime;
                "meetingEndDateTime" = $meetingEndDateTime;
                "lastModifiedDateTime" = $lastModifiedDateTime;
                "url" = "$fullUrl";
                "speakerNames" = "$speakerNames";
                "segmentText" = "$segmentText";
                "fileName" = "$fileName";
                "fileExtension" = "$fileExtension";
                "meetingOrganizer" = "$meetingOrganizer"  
            } `
            -ContentValue "$segmentText" `
            -ContentType Text `
            -GrantEveryone

            }
    }
    END {
    }
}