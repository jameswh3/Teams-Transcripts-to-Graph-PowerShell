#region STEP 1
    #Connect to SharePoint and Get File Info#

    $clientId = "<EntraAppId that you've registered>" #needs read access to the SharePoint site
    $siteUrl = "https://<your tenant>.sharepoint.com/sites/<your teamsite>/" #note that if your site uses something other than /sites/ as the path, you need to update that as well

    $pnpWebConnection=Connect-PnPOnline -Url $siteUrl `
                    -ClientId $clientId `
                    -Interactive `
                    -ForceAuthentication `
                    -ReturnConnection

    #Call Script; if you have a subfolder, you can add the -Folder parameter
    $transcriptFile=Get-StreamTranscriptViaSharePoint -SiteUrl $siteUrl `
        -DocumentLibrary "Videos" `
        -PnPWebConnection $pnpWebConnection `
        -DestinationFolder "c:\temp" #e.g. c:\temp
#endregion

#region STEP 2
    #Parse Transcript File#
    $transcriptData=Get-WebVTTContent `
        -TranscriptFile $transcriptFile `
        -SegmentSize 30
#endregion

#region STEP 3a
    #Connect to SharePoint Admin#
    $SPOAdminUrl = "https://<your tenant name>-admin.sharepoint.com"
    $streamEndpoint="/_layouts/15/stream.aspx"
    $searchExternalConnectionId="<Id of the search external connection>"
    Connect-PnPOnline -Url "$SPOAdminUrl" `
                    -ClientId $ClientId `
                    -Tenant $Tenant `
                    -Thumbprint $certThumbprint
#endregion

#region STEP 3b
    #Add Transcript Items to Graph#
    $category="<add your category for this video>"
    Add-TranscriptItemsToGraph -TranscriptItems $transcriptData `
        -StreamEndpoint $streamEndpoint `
        -Category $category `
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
#endregion