# Function to convert time format to seconds
function Convert-ToSeconds {
    param (
        [string]$time
    )
    $parts = $time -split "[:.]"
    return [int]$parts[0] * 3600 + [int]$parts[1] * 60 + [int]$parts[2] + [int]$parts[3] / 1000
}

function Get-WebVTTContent {
    param(
        [String]$VTTFilePath,
        [int]$SegmentSize,
        $Speakers
    )
    BEGIN {
        # Read the content of the VTT file
        $lines = Get-Content -Path $VTTFilePath

        # Initialize variables to process sentences
        $sentences = @()
        $currentSentence = ""
        $currentStartTime = 0
        $currentEndTime = ""
        $currentSpeakers = ""

        # Initialize variables for groupping sentences into segments
        $groupedSentences = @()
        $currentGroup = ""
        $currentGroupSpeakers = @()
        $currentStart = 0
        $currentEnd = $SegmentSize
    }
    PROCESS {
        # Process each line of the VTT file
        
        # Regular expression to match timecodes
        $timecodePattern = "(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3})"
        foreach ($line in $lines) {
            #validate thate line isn't a guid or the WebVTT Line
            if ($line -notmatch "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}-\d+" -and $line -notmatch "WebVTT" -and $line -ne "") {
                #if timestamp line
                if ($line -match $timecodePattern) {
                    if ($currentSentence -ne "") {
                        #existing sentence, so we update the end time
                        $currentEndTime=Convert-ToSeconds -time $matches[2]
                    } #if currentsentence not empty
                    $currentStartTime = Convert-ToSeconds -time $matches[1]
                    $currentEndTime = Convert-ToSeconds -time $matches[2] #not sure if we need this one...
                } #if line is timestamp
                elseif ($line -match "[\.\!\?]") {
                    if ($line -match '<v\s+([^>]+)>') {
                        # Extract the speaker name and add it to the array
                        $currentSpeakers += $matches[1]
                    }
                    $currentSentence += " " + $line
                    $sentences += [PSCustomObject]@{
                        Sentence = ($currentSentence -replace '<[^>]+>','').Trim() 
                        StartTime = $currentStartTime
                        EndTime = $currentEndTime
                        Speakers= $Speakers ? $Speakers : $currentSpeakers
                    }
                    $currentSentence = ""
                    $currentSpeakers = ""
                } #if line contains end of sentence punctuation
                else {
                    #line is just a line of text
                    if ($line -match '<v\s+([^>]+)>') {
                        # Extract the speaker name and add it to the array
                        $currentSpeakers += $matches[1]
                    }
                    $currentSentence += " " + $line
                } #else line
        
        
            } #if line is not guid or WEBVTT
        } #foreach line in lines
        
        # Add the last sentence if it exists
        if ($currentSentence -ne "") {
            $sentences += [PSCustomObject]@{
                Sentence = ($currentSentence -replace '<[^>]+>','').Trim() 
                StartTime = $currentStartTime
                EndTime = $currentEndTime
                Speakers = $Speakers ? $Speakers : $currentSpeakers
            }
        }

        $return = $sentences

        if ($SegmentSize) {
            #Group Sentences
            foreach ($sentence in $sentences) {
                if ($sentence.StartTime -ge $currentStart -and $sentence.StartTime -lt $currentEnd) {
                    $currentGroup += " " + $sentence.Sentence
                    $currentGroupSpeakers += $sentence.Speakers
                }
                else {
                    if ($currentGroup -ne "") {
                        $currentGroupSpeakers = $currentGroupSpeakers | Select-Object -Unique
                        $groupedSentences += [PSCustomObject]@{
                            Sentence  = $currentGroup.Trim()
                            StartTime = $currentStart
                            EndTime   = $currentEnd
                            Speakers = $currentGroupSpeakers
                        }
                    }
                    $currentStart = [int]([math]::Floor($sentence.StartTime / $SegmentSize) * $SegmentSize)
                    $currentEnd = [int]($currentStart + $SegmentSize)
                    $currentGroup = $sentence.Sentence
                    $currentGroupSpeakers=@()
                }
            }
            # Add the last group if there is one
            if ($currentGroup -ne "") {
                $groupedSentences += [PSCustomObject]@{
                    Sentence  = $currentGroup.Trim()
                    StartTime = $currentStart
                    EndTime   = $currentEnd
                    Speakers = $currentGroupSpeakers
                }
            }
            $return = $groupedSentences
        }
    }
    END {
        return $return
    }
}

