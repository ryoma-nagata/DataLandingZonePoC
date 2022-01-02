targetScope = 'resourceGroup'

// general params
param location string ='japaneast' 
param uniqueName string
param tags object
param sqlLogin string
@secure()
param sqlPassword string

var metakeyVaultName = replace(replace(toLower('kv001-${uniqueName}-meta'), '-', ''), '_', '')
var sqlServerName = 'sql-${uniqueName}-meta'
var sqlDatabaseName = 'metastore'

var SqlServerUsernameSecretName = 'hiveMetastoreConnectionUserName'
var SqlServerPasswordSecretName = 'hiveMetastoreConnectionPassword'
var sqlConnectionStringSecretName = 'hiveMetastoreConnectionURL'

module metastoreSql 'services/sql.bicep' = {
  name: 'metastoreSql'
  params: {
    sqldbName: sqlDatabaseName
    sqlLogin: sqlLogin
    sqlPassword: sqlPassword
    sqlserverName: sqlServerName
    location:location
    tags: tags
  }
}

module metakeyVault 'services/keyvault.bicep' = {
  name: 'metakeyVault'
  params: {
    keyvaultName: metakeyVaultName
    location: location
    tags: tags
  }
}

module sqlserver001UsernameSecretDeployment 'services/keyvaultSecret.bicep' ={
  name:'sqlserver001UsernameSecretDeployment'
  params:{
    secretValue: '${sqlLogin}@${sqlServerName}'
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: SqlServerUsernameSecretName
  }
}

module sqlserverPasswordSecretDeployment 'services/keyvaultSecret.bicep' ={
  name:'sqlserverPasswordSecretDeployment'
  params:{
    secretValue: sqlPassword
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: SqlServerPasswordSecretName
  }
}

module sqlserverConnectionStringSecretDeployment 'services/keyvaultSecret.bicep' ={
  name:'sqlserverConnectionStringSecretDeployment'
  params:{
    secretValue: 'jdbc:sqlserver://${metastoreSql.outputs.sqlserverName}.database.windows.net:1433;database=${metastoreSql.outputs.sqlDatabaseName};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: sqlConnectionStringSecretName
  }
}

module AssignmentmetaDatabricks 'auxiliary/databricksRoleAssignmentKeyVault.bicep' ={
  name: 'AssignmentmetaDatabricks'
  params:{
    keyVaultId:metakeyVault.outputs.keyvaultId
  }
}

output hiveKeyVaultResourceId string = metakeyVault.outputs.keyvaultId
output hiveKeyVaultDnsName string = metakeyVault.outputs.KeyVaultDns
output metastoreSqlServerName string = metastoreSql.outputs.sqlserverName
output metastoreSqlDatabaseName string = metastoreSql.outputs.sqlDatabaseName
