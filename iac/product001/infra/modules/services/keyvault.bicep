// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a KeyVault.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
// param subnetId string
param keyvaultName string
// param privateDnsZoneIdKeyVault string = ''

// Variables
// var keyVaultPrivateEndpointName = '${keyVault.name}-private-endpoint'

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}


// Outputs
output keyvaultId string = keyVault.id
