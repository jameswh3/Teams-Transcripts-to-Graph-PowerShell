
#modify these names and descriptions to match your environment; be sure to use a detailed description (i.e. better than what I have below)
$searchExternalConnectionName = "Contoso Training Content"
$searchExternalConnectionId = "trainingcontent"
$searchExternalConnectionDescription = "Employee training content developed by Contoso"

if (-not (Get-PnPSearchExternalConnection -Identity $searchExternalConnectionId)) {
  New-PnPSearchExternalConnection -Identity $searchExternalConnectionId `
  -Name $searchExternalConnectionName `
  -Description $searchExternalConnectionDescription
}

Set-PnPSearchExternalSchema -ConnectionId $searchExternalConnectionId -SchemaAsText '{
  "baseType": "microsoft.graph.externalItem",
  "properties": [
     {
      "name": "segmentId",
      "type": "String",
      "isQueryable": "true",
      "isExactMatchRequired": "true"
    },
    {
      "name": "segmentTitle",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true",
      "labels": ["title"]
    },
    {
      "name": "segmentStart",
      "type": "String",
      "isRetrievable": "true"
    },
    {
      "name": "segmentEnd",
      "type": "String",
      "isRetrievable": "true"
    },
    {
      "name": "meetingStartDateTime",
      "type": "DateTime",
      "isQueryable": "true",
      "isRetrievable": "true",
      "isRefinable": "true"
    },
    {
      "name": "meetingEndDateTime",
      "type": "DateTime",
      "isQueryable": "true",
      "isRetrievable": "true",
      "isRefinable": "true"
    },
    {
      "name": "meetingSubject",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true"
    },
    {
     "name": "url",
     "type": "String",
     "isSearchable": "false",
     "isRetrievable": "true",
     "labels": [
       "url"
     ]
    },
    {
      "name": "speakerNames",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true"
    },
    {
      "name": "segmentText",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true"
    },
    {
      "name": "fileName",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true",
     "labels": [
       "fileName"
     ]
    },
    {
      "name": "fileExtension",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true",
     "labels": [
       "fileExtension"
     ]
    },
    {
      "name": "lastModifiedDateTime",
      "type": "DateTime",
      "isQueryable": "true",
      "isRetrievable": "true"
    },
    {
      "name": "meetingOrganizer",
      "type": "String",
      "isSearchable": "true",
      "isQueryable": "true",
      "isRetrievable": "true",
      "labels": ["createdBy"]
    }
  ]
}'