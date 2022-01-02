
targetScope = 'resourceGroup'

// Parameters
param location string 
param tags object
param purviewName string

// Variables


// Resources
resource purview 'Microsoft.Purview/accounts@2021-07-01' = {
  name: purviewName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess:'Enabled'
    managedResourceGroupName:'mngrg-${purviewName}'
  }
  tags: tags
  dependsOn: []
}

// Outputs
output purviewId string = purview.id
output purviewManagedStorageId string = purview.properties.managedResources.storageAccount
output purviewManagedEventHubId string = purview.properties.managedResources.eventHubNamespace
