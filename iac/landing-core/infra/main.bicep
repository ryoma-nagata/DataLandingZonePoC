
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
// param deploySelfHostedIntegrationRuntimes bool = true
param purviewId string =''
param sqlLogin string = 'sqladmin'
@secure()
param sqlPassword string


// variables
var uniqueName = '${project}-dl${deployment_id}-${env}'
var rg_datalake_name = 'rg-${uniqueName}-datalake'
var rg_logging_name = 'rg-${uniqueName}-logging'
var rg_shared_integration_name = 'rg-${uniqueName}-shared-integration'
var rg_runtimes_name = 'rg-${uniqueName}-runtimes'
var rg_shared_prodct_name = 'rg-${uniqueName}-shared-product'
var rg_metadata_name = 'rg-${uniqueName}-metadata'

var tags_core = {
  Environment : env
  Project : project
  Component : 'landing-core'
}

// resources 
// Datalake resources
resource rg_datalake 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location:location
  name:rg_datalake_name
  tags:tags_core
}

module storageServices 'modules/datalake.bicep' ={
  name:'storageServices'
  scope:rg_datalake
  params:{
    uniqueName:uniqueName
    location:location
    tags:tags_core
    signed_in_user_object_id:signed_in_user_object_id
  }
}

// Logging resources
resource loggingResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_logging_name
  location: location
  tags: tags_core
  properties: {}
}

module loggingServices 'modules/logging.bicep' = {
  name: 'loggingServices'
  scope: loggingResourceGroup
  params: {
    location: location
    uniqueName:uniqueName
    tags: tags_core
  }
}


// Shared integration services
resource sharedIntegrationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_shared_integration_name
  location: location
  tags: tags_core
  properties: {}
}


module sharedIntegrationServices 'modules/sharedintegration.bicep' = {
  name: 'sharedIntegrationServices'
  scope: sharedIntegrationResourceGroup
  params: {
    location: location
    tags: tags_core
    uniqueName:uniqueName
    storageAccountRawFileSystemId: storageServices.outputs.storageRawFileSystemId
    storageAccountEnrichedCuratedFileSystemId: storageServices.outputs.storageEnrichedCuratedFileSystemId
    purviewId: purviewId
  }
}

// Runtime resources
resource runtimesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_runtimes_name
  location: location
  tags: tags_core
  properties: {}
}

module runtimeServices 'modules/runtimes.bicep' = {
  name: 'runtimeServices'
  scope: runtimesResourceGroup
  params: {
    location: location
    uniqueName: uniqueName
    tags: tags_core
    // subnetId: networkServices.outputs.servicesSubnetId
    // administratorUsername: administratorUsername
    // administratorPassword: administratorPassword
    // privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    // privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    // purviewId: purviewId
    // purviewSelfHostedIntegrationRuntimeAuthKey: purviewSelfHostedIntegrationRuntimeAuthKey
    // deploySelfHostedIntegrationRuntimes: deploySelfHostedIntegrationRuntimes
    // datafactoryIds: [
    //   sharedIntegrationServices.outputs.datafactoryIntegration001Id
    // ]
  }
}

// Shared product resources
resource sharedProductResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rg_shared_prodct_name
  location: location
  tags: tags_core
  properties: {}
}

module sharedProductServices 'modules/sharedproduct.bicep' = {
  name: 'sharedProductServices'
  scope: sharedProductResourceGroup
  params: {
    location: location
    uniqueName: uniqueName
    tags: tags_core
    administratorPassword:''
    // subnetId: networkServices.outputs.servicesSubnetId
    // vnetId: networkServices.outputs.vnetId
    // databricksProduct001PrivateSubnetName: networkServices.outputs.databricksProductPrivateSubnetName
    // databricksProduct001PublicSubnetName: networkServices.outputs.databricksProductPublicSubnetName
    // administratorUsername: administratorUsername
    // administratorPassword: administratorPassword
    synapseProduct001DefaultStorageAccountFileSystemId: storageServices.outputs.storageWorkspaceFileSystemId
    // synapseSqlAdminGroupName: ''
    // synapseSqlAdminGroupObjectID: ''
    // synapseProduct001ComputeSubnetId: ''
    // purviewId: purviewId
    // privateDnsZoneIdSynapseDev: privateDnsZoneIdSynapseDev
    // privateDnsZoneIdSynapseSql: privateDnsZoneIdSynapseSql
  }
}

// Role assignment
module purviewSubscriptionRoleAssignmentReader 'modules/auxiliary/purviewRoleAssignmentSubscription.bicep' = if(!empty(purviewId)) {
  name: 'purviewSubscriptionRoleAssignmentReader'
  scope: subscription()
  params: {
    purviewId: purviewId
    role: 'Reader'
  }
}

module purviewSubscriptionRoleAssignmentStorageBlobReader 'modules/auxiliary/purviewRoleAssignmentSubscription.bicep' = if(!empty(purviewId)) {
  name: 'purviewSubscriptionRoleAssignmentStorageBlobReader'
  scope: subscription()
  params: {
    purviewId: purviewId
    role: 'StorageBlobDataReader'
  }
}

resource metadataResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01'={
  name : rg_metadata_name
  location:location
  tags: tags_core
}

module metadataServices 'modules/metadata.bicep' ={
  scope: metadataResourceGroup
  name: 'metadataServices'
  params: {
    sqlLogin: sqlLogin
    sqlPassword: sqlPassword
    tags: tags_core
    uniqueName: uniqueName
  }
}



// Outputs

output coreSubscriptionId string = subscription().subscriptionId

// storage
output storageRawId string = storageServices.outputs.storageRawId
output storageRawFileSystemId string = storageServices.outputs.storageRawFileSystemId
output storageRawFileSystemId_di001 string = storageServices.outputs.storageRawFileSystemId_di001

output storageEnrichedCuratedId string = storageServices.outputs.storageEnrichedCuratedId
output storageEnrichedCuratedFileSystemId string = storageServices.outputs.storageEnrichedCuratedFileSystemId
output storageEnrichedCuratedFileSystemId_di001 string = storageServices.outputs.storageEnrichedCuratedFileSystemId_di001
output storageEnrichedCuratedFileSystemId_dp001 string = storageServices.outputs.storageEnrichedCuratedFileSystemId_dp001

output storageWorkspaceId string = storageServices.outputs.storageWorkspaceId
output storageWorkspaceFileSystemId string = storageServices.outputs.storageWorkspaceFileSystemId
output storageWorkspaceFileSystemId_dp001 string = storageServices.outputs.storageWorkspaceFileSystemId_dp001

// shared Integrations
output datafactoryPrincipalId string = sharedIntegrationServices.outputs.datafactoryPrincipalId

output databricksIntegration001Id string = sharedIntegrationServices.outputs.databricksIntegration001Id
output databricksIntegration001ApiUrl string = sharedIntegrationServices.outputs.databricksIntegration001ApiUrl
output databricksIntegration001WorkspaceUrl string = sharedIntegrationServices.outputs.databricksIntegration001WorkspaceUrl
output databricksIntegration001Name string = last(split(sharedIntegrationServices.outputs.databricksIntegration001Id, '/')) 

output sharedIntegrationResourceGroupName string = rg_shared_integration_name

// metadata
output hiveKeyVaultResourceId string = metadataServices.outputs.hiveKeyVaultResourceId
output hiveKeyVaultDnsName string = metadataServices.outputs.hiveKeyVaultDnsName
output metastoreSqlServerName string = metadataServices.outputs.metastoreSqlServerName
output metastoreSqlDatabaseName string = metadataServices.outputs.metastoreSqlDatabaseName
output metastoreResourceGroupName string = rg_metadata_name

// logging
output logAnalytics001WorkspaceKeyVaultId string  = loggingServices.outputs.logAnalytics001WorkspaceKeyVaultId
output logAnalytics001WorkspaceKeyVaultDns string = loggingServices.outputs.logAnalytics001WorkspaceKeyVaultDns

// shared Product
output databricksProduct001Id string = sharedProductServices.outputs.databricksProduct001Id
output databricksProduct001ApiUrl string = sharedProductServices.outputs.databricksProduct001ApiUrl
output databricksProduct001WorkspaceUrl string = sharedProductServices.outputs.databricksProduct001WorkspaceUrl
output databrikcsProduct001Name string = last(split(sharedProductServices.outputs.databricksProduct001Id, '/')) 

output sharedProductResourceGroupName string = rg_shared_prodct_name


