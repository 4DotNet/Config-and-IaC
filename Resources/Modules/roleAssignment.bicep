// Assign a role at subscription level

@description('The principal to assign the role to')
param principalId string

@description('The principal type')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'


@allowed([
  'Owner'
  'Contributor'
  'Reader'
  'MonitoringMetricsPublisher'
  'NetworkContributor'
  'AppConfigurationDataOwner'
  'AppConfigurationDataReader'
  'AcrPull'
  'AcrPush'
  'KeyVaultSecretUser'
])
@description('Built-in role to assign')
param builtInRoleType string


var role = {
  // https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  Owner: resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Contributor: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  // View all resources, but does not allow you to make any changes.
  Reader: resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  // Enables publishing metrics against Azure resources
  MonitoringMetricsPublisher: resourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
  // Lets you manage networks, but not access to them.
  NetworkContributor: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  // Allows full access to App Configuration data.
  AppConfigurationDataOwner: resourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')
  // Allows read access to App Configuration data.
  AppConfigurationDataReader: resourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071')
  // Allows pulling images from an Azure Container Registry.
  AcrPull: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  // Allows pushing images to an Azure Container Registry.
  AcrPush: resourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
  // Allows read access to Azure Key Vault secrets.
  KeyVaultSecretUser: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
}

resource roleAssignStorage 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().id, principalId, role[builtInRoleType])
  properties: {
    roleDefinitionId: role[builtInRoleType]
    principalType: principalType
    principalId: principalId
  }
}
