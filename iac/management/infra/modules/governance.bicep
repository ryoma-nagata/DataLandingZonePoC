targetScope = 'resourceGroup'

// general params
param location string ='japaneast' 
param uniqueName string
param tags object

// original params
param perviewlocation string = 'southeastasia'
param signed_in_user_object_id string

// variables
var purview_name = 'apv-${uniqueName}-gov'
var akv_name = replace(replace(toLower('kv-${uniqueName}-gov'), '-', ''), '_', '')

// resources 

module purview001 'services/purview.bicep' ={
  name:'purview001'
  params:{
    location:perviewlocation
    purviewName:purview_name
    tags:tags
  }
  scope:resourceGroup()
}

module kv001 'services/keyvault.bicep' = {
  name: 'kv001'
  params:{
    keyvaultName:akv_name
    location:location
    tags:tags
  }
  scope:resourceGroup()
}

module purviewKeyVaultRoleAssignment 'auxiliary/purviewRoleAssignmentKeyVault.bicep' = {
  name: 'purviewKeyVaultRoleAssignment'
  scope: resourceGroup()
  params: {
    purviewId: purview001.outputs.purviewId
    keyVaultId: kv001.outputs.keyvaultId
  }
}

module userRoleAssignments 'auxiliary/userRoleAssignmentResourceGroup.bicep' ={
  name:'userRoleAssignments'
  params:{
    userId:signed_in_user_object_id
  }
  scope:resourceGroup()
}


// Outputs
output purviewId string = purview001.outputs.purviewId
output purviewManagedStorageId string = purview001.outputs.purviewManagedStorageId
output purviewManagedEventHubId string = purview001.outputs.purviewManagedEventHubId
