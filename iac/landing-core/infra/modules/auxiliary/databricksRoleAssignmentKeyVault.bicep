// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to a KeyVault.
targetScope = 'resourceGroup'

// Parameters
param keyVaultId string

// Variables
var keyVaultName = length(split(keyVaultId, '/')) >= 9 ? last(split(keyVaultId, '/')) : 'incorrectSegmentLength'
var databricksId = 'f42d97a8-e4be-4da1-a1dd-a8b250f42955'

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var secretUser = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}


resource databricksRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(keyVault.id,databricksId))
  scope: keyVault
  properties: {
    roleDefinitionId: secretUser
    principalId: databricksId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
