// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of a useer assigned identity to a resource group.
targetScope = 'resourceGroup'

// Parameters
param userId string 
param roleId string 

// Variables
var RBACrole = resourceId('Microsoft.Authorization/roleDefinitions', roleId)

// Resources

resource resourceGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id,userId,roleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: RBACrole
    principalId: userId
    principalType: 'User'
  }
}
// Outputs
