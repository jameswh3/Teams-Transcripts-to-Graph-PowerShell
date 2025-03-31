#Requires -Modules PnP.PowerShell
#Requires -Version 7.0

function Get-StreamTranscriptViaSharePoint {
    param(
        $SiteUrl,
        $DocumentLibrary,
        $SharePointFolder,
        $DestinationFolder,
        [Parameter(Mandatory=$true)]
            [PnP.PowerShell.Commands.Base.PnPConnection]$PnPWebConnection
    )
    BEGIN {
        #assumes root web is the site hosting videos
        $site=get-pnpsite -Connection $PnPWebConnection -Includes Id
        $web=get-pnpweb -Connection $PnPWebConnection -Includes Id
        $library=Get-PnPList $DocumentLibrary -Connection $PnPWebConnection -Includes Id
        #construct the drive id
        $siteIdGuid = $site.Id
        $webIdGuid = $web.Id
        $listIdGuid = $library.Id
        $DestinationFolder=$DestinationFolder.Trim("\")
        $bytes = $siteIdGuid.ToByteArray() + $webIdGuid.ToByteArray() + $listIdGuid.ToByteArray()
        $driveId = "b!" + ([Convert]::ToBase64String($bytes)).Replace('/','_').Replace('+','-') 
        write-host $driveId
        $folderUrl="$DocumentLibrary"
        if ($SharePointFolder) {
            $folderUrl="$folderUrl/$SharePointFolder"
        }
        Write-Host $folderUrl
        $files=get-pnpfileinfolder -FolderSiteRelativeUrl $folderUrl -Connection $pnpWebConnection -Includes UniqueId,ServerRelativeUrl,Name
        $token=Get-PnPAccessToken -ResourceTypeName SharePoint
        $transcripts=@()
    }
    PROCESS {
        foreach ($file in $files) {
            $itemId=$file.UniqueId
            $itemName=$file.Name
            $itemName=$itemName.Replace("-Meeting Recording.mp4","").Replace("mp4","")
            $transcriptsRequestUrl="$($site.Url)/_api/v2.1/drives/$driveId/items/$itemId/media/transcripts"
            write-host $transcriptsRequestUrl
            $response=Invoke-PnPSPRestMethod -Method Get -Url $transcriptsRequestUrl -Connection $PnPWebConnection
            write-host $response
            $i=1
            foreach ($transcript in $response.value) {
                $headers = @{
                    "Authorization" = "Bearer $token"
                }
                Invoke-WebRequest -uri $transcript.temporaryDownloadUrl `
                    -OutFile "$DestinationFolder\$itemName - $i.vtt" `
                    -Headers $headers
                $transcripts+="$DestinationFolder\$itemName - $i.vtt"
                $i=$i+1
            }
        }
    }
    END {
        return $transcripts
    }
}