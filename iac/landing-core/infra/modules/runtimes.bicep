// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create runtime resources.
targetScope = 'resourceGroup'

// general params
param location string ='japaneast' 
param uniqueName string
param tags object
// param subnetId string
// param administratorUsername string = 'VmssMainUser'
// @secure()
// param administratorPassword string
// param privateDnsZoneIdDataFactory string = ''
// param privateDnsZoneIdDataFactoryPortal string = ''
// param purviewId string = ''
// param purviewSelfHostedIntegrationRuntimeAuthKey string = ''
// param deploySelfHostedIntegrationRuntimes bool = false
// param datafactoryIds array

// Variables
var datafactoryRuntimes001Name = 'adf001-${uniqueName}-runtime'
var shir001Name = 'shir001-${uniqueName}'
// var shir002Name = '${prefix}-shir002'

// Resources
module datafactoryRuntimes001 'services/datafactoryruntime.bicep' = {
  name: 'datafactoryRuntimes001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    // subnetId: subnetId
    datafactoryName: datafactoryRuntimes001Name
    // privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    // privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    // purviewId: purviewId
  }
}

resource datafactoryRuntimes001IntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${datafactoryRuntimes001Name}/dataLandingZoneShir-${shir001Name}'
  dependsOn: [
    datafactoryRuntimes001
  ]
  properties: {
    type: 'SelfHosted'
    description: 'Data Landing Zone - Self Hosted Integration Runtime running on ${shir001Name}'
  }
}



// module shareDatafactoryRuntimes001IntegrationRuntime001 'auxiliary/shareSelfHostedIntegrationRuntime.bicep' = [ for (datafactoryId, i) in datafactoryIds: if (deploySelfHostedIntegrationRuntimes) {
//   name: 'shareDatafactoryRuntimes001IntegrationRuntime001-${i}'

//   scope: resourceGroup(split(datafactoryId, '/')[2], split(datafactoryId, '/')[4])
//   params: {
//     datafactorySourceId: datafactoryRuntimes001.outputs.datafactoryId
//     datafactorySourceShirId: datafactoryRuntimes001IntegrationRuntime001.id
//     datafactoryDestinationId: datafactoryId
//   }
// }]
// Outputs

