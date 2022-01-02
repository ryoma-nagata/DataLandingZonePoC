targetScope = 'resourceGroup'
param keyVaultId string
param secretValue string
param secretName string

var keyVaultName = last(split(keyVaultId,'/'))

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name:keyVaultName
}

resource mysqlserver001PasswordSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: secretName
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: secretValue
  }
}
