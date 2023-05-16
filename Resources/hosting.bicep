
param name string
param prefix string
param environment string
param sharedResourceGroup string = 'infra'

param hostingPlanName string
param managedIdentityName string
param sku string

@description('The resource location. Defaults to the resource group location.')
param location string = resourceGroup().location

// Short names for environments, used in resource names
var envNames = {
  development: 'dev'
  test: 'tst'
  staging: 'acc'
  production: 'prd'
}

var env = envNames[environment]

var settings = {
  logging: {
    resourceGroup: '${prefix}-${sharedResourceGroup}-${env}'
    appinsights: '${prefix}-appinsights-${env}'
    logAnalytics: '${prefix}-law-${env}'
  }
  keyvault:{
    name: '${prefix}-keyvault-${env}'
    sku: 'standard'
  }
  appconfig: {
    name: '${prefix}-appconfig-${env}'
    sku: 'standard'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  tags: {
  }
  properties: {
    reserved: true
    zoneRedundant: false
  }
  sku: {
    name: sku
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: settings.logging.appinsights
  scope: resourceGroup(settings.logging.resourceGroup)
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: managedIdentityName
  location: location
}

resource name_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }  
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        // TODO : appconfig url
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
      ]
      linuxFxVersion: 'DOTNETCORE|7.0'
      alwaysOn: (!startsWith(sku, 'B') && !startsWith(sku, 'F')) // always On is not available in basic and free tier
      ftpsState: 'Disabled'
    }
    keyVaultReferenceIdentity: managedIdentity.id
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}
