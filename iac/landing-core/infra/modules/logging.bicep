// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create logging resources.
targetScope = 'resourceGroup'

// general params
param location string ='japaneast' 
param uniqueName string
param tags object

// Variables
var keyVaultlogName = replace(replace(toLower('kv001-${uniqueName}-spk'), '-', ''), '_', '')
var logAnalytics001Name = 'log001-${uniqueName}-spk'

// Resources
module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    keyvaultName: keyVaultlogName
  }
}

module logAnalytics001 'services/loganalytics.bicep' = {
  name: 'logAnalytics001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    logAnanalyticsName: logAnalytics001Name
  }
}

module logAnalytics001SecretDeployment 'auxiliary/logAnalyticsSecretDeployment.bicep' = {
  name: 'logAnalytics001SecretDeployment'
  scope: resourceGroup()
  params: {
    keyVaultId: keyVault001.outputs.keyvaultId
    logAnalyticsId: logAnalytics001.outputs.logAnalyticsWorkspaceId
  }
}

module AssignmentmetaDatabricks 'auxiliary/databricksRoleAssignmentKeyVault.bicep' ={
  name: 'AssignmentmetaDatabricks'
  params:{
    keyVaultId:keyVault001.outputs.keyvaultId
  }
}

// Outputs
output logAnalytics001WorkspaceKeyVaultId string = keyVault001.outputs.keyvaultId
output logAnalytics001WorkspaceKeyVaultDns string = keyVault001.outputs.KeyVaultDns
output logAnalytics001WorkspaceIdSecretName string = logAnalytics001SecretDeployment.outputs.logAnalyticsWorkspaceIdSecretName
output logAnalytics001WorkspaceKeySecretName string = logAnalytics001SecretDeployment.outputs.logAnalyticsWorkspaceKeySecretName
