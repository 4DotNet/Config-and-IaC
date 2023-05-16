param name string
@description('The location of the resources.')
param location string = resourceGroup().location

@allowed(['standard','premium'])
param sku string = 'standard'

@description('A list of IP addresses that should have access to the KeyVault.')
param ipRules array 
param accessPolicies array  
param developersGroupObjectId string = ''
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
    enableRbacAuthorization: false
    accessPolicies: accessPolicies
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny' // Set to Deny to enable firewall
      ipRules: ipRules
    }
  }
}

resource accessPolicyForDevs 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = if(!empty(developersGroupObjectId)) {
  name: 'replace'
  parent: keyvault
  properties: {
    accessPolicies: [
      {
        objectId: developersGroupObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
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
