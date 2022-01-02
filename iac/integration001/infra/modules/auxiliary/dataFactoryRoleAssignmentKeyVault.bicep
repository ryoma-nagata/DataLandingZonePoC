// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to a KeyVault.
targetScope = 'resourceGroup'

// Parameters
param datafactoryId string
param keyVaultId string

// Variables
var keyVaultName = length(split(keyVaultId, '/')) >= 9 ? last(split(keyVaultId, '/')) : 'incorrectSegmentLength'
var datafactorySubscriptionId = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[2] : subscription().subscriptionId
var datafactoryResourceGroupName = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[4] : resourceGroup().name
var datafactoryName = length(split(datafactoryId, '/')) >= 9 ? last(split(datafactoryId, '/')) : 'incorrectSegmentLength'

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var secretUser = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryName
  scope: resourceGroup(datafactorySubscriptionId, datafactoryResourceGroupName)
}

resource datafactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(keyVault.id, datafactory.id))
  scope: keyVault
  properties: {
    roleDefinitionId: secretUser
    principalId: datafactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
