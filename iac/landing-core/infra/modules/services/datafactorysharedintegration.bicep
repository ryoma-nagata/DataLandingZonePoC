// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Data Factory.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object

param datafactoryName string


param purviewId string = ''
// param purviewManagedStorageId string = ''
// param purviewManagedEventHubId string = ''
// param storageRawId string
// param storageEnrichedCuratedId string
// param databricks001Id string
// param databricks001WorkspaceUrl string
// param keyVault001Id string
// param sqlServer001Id string
// param sqlDatabase001Name string

// // Variables
// var storageRawName = length(split(storageRawId, '/')) >= 9 ? last(split(storageRawId, '/')) : 'incorrectSegmentLength'
// var storageEnrichedCuratedName = length(split(storageEnrichedCuratedId, '/')) >= 9 ? last(split(storageEnrichedCuratedId, '/')) : 'incorrectSegmentLength'
// var databricks001Name = length(split(databricks001Id, '/')) >= 9 ? last(split(databricks001Id, '/')) : 'incorrectSegmentLength'
// var keyVault001Name = length(split(keyVault001Id, '/')) >= 9 ? last(split(keyVault001Id, '/')) : 'incorrectSegmentLength'
// var sqlServer001Name = length(split(sqlServer001Id, '/')) >= 9 ? last(split(sqlServer001Id, '/')) : 'incorrectSegmentLength'
// var datafactoryDefaultManagedVnetIntegrationRuntimeName = 'AutoResolveIntegrationRuntime'
// var datafactoryPrivateEndpointNameDatafactory = '${datafactory.name}-datafactory-private-endpoint'
// var datafactoryPrivateEndpointNamePortal = '${datafactory.name}-portal-private-endpoint'

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



// resource datafactoryStorageRawLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
//   parent: datafactory
//   name: storageRawName

//   properties: {
//     type: 'AzureBlobFS'
//     annotations: []
//     connectVia: {
//       type: 'IntegrationRuntimeReference'
//       referenceName: 'AutoResolve'
//       parameters: {}
//     }
//     description: 'Storage Account for raw data'
//     parameters: {}
//     typeProperties: {
//       url: 'https://${storageRawName}.dfs.${environment().suffixes.storage}'
//     }
//   }
// }


// resource datafactoryStorageEnrichedCuratedLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
//   parent: datafactory
//   name: storageEnrichedCuratedName
//   dependsOn: [
//     datafactoryStorageEnrichedCuratedManagedPrivateEndpoint
//   ]
//   properties: {
//     type: 'AzureBlobFS'
//     annotations: []
//     connectVia: {
//       type: 'IntegrationRuntimeReference'
//       referenceName: datafactoryManagedIntegrationRuntime001.name
//       parameters: {}
//     }
//     description: 'Storage Account for raw data'
//     parameters: {}
//     typeProperties: {
//       url: 'https://${storageEnrichedCuratedName}.dfs.${environment().suffixes.storage}'
//     }
//   }
// }

// resource datafactoryDatabricksLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
//   parent: datafactory
//   name: replace(databricks001Name, '-', '')
//   properties: {
//     type: 'AzureDatabricks'
//     annotations: []
//     connectVia: {
//       type: 'IntegrationRuntimeReference'
//       referenceName: datafactoryManagedIntegrationRuntime001.name
//       parameters: {}
//     }
//     description: 'Azure Databricks Compute for Data Engineering'
//     parameters: {
//       DatabricksClusterType: {
//         type: 'String'
//         defaultValue: 'Standard_DS3_v2'
//       }
//       DatabricksAutoscale: {
//         type: 'String'
//         defaultValue: '1:15'
//       }
//       DatabrickClusterVersion: {
//         type: 'String'
//         defaultValue: '7.3.x-scala2.12'
//       }
//     }
//     typeProperties: {
//       authentication: 'MSI'
//       domain: 'https://${databricks001WorkspaceUrl}'
//       newClusterCustomTags: {
//         costCenter: 'ABCDE-12345'
//       }
//       newClusterDriverNodeType: '@linkedService().DatabricksClusterType'
//       newClusterNodeType: '@linkedService().DatabricksClusterType'
//       newClusterNumOfWorker: '@linkedService().DatabricksAutoscale'
//       newClusterSparkEnvVars: {
//         PYSPARK_PYTHON: '/databricks/python3/bin/python3'
//       }
//       newClusterVersion: '@linkedService().DatabrickClusterVersion'
//       // policyId: ''  // Uncomment to set the default cluster policy ID for jobs running on the Databricks workspace
//       workspaceResourceId: databricks001Id
//     }
//   }
// }

// Outputs
output datafactoryId string = datafactory.id
output datafactoryPrincipalId string = datafactory.identity.principalId
