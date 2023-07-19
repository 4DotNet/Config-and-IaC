// Deploys shared resources for an environment
//
// Note: this doesn't include a VNet setup for simplicity. 
//
@allowed([
  'development'
  'test'
  'staging'
  'production'
])
@description('The environment to deploy the resource for.')
param environment string

@description('A prefix to use for all resource names.')
param prefix string

param location string = resourceGroup().location

@description('The object ID of the administrative user. That would be you 🫵. Run this command to get that id:  az ad signed-in-user show --query id --output tsv')
param adminObjectId string

param deploymentTimestamp string = utcNow('yyMMddhhmmss')

// Short names for environments, used in resource names
var envNames = {
  development: 'dev'
  test: 'tst'
  staging: 'acc'
  production: 'prd'
}

var env = envNames[environment]

// All resource names
var settings = {
  logging: {
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

module keyvault './Modules/keyvault.bicep' = {
  name: 'keyvault-${deploymentTimestamp}'
  params: {
    name: settings.keyvault.name
    location: location
    logAnalyticsWorkspace: logging.outputs.logAnalytics
    enableFirewall: false
    ipRules: [ ]
    adminObjectIds: [ adminObjectId ]
  }
}

module appConfigService './Modules/appConfig.bicep' = {
  name: 'appconfig-${deploymentTimestamp}'
  params:{
    location: location
    name: settings.appconfig.name
    sku:  settings.appconfig.sku
    dataOwnersUserIds: [ adminObjectId ]
  }
}

module logging 'Modules/logging.bicep' = {
  name: 'logging-${deploymentTimestamp}'
  params: {
    location: location
    appInsightsName: settings.logging.appinsights
    logAnalyticsName: settings.logging.logAnalytics
  }
}
