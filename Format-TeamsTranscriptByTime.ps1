function ConvertTo-Seconds {
    param (
        [string]$time
    )
    $parts = $time -split "[:.]"
    return [int]$parts[0] * 3600 + [int]$parts[1] * 60 + [int]$parts[2]
}

Function Format-TeamsTranscriptByTime {
    param(
        [string]$TranscriptFile, #WebVTT file
        [int]$TimeIncrement = 30
    )
    BEGIN {
        # Read the WebVTT file
        $content = Get-Content -Path $TranscriptFile

        # Initialize variables
        $currentSegment = @()
        $currentStartTime = 0
        $currentEndTime = $TimeIncrement

        $transcriptData = @{}
        $currentSpeakers=@()
        $transcriptKey=""

        $groupedSentences = @()

    }
    PROCESS{
        # Process each line in the WebVTT file
        foreach ($line in $content) {
            if ($line -match '<v\s+([^>]+)>') {
                # Extract the speaker name and add it to the array
                $currentSpeakers += $matches[1]
            }
            if ($line -match "(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3})") {
                $startTime = ConvertTo-Seconds $matches[1]
                #$endTime = ConvertTo-Seconds $matches[2] #didnt use this previously, but leaving it in case it's needed later

                if ($startTime -lt $TimeIncrement) {
                    $transcriptKey="[$([TimeSpan]::FromSeconds(0).ToString()) - $([TimeSpan]::FromSeconds($TimeIncrement).ToString())]"
                    if (-not ($transcriptData.ContainsKey($transcriptKey))) {
                        Write-host "    Adding new transcript segment: $transcriptKey"
                        $transcriptData.add($transcriptKey,@{
                            StartTime = $currentStartTime
                            EndTime = $TimeIncrement
                            TranscriptText = @()
                            Speakers = @()
                            WebVTTLine=@()
                        })
                    }
                }

                if ($startTime -ge $currentEndTime) {
                    $currentSpeakers=@()
                    #added the timeincrement as the offset, as the times were off by the time increment
                    $transcriptKey="[$([TimeSpan]::FromSeconds($currentStartTime+$TimeIncrement).ToString()) - $([TimeSpan]::FromSeconds($currentEndTime+$TimeIncrement).ToString())]"
                    Write-host "    Adding new transcript segment: $transcriptKey"
                    $transcriptData.add($transcriptKey,@{
                        StartTime = $currentStartTime+$TimeIncrement
                        EndTime = $currentEndTime+$TimeIncrement
                        TranscriptText = @()
                        Speakers = @()
                    })
                    $currentSegment = @()
                    $currentStartTime = $currentEndTime
                    $currentEndTime += $TimeIncrement
                }
            } elseif ($line -ne "" -and $line -notmatch "WEBVTT") {
                $currentSegment += $line -replace '<[^>]+>',''
                $transcriptData[$transcriptKey].TranscriptText = $currentSegment
                $transcriptData[$transcriptKey].WebVTTLine += $line
                $transcriptData[$transcriptKey].Speakers = $currentSpeakers
            }
        }

        # Add the last segment
        if ($currentSegment.Count -gt 0) {
            $transcriptData[$transcriptKey].TranscriptText += $currentSegment
            $transcriptData[$transcriptKey].Speakers += $currentSpeakers
            $transcriptData[$transcriptKey].Speakers = $transcriptData[$transcriptKey].Speakers | Select-Object -Unique
        }
    }
    END {
        foreach ($transcriptDatum in $transcriptData.GetEnumerator()) {
            $groupedSentences += [PSCustomObject]@{
                Sentence  = ($transcriptDatum.Value.TranscriptText -join " ")
                StartTime = [int]$transcriptDatum.Value.StartTime
                EndTime   = [int]$transcriptDatum.Value.EndTime
                Speakers = ($transcriptDatum.Value.Speakers | Select-Object -Unique)
            }
        }
        return $groupedSentences
    }
}