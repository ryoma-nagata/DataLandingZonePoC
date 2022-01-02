// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Data Factory.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object

param datafactoryName string

param keyVault001Id string
param purviewId string = ''
param storageRawId string = '' 
param storageEnrichedCuratedId string = ''
param databricks001Id string
param databricks001WorkspaceUrl string

param storageRawFileSystemId_di001 string =''
param storageEnrichedCuratedFileSystemId_di001 string =''
param storageIngestId string = ''

var storageRawName = length(split(storageRawId, '/')) >= 9 ? last(split(storageRawId, '/')) : 'incorrectSegmentLength'
var storageEnrichedCuratedName = length(split(storageEnrichedCuratedId, '/')) >= 9 ? last(split(storageEnrichedCuratedId, '/')) : 'incorrectSegmentLength'
var databricks001Name = length(split(databricks001Id, '/')) >= 9 ? last(split(databricks001Id, '/')) : 'incorrectSegmentLength'

var storageRawAccountSubscriptionId = length(split(storageRawId, '/')) >= 9 ? split(storageRawId, '/')[2] : 'incorrectSegmentLength'
var storageRawResourceGroupName = length(split(storageRawId, '/')) >= 9 ? split(storageRawId, '/')[4] : 'incorrectSegmentLength'

var storageEnrichedAccountSubscriptionId = length(split(storageEnrichedCuratedId, '/')) >= 9 ? split(storageEnrichedCuratedId, '/')[2] : 'incorrectSegmentLength'
var storageEnrichedResourceGroupName = length(split(storageEnrichedCuratedId, '/')) >= 9 ? split(storageEnrichedCuratedId, '/')[4] : 'incorrectSegmentLength'

var databricksSubscriptionId = length(split(databricks001Id, '/')) >= 9 ? split(databricks001Id, '/')[2] : 'incorrectSegmentLength'
var databricksResourceGroupName = length(split(databricks001Id, '/')) >= 9 ? split(databricks001Id, '/')[4] : 'incorrectSegmentLength'

var storageIngestName =length(split(storageIngestId, '/')) >= 9 ? last(split(storageIngestId, '/')) : 'incorrectSegmentLength'


// Variables
var keyVault001Name = length(split(keyVault001Id, '/')) >= 9 ? last(split(keyVault001Id, '/')) : 'incorrectSegmentLength'


// Resources
resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: datafactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    globalParameters: {}
    publicNetworkAccess: 'Enabled'
    purviewConfiguration: {
      purviewResourceId: purviewId
    }
  }
}

resource keyVault001LinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: replace(keyVault001Name, '-', '')
  properties: {
    type: 'AzureKeyVault'
    annotations: []
    description: 'Key Vault for storing secrets'
    parameters: {}
    typeProperties: {
      baseUrl: 'https://${keyVault001Name}${environment().suffixes.keyvaultDns}/'
    }
  }
}

resource datafactoryStorageIngestLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: storageIngestName

  properties: {
    type: 'AzureBlobStorage'
    annotations: []
    description: 'Storage Account for landing data'
    parameters: {}
    typeProperties: {
      serviceEndpoint:'https://${storageIngestName}.blob.${environment().suffixes.storage}'
      accountKind:'StorageV2'
      url: 'https://${storageIngestName}.blob.${environment().suffixes.storage}'
    }
  }
}

resource datafactoryStorageRawLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: storageRawName

  properties: {
    type: 'AzureBlobFS'
    annotations: []
    description: 'Storage Account for raw data'
    parameters: {}
    typeProperties: {
      
      url: 'https://${storageRawName}.dfs.${environment().suffixes.storage}'
    }
  }
}


resource datafactoryStorageEnrichedCuratedLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: storageEnrichedCuratedName
  properties: {
    type: 'AzureBlobFS'
    annotations: []
    description: 'Storage Account for raw data'
    parameters: {}
    typeProperties: {
      url: 'https://${storageEnrichedCuratedName}.dfs.${environment().suffixes.storage}'
    }
  }
}

resource datafactoryDatabricksLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: replace(databricks001Name, '-', '')
  properties: {
    type: 'AzureDatabricks'
    annotations: []
    description: 'Azure Databricks Compute for Data Engineering'
    parameters: {
      DatabricksClusterType: {
        type: 'String'
        defaultValue: 'Standard_DS3_v2'
      }
      DatabricksAutoscale: {
        type: 'String'
        defaultValue: '1:15'
      }
      DatabrickClusterVersion: {
        type: 'String'
        defaultValue: '7.3.x-scala2.12'
      }
    }
    typeProperties: {
      authentication: 'MSI'
      domain: 'https://${databricks001WorkspaceUrl}'
      newClusterCustomTags: {
        costCenter: 'ABCDE-12345'
      }
      newClusterDriverNodeType: '@linkedService().DatabricksClusterType'
      newClusterNodeType: '@linkedService().DatabricksClusterType'
      newClusterNumOfWorker: '@linkedService().DatabricksAutoscale'
      newClusterSparkEnvVars: {
        PYSPARK_PYTHON: '/databricks/python3/bin/python3'
      }
      newClusterVersion: '@linkedService().DatabrickClusterVersion'
      // policyId: ''  // Uncomment to set the default cluster policy ID for jobs running on the Databricks workspace
      workspaceResourceId: databricks001Id
    }
  }
}

module adfRoleAssignmentsEnFilesystem '../auxiliary/dataFactoryRoleAssignmentStorage.bicep' ={
  name:'adfRoleAssignmentsEnFilesystem'
  params:{
    datafactoryId:datafactory.id
    storageAccountFileSystemId:storageEnrichedCuratedFileSystemId_di001
  }
  scope: resourceGroup(storageEnrichedAccountSubscriptionId, storageEnrichedResourceGroupName)
}

module adfRoleAssignmentsRowFilesystem '../auxiliary/dataFactoryRoleAssignmentStorage.bicep' ={
  name:'adfRoleAssignmentsRowFilesystem'
  params:{
    datafactoryId:datafactory.id
    storageAccountFileSystemId:storageRawFileSystemId_di001
  }
  scope: resourceGroup(storageRawAccountSubscriptionId, storageRawResourceGroupName)
}

module adbAdfRoleAssignments '../auxiliary/databricksRoleAssignment.bicep' ={
  name:'adbAdfRoleAssignments'
  params:{
    datafactoryId:datafactory.id
    databricksId:databricks001Id
  }
  scope: resourceGroup(databricksSubscriptionId, databricksResourceGroupName)
}
// Outputs
output datafactoryId string = datafactory.id
