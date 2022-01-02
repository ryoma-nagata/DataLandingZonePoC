// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Cognitive Service.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param cognitiveServiceName string
param cognitiveServiceSkuName string = 'S0'
@allowed([
  'AnomalyDetector'
  'ComputerVision'
  'CognitiveServices'
  'ContentModerator'
  'CustomVision.Training'
  'CustomVision.Prediction'
  'Face'
  'FormRecognizer'
  'ImmersiveReader'
  'LUIS'
  'Personalizer'
  'SpeechServices'
  'TextAnalytics'
  'TextTranslation'
])
param cognitiveServiceKind string


// Variables

// Resources
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2021-04-30' = {
  name: cognitiveServiceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: cognitiveServiceKind == 'ComputerVision' || cognitiveServiceKind == 'TextTranslation' ? 'S1' : cognitiveServiceKind == 'TextAnalytics' ? 'S' : cognitiveServiceSkuName
  }
  kind: cognitiveServiceKind
  properties: {
    // userOwnedStorage: []  // Uncomment if you want to enable user owned storage. Only available for select set of cognitive service kinds.
  }
}


// Outputs
