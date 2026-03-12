#Requires -Modules PnP.PowerShell
#Requires -Version 7.0

function Get-StreamTranscriptViaSharePoint {
    <#
    .SYNOPSIS
        Downloads transcript (.vtt) files for Stream videos stored in SharePoint.

    .DESCRIPTION
        Connects to a SharePoint document library, locates video files, retrieves their
        associated transcripts via the SharePoint REST API, and downloads each transcript
        as a .vtt file to a local destination folder.

    .PARAMETER SiteUrl
        The URL of the SharePoint site that hosts the videos
        (e.g., https://contoso.sharepoint.com/sites/mysite).
        Used to construct REST API request URLs.

    .PARAMETER DocumentLibrary
        The site-relative name or path of the document library containing the video files
        (e.g., "Documents" or "Stream migrated videos").
        Used to look up the library ID for drive ID construction and to enumerate files.

    .PARAMETER SharePointFolder
        Optional. A subfolder path within the document library to scope the search for video files
        (e.g., "Recordings/2024"). If omitted, files are retrieved from the root of the library.

    .PARAMETER DestinationFolder
        The local file system path where downloaded transcript (.vtt) files will be saved
        (e.g., "C:\Transcripts"). Leading/trailing backslashes are trimmed automatically.

    .PARAMETER PnPWebConnection
        A PnP PowerShell connection object targeting the SharePoint site, obtained via
        Connect-PnPOnline. Used for all PnP and REST API calls against the site.
        This parameter is mandatory.
    #>
    param(
        [Parameter(HelpMessage="URL of the SharePoint site hosting the videos (e.g., https://contoso.sharepoint.com/sites/teamsite).")]
        [string]$SiteUrl,

        [Parameter(HelpMessage="Site-relative name or path of the document library containing the video files (e.g., 'Documents').")]
        [string]$DocumentLibrary,

        [Parameter(HelpMessage="Optional subfolder path within the document library to scope the file search (e.g., 'Recordings/2024').")]
        [string]$SharePointFolder,

        [Parameter(HelpMessage="Local file system path where downloaded .vtt transcript files will be saved (e.g., 'C:\Transcripts').")]
        [string]$DestinationFolder,

        [Parameter(Mandatory=$true, HelpMessage="PnP PowerShell connection object for the SharePoint site, obtained via Connect-PnPOnline.")]
            [PnP.PowerShell.Commands.Base.PnPConnection]$PnPWebConnection
    )
    BEGIN {
        #assumes root web is the site hosting videos
        $site=get-pnpsite -Connection $PnPWebConnection -Includes Id
        $web=get-pnpweb -Connection $PnPWebConnection -Includes Id
        $library=Get-PnPList $DocumentLibrary -Connection $PnPWebConnection -Includes Id
        #construct the drive id
        $DestinationFolder=$DestinationFolder.Trim("\")
        $siteIdGuid = $site.Id
        $webIdGuid = $web.Id
        $listIdGuid = $library.Id
        $bytes = $siteIdGuid.ToByteArray() + $webIdGuid.ToByteArray() + $listIdGuid.ToByteArray()
        $driveId = "b!" + ([Convert]::ToBase64String($bytes)).Replace('/','_').Replace('+','-') 
        #write-host $driveId
        $folderUrl="$DocumentLibrary"
        if ($SharePointFolder) {
            $folderUrl="$folderUrl/$SharePointFolder"
        }
        Write-Host $folderUrl
        $files=get-pnpfileinfolder -FolderSiteRelativeUrl $folderUrl -Connection $pnpWebConnection -Includes UniqueId,ServerRelativeUrl,Name
        $token=Get-PnPAccessToken -ResourceTypeName SharePoint -Connection $PnPWebConnection
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
            write-host ($response | ConvertTo-Json -Depth 5)
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