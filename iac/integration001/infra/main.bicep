
targetScope = 'subscription'

// general params
param location string ='japaneast' 
param project string ='rydata'
@allowed([
  'demo'
])
param env string ='demo'
param deployment_id string 

// original params
param signed_in_user_object_id string 
param purviewId string =''
param storageRawFileSystemId_di001 string =''
param storageEnrichedCuratedFileSystemId_di001 string =''
param storageRawId string = '' 
param storageEnrichedCuratedId string = ''
param databricks001Id string = ''
param databricks001WorkspaceUrl string = ''


// variables
var uniqueName = '${project}-dl${deployment_id}-${env}'
var rg_dataIntegration001_name = 'rg-${uniqueName}-integration001'
var rg_dataIntegration002_name = 'rg-${uniqueName}-integration002'

var keyvault001Name = replace(replace(toLower('kv-${uniqueName}-di001'), '-', ''), '_', '')
var datafactory001Name = 'adf-${uniqueName}-di001'
var st001Name = replace(replace(toLower('st-${uniqueName}-di001'), '-', ''), '_', '')
var databricksName = 'adb-${uniqueName}-di001'

var tags_integration = {
  Environment : env
  Project : project
  Component : 'integration'
}

// resources 
// Data integration resources 001
resource dataIntegration001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_dataIntegration001_name
  location: location
  tags: tags_integration
  properties: {}
}

resource dataIntegration002ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_dataIntegration002_name
  location: location
  tags: tags_integration
  properties: {}
}

module databricks001 'modules/services/databricks.bicep' = {
  scope: dataIntegration001ResourceGroup
  name: 'databricks001'
  params: {
    databricksName: databricksName
    location: location
    tags: tags_integration
  }
}

module keyVault001 'modules/services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: dataIntegration001ResourceGroup
  params: {
    location: location
    tags: tags_integration
    keyvaultName: keyvault001Name
  }
}

module datafactory001 'modules/services/datafactory.bicep' = {
  name: 'datafactory001'
  scope: dataIntegration001ResourceGroup
  params: {
    location: location
    tags: tags_integration
    // subnetId: subnetId
    datafactoryName: datafactory001Name
    keyVault001Id: keyVault001.outputs.keyvaultId
    purviewId : purviewId
    databricks001Id:databricks001Id
    databricks001WorkspaceUrl:databricks001WorkspaceUrl
    storageEnrichedCuratedId:storageEnrichedCuratedId
    storageRawId:storageRawId
    storageEnrichedCuratedFileSystemId_di001:storageEnrichedCuratedFileSystemId_di001
    storageRawFileSystemId_di001:storageRawFileSystemId_di001
    storageIngestId:storage001.outputs.storageId
  }
}

module storage001 'modules/services/storage.bicep' = {
  name: 'storage001'
  scope: dataIntegration001ResourceGroup
  params: {
    location: location
    tags: tags_integration
    storageName: st001Name
    storageContainerNames: [
      'default'
    ]
    storageSkuName: 'Standard_LRS'
  }
}


module adfRoleAssignmentsIngestStorage 'modules/auxiliary/dataFactoryRoleAssignmentIngestStorage.bicep' ={
  name:'adfRoleAssignmentsIngestStorage'
  params:{
    datafactoryId:datafactory001.outputs.datafactoryId
    storageAccountId:storage001.outputs.storageId
  }
  scope:dataIntegration001ResourceGroup
}

module adfRoleAssignments 'modules/auxiliary/dataFactoryRoleAssignmentKeyVault.bicep' ={
  name:'adfRoleAssignments'
  params:{
    datafactoryId:datafactory001.outputs.datafactoryId
    keyVaultId:keyVault001.outputs.keyvaultId
  }
  scope:dataIntegration001ResourceGroup
}


module userRoleAssignmentsKeyAdmin 'modules/auxiliary/userResourceGroupRoleAssignment.bicep' ={
  name:'userRoleAssignmentsKeyAdmin'
  params:{
    userId:signed_in_user_object_id
    roleId:'00482a5a-887f-4fb3-b363-3b7fe8e74483' // key container admin
  }
  scope:dataIntegration001ResourceGroup
}

module userRoleAssignmentsblobreader 'modules/auxiliary/userResourceGroupRoleAssignment.bicep' ={
  name:'userRoleAssignmentsblobreader'
  params:{
    userId:signed_in_user_object_id
    roleId:'2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // blob Reader
  }
  scope:dataIntegration001ResourceGroup
}
