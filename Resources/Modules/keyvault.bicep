param name string
@description('The location of the resources.')
param location string = resourceGroup().location
@allowed(['standard','premium'])
param sku string = 'standard'
param deploymentTimestamp string
param logAnalyticsWorkspace string
@description('A list of IP addresses that should have access to the KeyVault.')
param allowedIps array = []
@description('Set to true on first deployment only.')
param deployFromScratch bool = false

var devopsIps = [       
    '40.74.28.0/23' // https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops&tabs=IP-V4#inbound-connections
]

// https://ochzhen.com/blog/key-vault-access-policies-using-azure-bicep#keep-existing-access-policies-when-redeploying-a-key-vault
// If it's a new key vault, we pass empty array but it could be any static set of access policies
var accessPolicies = deployFromScratch ? [] : reference(resourceId('Microsoft.KeyVault/vaults', name), '2019-09-01').accessPolicies

module keyvault 'keyvault-with-policies.bicep' = {
  name: 'keyvault-inner-${deploymentTimestamp}'
  params: {
    name: name
    location: location
    accessPolicies: accessPolicies
    logAnalyticsWorkspace: logAnalyticsWorkspace
    sku: sku
    ipRules: [ for ip in concat(allowedIps, devopsIps): { value: ip } ]
  }
}
