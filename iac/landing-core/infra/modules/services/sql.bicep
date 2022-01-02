param sqlserverName string
param sqldbName string 
param location string =resourceGroup().location
param sqlLogin string
@secure()
param sqlPassword string
param tags object

resource sqlserver 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlLogin
    administratorLoginPassword: sqlPassword
    publicNetworkAccess: 'Enabled'
  }
  tags:tags
}

resource network 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name:'AllowAllWindowsAzureIps'
  parent:sqlserver
  properties:{
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
    
resource ALLnetwork 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name:'AllowAll'
  parent:sqlserver
  properties:{
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}
resource sqldatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: sqldbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 50
  }
  parent: sqlserver
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  tags:tags
}


output sqlserverName string = sqlserverName
output sqlDatabaseName string = sqldbName
