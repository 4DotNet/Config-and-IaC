param name string
@description('The location of the resources.')
param location string = resourceGroup().location

@allowed(['standard','premium'])
param sku string = 'standard'

param enableFirewall bool
@description('A list of IP addresses that should have access to the KeyVault.')
param ipRules array 
param developersGroupObjectId string = ''
param adminObjectIds array = []
param logAnalyticsWorkspace string

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    //createMode: 'recover' // Use create exclusively when the KV doesn't exist yet or access policies added outside this template will be removed
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: enableFirewall ? 'Deny' : 'Allow' // Set to Deny to enable firewall
      ipRules: ipRules
    }
  }
}

var keyVaultAdminRole = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource roleAssignOwner 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for owner in adminObjectIds : {
    name: guid(keyvault.id, owner, keyVaultAdminRole)
    scope: keyvault
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',keyVaultAdminRole)
      principalType: 'User'
      principalId: owner
    }
  }
]

resource roleAssignStorage 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(!empty(developersGroupObjectId)) {
  name: guid(keyvault.id, developersGroupObjectId, keyVaultAdminRole)
  scope: keyvault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',keyVaultAdminRole)
    principalType: 'Group'
    principalId: developersGroupObjectId
  }
}

@description('Send audit logs and metrics to LogAnalytics. This provides insights into security and operation health.')
resource auditLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: keyvault
  properties: {
    workspaceId: logAnalyticsWorkspace
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output keyvaultId string = keyvault.id
