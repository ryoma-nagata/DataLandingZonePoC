// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Synapse workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object

param synapseName string
param administratorUsername string = 'SqlServerMainUser'
@secure()
param administratorPassword string = ''
param synapseDefaultStorageAccountFileSystemId string
param synapseComputeSubnetId string = ''
@allowed([
  'true'
  'false'
])
param AllowAll string = 'true'
param purviewId string = ''
param enableSqlPool bool = false

// Variables
var synapseDefaultStorageAccountFileSystemName = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? last(split(synapseDefaultStorageAccountFileSystemId, '/')) : 'incorrectSegmentLength'
var synapseDefaultStorageAccountName = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseDefaultStorageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'

// Resources
resource synapse 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: synapseName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${synapseDefaultStorageAccountName}.dfs.${environment().suffixes.storage}'
      filesystem: synapseDefaultStorageAccountFileSystemName
    }
    managedResourceGroupName: 'mngrg-${synapseName}'
    // managedVirtualNetwork: 'default'
    // managedVirtualNetworkSettings: {
    //   allowedAadTenantIdsForLinking: []
    //   linkedAccessCheckOnTargetResource: true
    //   preventDataExfiltration: true
    // }
    publicNetworkAccess: 'Enabled'
    purviewConfiguration: {
      purviewResourceId: purviewId
    }
    sqlAdministratorLogin: administratorUsername
    sqlAdministratorLoginPassword: administratorPassword
    // virtualNetworkProfile: {
    //   computeSubnetId: synapseComputeSubnetId
    // }
  }
}
resource synapseWorkspace_allowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = if (AllowAll == 'true') {
  parent: synapse
  name: 'allowAll'

  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}
resource synapseSqlPool001 'Microsoft.Synapse/workspaces/sqlPools@2021-03-01' = if(enableSqlPool) {
  parent: synapse
  name: 'sqlPool001'
  location: location
  tags: tags
  sku: {
    name: 'DW100c'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    storageAccountType: 'GRS'
  }
}

resource synapseBigDataPool001 'Microsoft.Synapse/workspaces/bigDataPools@2021-03-01' = {
  parent: synapse
  name: 'bigDataPool001'
  location: location
  tags: tags
  properties: {
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    // cacheSize: 100  // Uncomment to set a specific cache size
    customLibraries: []
    defaultSparkLogFolder: 'logs/'
    dynamicExecutorAllocation: {
      enabled: true
      minExecutors: 1
      maxExecutors: 9
    }
    // isComputeIsolationEnabled: true  // Uncomment to enable compute isolation (only available in selective regions)
    // libraryRequirements: {  // Uncomment to install pip dependencies on the Spark cluster
    //   content: ''
    //   filename: 'requirements.txt'
    // }
    nodeSize: 'Small'
    nodeSizeFamily: 'MemoryOptimized'
    sessionLevelPackagesEnabled: true
    // sparkConfigProperties: {  // Uncomment to set spark conf on the Spark cluster
    //   content: ''
    //   filename: 'spark.conf'
    // }
    sparkEventsFolder: 'events/'
    sparkVersion: '3.1'
  }
}

resource synapseManagedIdentitySqlControlSettings 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-03-01' = {
  parent: synapse
  name: 'default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: 'Enabled'
    }
  }
}

// Outputs
output synapseId string = synapse.id
output synapseBigDataPool001Id string = synapseBigDataPool001.id
