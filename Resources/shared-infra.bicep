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

param deploymentTimestamp string = utcNow('yyMMddhhmmss')

param initialDeployment bool = false

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

module keyVault './Modules/keyvault.bicep' ={
  name: 'keyvault-${deploymentTimestamp}'
  params:{
    location: location
    deploymentTimestamp: deploymentTimestamp
    name: settings.keyvault.name
    logAnalyticsWorkspace: logging.outputs.logAnalytics
    deployFromScratch: initialDeployment
  }
}

module appConfigService './Modules/appConfig.bicep' = {
  name: 'appconfig-${deploymentTimestamp}'
  params:{
    location: location
    name: settings.appconfig.name
    sku:  settings.appconfig.sku
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
