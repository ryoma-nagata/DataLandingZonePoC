// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Machine Learning workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object

param machineLearningName string
param applicationInsightsId string
param containerRegistryId string
param keyVaultId string
param storageAccountId string
param datalakeFileSystemIds string 
param synapseId string = ''
param synapseBigDataPoolId string = ''


param machineLearningComputeInstance001AdministratorObjectId string = ''

param enableRoleAssignments bool = false



// Resources
resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
  name: machineLearningName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowPublicAccessWhenBehindVnet: false
    description: machineLearningName

    friendlyName: machineLearningName
    hbiWorkspace: false
    imageBuildCompute: 'cpucluster001'
    primaryUserAssignedIdentity: ''
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    keyVault: keyVaultId
    storageAccount: storageAccountId
    publicNetworkAccess: 'Enabled'
  }
}


resource machineLearningSynapse001 'Microsoft.MachineLearningServices/workspaces/linkedServices@2020-09-01-preview' = if (enableRoleAssignments && !empty(synapseId)) {
  parent: machineLearning
  name: 'synapse001'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    linkedServiceResourceId: synapseId
    linkType: 'Synapse'
  }
}

resource machineLearningSynapse001BigDataPool001 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = if (enableRoleAssignments && !empty(synapseId) && !empty(synapseBigDataPoolId)) {
  parent: machineLearning
  name: 'bigdatapool001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    machineLearningSynapse001
  ]
  properties: {
    computeType: 'SynapseSpark'
    computeLocation: location
    description: 'Synapse workspace - Spark Pool'
    disableLocalAuth: true
    resourceId: synapseBigDataPoolId
  }
}

resource machineLearningCpuCluster001 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  parent: machineLearning
  name: 'cpucluster001'

  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    computeType: 'AmlCompute'
    computeLocation: location
    description: 'Machine Learning cluster 001'
    disableLocalAuth: true
    properties: {

      osType: 'Linux'

      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }

      vmPriority: 'LowPriority'
      vmSize: 'Standard_DS3_v2'
    }
  }
}

resource machineLearningComputeInstance001 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = if (!empty(machineLearningComputeInstance001AdministratorObjectId)) {
  parent: machineLearning
  name: 'computeinstance001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    computeType: 'ComputeInstance'
    computeLocation: location
    description: 'Machine Learning compute instance 001'
    disableLocalAuth: true
    properties: {
      applicationSharingPolicy: 'Personal'
      computeInstanceAuthorizationType: 'personal'
      setupScripts: {
        scripts: {
          creationScript: {}
          startupScript: {}
        }
      }

      vmSize: 'Standard_DS3_v2'
    }
  }
}

resource machineLearningDatastores 'Microsoft.MachineLearningServices/workspaces/datastores@2021-03-01-preview' = {
  parent: machineLearning
  name: split(datalakeFileSystemIds, '/')[8]
  properties: {
    tags: tags
    contents: {
      contentsType: 'AzureDataLakeGen2'
      accountName: split(datalakeFileSystemIds, '/')[8]
      containerName: last(split(datalakeFileSystemIds, '/'))
      credentials: {
        credentialsType: 'None'
        secrets: {
          secretsType: 'None'
        }
      }
      endpoint: environment().suffixes.storage
      protocol: 'https'
    }
    description: 'Data Lake Gen2 - ${split(datalakeFileSystemIds, '/')[8]}'
    isDefault: false
  }
}


// Outputs
output machineLearningId string = machineLearning.id
