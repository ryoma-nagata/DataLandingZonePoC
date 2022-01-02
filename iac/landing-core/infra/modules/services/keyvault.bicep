
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param keyvaultName string

// Variables


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
output KeyVaultDns string = 'https://${keyvaultName}${environment().suffixes.keyvaultDns}/'
