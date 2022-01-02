
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


// variables
var uniqueName = '${project}-dm${deployment_id}-${env}'
var rg_governance_name = 'rg-${uniqueName}-governance'
var tags_management = {
  Environment : env
  Project : project
  Component : 'management'
}

// resources 
resource rg_governance 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location:location
  name:rg_governance_name
  tags:tags_management
}

module governanceResources 'modules/governance.bicep' ={
  name:'governanceResources'
  scope:rg_governance
  params:{
    uniqueName:uniqueName
    location:location
    tags:tags_management
    signed_in_user_object_id:signed_in_user_object_id
  }
}


output purviewId string = governanceResources.outputs.purviewId
output purviewManagedStorageId string = governanceResources.outputs.purviewManagedStorageId
output purviewManagedEventHubId string = governanceResources.outputs.purviewManagedEventHubId
