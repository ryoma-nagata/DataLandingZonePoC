
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
param synapseDefaultStorageAccountFileSystemId string =''
param storageCuratedFileSystemId string = ''
param storageEnrichedFileSystemId string = ''
param purviewId string = ''

// variables
var uniqueName = '${project}-dl${deployment_id}-${env}'
var rg_product_name = 'rg-${uniqueName}-product001'
var tags_product = {
  Environment : env
  Project : project
  Component : 'product'
}

var synapse_name = 'syn-${uniqueName}-dp001'

var synapseDefaultStorageAccountSubscriptionId = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseDefaultStorageAccountFileSystemId, '/')[2] : subscription().subscriptionId
var synapseDefaultStorageAccountResourceGroupName = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseDefaultStorageAccountFileSystemId, '/')[4] : split(synapseDefaultStorageAccountFileSystemId, '/')[4]

var storageCuratedAccountSubscriptionId = length(split(storageCuratedFileSystemId, '/')) >= 13 ? split(storageCuratedFileSystemId, '/')[2] : subscription().subscriptionId
var storageCuratedAccountResourceGroupName = length(split(storageCuratedFileSystemId, '/')) >= 13 ? split(storageCuratedFileSystemId, '/')[4] : split(storageCuratedFileSystemId, '/')[4]

var storageEnrichedAccountSubscriptionId = length(split(storageEnrichedFileSystemId, '/')) >= 13 ? split(storageEnrichedFileSystemId, '/')[2] : subscription().subscriptionId
var storageEnrichedAccountResourceGroupName = length(split(storageEnrichedFileSystemId, '/')) >= 13 ? split(storageEnrichedFileSystemId, '/')[4] : split(storageEnrichedFileSystemId, '/')[4]



var ml_name = 'aml-${uniqueName}-dp001'
var mlkv_name = replace(replace(toLower('mlkv-${uniqueName}-dp001'), '-', ''), '_', '')
var mlai_name = 'mlai-${uniqueName}-dp001'
var mlacr_name = 'mlacr-${uniqueName}-dp001'
var mlst_name = replace(replace(toLower('mlst-${uniqueName}-dp001'), '-', ''), '_', '')
var cog_name = 'cog-${uniqueName}-dp001'



@description('Specifies the cognitive service kind that will be deployed.')
param cognitiveServiceKinds string ='CognitiveServices'

// resources 
resource rg_product 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location:location
  name:rg_product_name
  tags:tags_product
}
// Resources
module keyVault001 'modules/services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product
    keyvaultName: mlkv_name
  }
}

module synapse001 'modules/services/synapse.bicep'= {
  name: 'synapse001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product
    synapseName: synapse_name
    synapseComputeSubnetId: ''
    synapseDefaultStorageAccountFileSystemId: synapseDefaultStorageAccountFileSystemId
  }
}
module synapse001RoleAssignmentStorage 'modules/auxiliary/synapseRoleAssignmentStorage.bicep' =  {
  name: 'synapse001RoleAssignmentStorage'
  scope: resourceGroup(synapseDefaultStorageAccountSubscriptionId, synapseDefaultStorageAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: synapseDefaultStorageAccountFileSystemId
    synapseId: synapse001.outputs.synapseId 
  }
}


module synapse001RoleAssignmentStorageCurated 'modules/auxiliary/synapseRoleAssignmentStorage.bicep' =  {
  name: 'synapse001RoleAssignmentStorageCurated'
  scope: resourceGroup(storageCuratedAccountSubscriptionId, storageCuratedAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: storageCuratedFileSystemId
    synapseId: synapse001.outputs.synapseId 
  }
}

module synapse001RoleAssignmentStorageEnrich 'modules/auxiliary/synapseRoleAssignmentStorage.bicep' =  {
  name: 'synapse001RoleAssignmentStorageEnrich'
  scope: resourceGroup(storageEnrichedAccountSubscriptionId, storageEnrichedAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: storageEnrichedFileSystemId
    synapseId: synapse001.outputs.synapseId 
    roleId:'2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' //blob Reader
  }
}

module cognitiveservices 'modules/services/cognitiveservices.bicep' = {
  name: cog_name
  scope: rg_product
  params: {
    location: location
    tags: tags_product

    cognitiveServiceName: cog_name
    cognitiveServiceKind: cognitiveServiceKinds
    cognitiveServiceSkuName: 'S0'
  }
}



module applicationInsights001 'modules/services/applicationinsights.bicep' = {
  name: 'applicationInsights001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product
    applicationInsightsName: mlai_name
    logAnalyticsWorkspaceId: ''
  }
}

module containerRegistry001 'modules/services/containerregistry.bicep' = {
  name: 'containerRegistry001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product
    containerRegistryName: mlacr_name
  }
}

module storage001 'modules/services/storage.bicep' = {
  name: 'storage001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product

    storageName: mlst_name
    storageContainerNames: [
      'default'
    ]
    storageSkuName: 'Standard_LRS'

  }
}

module machineLearning001 'modules/services/machinelearning.bicep' = {
  name: 'machineLearning001'
  scope: rg_product
  params: {
    location: location
    tags: tags_product
    enableRoleAssignments:true
    machineLearningName: ml_name
    applicationInsightsId: applicationInsights001.outputs.applicationInsightsId
    containerRegistryId: containerRegistry001.outputs.containerRegistryId
    keyVaultId: keyVault001.outputs.keyvaultId
    storageAccountId: storage001.outputs.storageId
    datalakeFileSystemIds: synapseDefaultStorageAccountFileSystemId
    synapseId: synapse001.outputs.synapseId
    synapseBigDataPoolId: synapse001.outputs.synapseBigDataPool001Id
  }
}
module machineLearningRoleAssignmentStorageEnrich 'modules/auxiliary/machineLearningRoleAssignmentStorage.bicep' = {
  name : 'machineLearningRoleAssignmentStorageEnrich'
  scope: resourceGroup(storageEnrichedAccountSubscriptionId, storageEnrichedAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: storageEnrichedFileSystemId
    machineLearningId:machineLearning001.outputs.machineLearningId
    roleId:'2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' //blob Reader
  }
}
module machineLearningRoleAssignmentStorageCurated 'modules/auxiliary/machineLearningRoleAssignmentStorage.bicep' = {
  name : 'machineLearningRoleAssignmentStorageCurated'
  scope: resourceGroup(storageCuratedAccountSubscriptionId, storageCuratedAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: storageCuratedFileSystemId
    machineLearningId:machineLearning001.outputs.machineLearningId
  }
}

