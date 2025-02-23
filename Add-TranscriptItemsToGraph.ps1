function Convert-SecondsToTime {
    param (
        $seconds
    )  
    if ($seconds -isnot [int]) {
        $seconds=[Convert]::ToInt32($seconds)
    }
    $hours = [math]::Floor($seconds / 3600)
    if ($hours.Length -lt 2) {
        $hours = $hours.ToSTring().PadLeft(2, '0')
    }
    $minutes = [math]::Floor(($seconds % 3600) / 60)
    if ($minutes.Length -lt 2) {
        $minutes = $minutes.ToSTring().PadLeft(2, '0')
    }
    $remainingSeconds = $seconds % 60
    if ($remainingSeconds.Length -lt 2) {
        $remainingSeconds = $remainingSeconds.ToSTring().PadLeft(2, '0')
    }
    return "$hours`:$minutes`:$remainingSeconds"
}

function Add-TranscriptItemsToGraph {
    param(
        $TranscriptItems,
        $MeetingStartDateTime,
        $MeetingEndDateTime,
        $MeetingSubject,
        $MeetingOrganizer,
        $FileName,
        $FileExtension,
        $FileUrl,
        $SiteUrl,
        $LastModifiedDateTime,
        $StreamEndpoint,
        $SearchExternalConnectionId
    )
    BEGIN {
        write-host "  Adding Transcript Items to Graph"

        $meetingStartDateTime=$MeetingStartDateTime
        $meetingEndDateTime=$MeetingEndDateTime
        $meetingSubject=$MeetingSubject
        $meetingOrganizer=$MeetingOrganizer
        
        $fileName=$FileName
        $fileExtension=$FileExtension
        $lastModifiedDateTime=$LastModifiedDateTime
    }
    PROCESS {
        foreach ($transcriptItem in $TranscriptItems) {
            $segmentStart=$transcriptItem.StartTime
            $segmentEnd=$transcriptItem.EndTime

            $segmentStartTimeStamp = Convert-SecondsToTime -seconds $segmentStart
            $segmentEndTimeStamp = Convert-SecondsToTime -seconds $segmentEnd

            $segmentTitle=$meetingSubject + " - [$segmentStartTimeStamp - $segmentEndTimeStamp]"
            $segmentId=$segmentTitle

            $encodedFileRef=[URI]::EscapeUriString($FileUrl).replace("/","%2F")
            $playbackOptions=[URI]::EscapeUriString("&nav={""playbackOptions"":{""startTimeInSeconds"":$segmentStart}}")
            $fullUrl="$SiteUrl$StreamEndpoint"+"?id=$encodedFileRef"+"$playbackOptions"
            <#
                $Properties=@{
                    "segmentId" = "$segmentId";
                    "segmentTitle"= "$segmentTitle";
                    "segmentStart" = "$segmentStart";
                    "segmentEnd" = "$segmentEnd";
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
                }
                write-host $Properties
            #>
            $speakerNames=$transcriptItem.Speakers -join ","
            $segmentText=$transcriptItem.Sentence | Out-String
            Set-PnPSearchExternalItem -ConnectionId $SearchExternalConnectionId `
                -ItemId (new-guid) `
                -Properties @{
                    "segmentId" = "$segmentId";
                    "segmentTitle"= "$segmentTitle";
                    "segmentStart" = "$segmentStart";
                    "segmentEnd" = "$segmentEnd";
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