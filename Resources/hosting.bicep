
param app string
param prefix string
param environment string
param sharedResourceGroup string = 'infra'

param sku string

param deploymentTimestamp string = utcNow('yyMMddhhmmss')

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
  hostingPlanName: '${prefix}-asp-${env}'
  managedIdentityName: '${prefix}-id-${env}'
  appName: '${prefix}-app-${env}-${app}'
  logging: {
    resourceGroup: '${prefix}-${sharedResourceGroup}-${env}'
    appinsights: '${prefix}-appinsights-${env}'
    logAnalytics: '${prefix}-law-${env}'
  }
  keyvault:{
    resourceGroup: '${prefix}-${sharedResourceGroup}-${env}'
    name: '${prefix}-keyvault-${env}'
    sku: 'standard'
  }
  appconfig: {
    resourceGroup: '${prefix}-${sharedResourceGroup}-${env}'
    name: '${prefix}-appconfig-${env}'
    sku: 'standard'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: settings.hostingPlanName
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

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: settings.appconfig.name
  scope: resourceGroup(settings.appconfig.resourceGroup)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: settings.logging.appinsights
  scope: resourceGroup(settings.logging.resourceGroup)
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: settings.managedIdentityName
  location: location
}

module appConfigReader 'Modules/roleAssignment.bicep' = {
  name: 'appConfigReader--${deploymentTimestamp}'
  scope: resourceGroup(settings.appconfig.resourceGroup)
  params: {
    
    builtInRoleType: 'AppConfigurationDataReader'
    principalId: managedIdentity.properties.principalId
  }
}


module keyVaultReader 'Modules/roleAssignment.bicep' = {
  name: 'keyVaultReader--${deploymentTimestamp}'
  scope: resourceGroup(settings.keyvault.resourceGroup)
  params: {
    
    builtInRoleType: 'KeyVaultSecretUser'
    principalId: managedIdentity.properties.principalId
  }
}

resource name_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: settings.appName
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
        {
          name: 'AppConfig__Uri'
          value: appConfig.properties.endpoint
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'MANAGED_CLIENT_ID'
          value: managedIdentity.properties.clientId
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
