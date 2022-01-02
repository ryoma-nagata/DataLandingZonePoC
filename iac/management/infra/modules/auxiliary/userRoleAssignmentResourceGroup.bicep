// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of a useer assigned identity to a resource group.
targetScope = 'resourceGroup'

// Parameters
param userId string 

// Variables
var keyContainerAdmin = resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')

// Resources

resource resourceGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id,userId,'keyContainerAdmin')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyContainerAdmin
    principalId: userId
    principalType: 'User'
  }
}
// Outputs
