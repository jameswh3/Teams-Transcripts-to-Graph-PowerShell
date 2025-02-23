#Requires -Modules Microsoft.Graph

function Get-MeetingRecordingInfo {
    param(
        [string]$meetingOrganizerUserId,
        $startDateTime,
        $endDateTime,
        $MeetingSubject
    )
    BEGIN {
        $meetingHost = Get-MgUser -UserId $meetingOrganizerUserId
        $meetingOrganizerUserId = $meetingHost.Id
        $meetingOrganizerUPN = $meetingHost.UserPrincipalName
        write-host "Retrieving Meeting Recording Details for $meetingOrganizerUPN"
        $uri="https://graph.microsoft.com/v1.0/users/$meetingOrganizerUserId/onlineMeetings/getAllRecordings(meetingOrganizerUserId='$meetingOrganizerUserId',startDateTime=$startDateTime,endDateTime=$endDateTime)"
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        $meetingObject = New-Object -TypeName PSObject

    }
    PROCESS {
        foreach ($meetingRecording in $response.value) {
            $meetingId=$meetingRecording.MeetingId
            $uri = "https://graph.microsoft.com/v1.0/users/$meetingOrganizerUserId/onlineMeetings/$meetingId"
            $meetingDetails=Invoke-MgGraphRequest -Method GET -Uri $uri
            write-host "  Processing Meeting - $($meetingDetails.subject)"
            if ($meetingDetails.subject -eq $MeetingSubject) {
                $meetingObject | Add-Member -MemberType NoteProperty -Name "MeetingId" -Value $meetingDetails.id
                $meetingObject | Add-Member -MemberType NoteProperty -Name "MeetingSubject" -Value $meetingDetails.subject
                $meetingObject | Add-Member -MemberType NoteProperty -Name "StartDateTime" -Value $meetingDetails.startDateTime
                $meetingObject | Add-Member -MemberType NoteProperty -Name "EndDateTime" -Value $meetingDetails.endDateTime
                $meetingObject | Add-Member -MemberType NoteProperty -Name "MeetingHostUPN" -Value $meetingOrganizerUPN
                $meetingObject | Add-Member -MemberType NoteProperty -Name "MeetingHostId" -Value $meetingOrganizerUserId
                $meetingObject | Add-Member -MemberType NoteProperty -Name "ContentCorrelationId" -Value $recordingDetails.contentCorrelationId #doesn't work b/c this URI doesn't include this field
            }
        }
    }
    END {
        return $meetingObject
    }
}