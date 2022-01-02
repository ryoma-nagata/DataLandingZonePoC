// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Container Registry.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param containerRegistryName string

// Variables
var containerRegistryNameCleaned = replace(containerRegistryName, '-', '')

// Resources
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: containerRegistryNameCleaned
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
  }

}


// Outputs
output containerRegistryId string = containerRegistry.id
