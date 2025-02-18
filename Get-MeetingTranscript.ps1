Function Get-MeetingTranscript {
    param(
        [string]$MeetingOrganizerUserId,
        [string]$MeetingId,
        [string]$MeetingSubject,
        [string]$TranscriptFilePath,
        [string]$ContentCorrelationId
    )
    BEGIN {
        write-host "  Retrieving Transcripts for $MeetingSubject"
        $uri = "https://graph.microsoft.com/v1.0/users/$meetingOrganizerUserId/onlineMeetings/$meetingId/transcripts"
        $transcripts=Invoke-MgGraphRequest -Method GET -Uri $uri
    } 
    PROCESS {
        foreach ($transcript in $transcripts.value) {
            write-host "    Processing Transcript - $($transcript.id)"
            $uri=$transcript.transcriptContentUrl
            Invoke-MgGraphRequest -Method GET -Uri $uri -OutputFilePath "$transcriptFilePath\$meetingSubject-transcript.txt" -ProgressAction SilentlyContinue
        }
    }
    END {

    return "$transcriptFilePath\$meetingSubject-transcript.txt"
    }
}