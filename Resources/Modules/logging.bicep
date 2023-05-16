@description('The location of the resources.')
param location string = resourceGroup().location

@description('Resource name of the log analytics workspace')
param logAnalyticsName string

@description('Resource name of the app insights instance')
param appInsightsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: logAnalyticsName
 }
 
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  location: location
  name: appInsightsName
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output logAnalytics string = logAnalyticsWorkspace.id
