@description('The location of the resources.')
param location string = resourceGroup().location
param name string
param sku string
@description('Set this to the objectId for a group to assign the data owner role within the AppConfig resource')
param dataOwnersGroupId string = '' // note that the service connection used to deploy this must have permission to assign roles
param dataOwnersUserIds array = [] // note that the service connection used to deploy this must have permission to assign roles

resource appconfig 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    disableLocalAuth: true
    enablePurgeProtection: false
    publicNetworkAccess: 'Enabled'
    //softDeleteRetentionInDays: (settings[environment].appconfig.sku == 'standard' ? 7 : 0)
  }
}

var appConfigurationDataOwner = resourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')

resource roleDataOwners 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for userId in dataOwnersUserIds: {
  scope: appconfig
  name: guid(appconfig.id, userId, appConfigurationDataOwner)
  properties: {
    roleDefinitionId: appConfigurationDataOwner
    principalId: userId
    principalType: 'User'
  }
}]

resource roleDevGroupDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if(!empty(dataOwnersGroupId)) {
  scope: appconfig
  name: guid(appconfig.id, dataOwnersGroupId, appConfigurationDataOwner)
  properties: {
    roleDefinitionId: appConfigurationDataOwner
    principalId: dataOwnersGroupId
    principalType: 'Group'
  }
}
