targetScope = 'resourceGroup'

// general params
param location string ='japaneast' 
param uniqueName string
param tags object

// original params
param purviewId string = ''
param signed_in_user_object_id string 


// Variables
var storageRawName = replace(replace(toLower('dls-${uniqueName}-raw'), '-', ''), '_', '')
var storageEnrichedCuratedName = replace(replace(toLower('dls-${uniqueName}-encur'), '-', ''), '_', '')
var storageWorkspaceName = replace(replace(toLower('dls-${uniqueName}-work'), '-', ''), '_', '')
var rawFileSytemNames = [
  'data'
  'di001'
]
var dataProductFileSystemNames = [
  'data'
  'dp001'
]
var enrichedCuratedFileSytemNames = [
  'data'
  'di001'
  'dp001'
]

// Resources
module storageRaw 'services/storage.bicep' = {
  name: 'storageRaw'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    storageName: storageRawName
    fileSystemNames: rawFileSytemNames
    purviewId: purviewId
  }
}

module storageEnrichedCurated 'services/storage.bicep' = {
  name: 'storageEnrichedCurated'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    storageName: storageEnrichedCuratedName
    fileSystemNames: enrichedCuratedFileSytemNames
    purviewId: purviewId
  }
}

module storageWorkspace 'services/storage.bicep' = {
  name: 'storageWorkspace'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    storageName: storageWorkspaceName
    fileSystemNames: dataProductFileSystemNames
    purviewId: purviewId
  }
}


module userRoleAssignments 'auxiliary/userResourceGroupRoleAssignment.bicep' ={
  name:'userRoleAssignments'
  params:{
    roleId:'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // blob data owner
    userId:signed_in_user_object_id
  }
  scope:resourceGroup()
}


// Outputs
output storageRawId string = storageRaw.outputs.storageId
output storageRawFileSystemId string = storageRaw.outputs.storageFileSystemIds[0].storageFileSystemId
output storageRawFileSystemId_di001 string = storageRaw.outputs.storageFileSystemIds[1].storageFileSystemId

output storageEnrichedCuratedId string = storageEnrichedCurated.outputs.storageId
output storageEnrichedCuratedFileSystemId string = storageEnrichedCurated.outputs.storageFileSystemIds[0].storageFileSystemId
output storageEnrichedCuratedFileSystemId_di001 string = storageEnrichedCurated.outputs.storageFileSystemIds[1].storageFileSystemId
output storageEnrichedCuratedFileSystemId_dp001 string = storageEnrichedCurated.outputs.storageFileSystemIds[2].storageFileSystemId

output storageWorkspaceId string = storageWorkspace.outputs.storageId
output storageWorkspaceFileSystemId string = storageWorkspace.outputs.storageFileSystemIds[0].storageFileSystemId
output storageWorkspaceFileSystemId_dp001 string = storageWorkspace.outputs.storageFileSystemIds[1].storageFileSystemId
