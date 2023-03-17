param location string = resourceGroup().location

@description('Name of the chat application. Needs to be unique for Cosmos DB & App Service')
param chatAppName string

@description('Specifies App Service Sku (F1 = Free Tier)')
param appServicesSkuName string = 'F1'

@description('Specifies App Service capacity')
param appServicesSkuCapacity int = 1

@description('Enable Cosmos DB Free Tier')
param cosmosFreeTier bool = true

@description('Cosmos DB Container Throughput (<1000 for free tier)')
param cosmosContainerThroughput int = 400

var cosmosDBAccountName = '${chatAppName}-cosmos'
var hostingPlanName = '${chatAppName}-hostingplan'
var webSiteName = '${chatAppName}-webapp'
var webSiteRepository = 'https://github.com/AzureCosmosDB/cosmos-chat.git'
var databaseName = 'ChatDatabase'
var containerName = 'ChatContainer'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: cosmosDBAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    enableFreeTier: cosmosFreeTier
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-08-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  parent: cosmosDatabase
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/ChatSessionId'
        ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'Consistent'
        automatic: true
        includedPaths: [
          {
            path: '/ChatSessionId/?'
          }
          {
            path: '/Type/?'
          }
        ]
        excludedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
    options: {
      throughput: cosmosContainerThroughput
    }
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: appServicesSkuName
    capacity: appServicesSkuCapacity
  }
}

resource webSite 'Microsoft.Web/sites@2020-12-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'CosmosUri'
          value: cosmosAccount.properties.documentEndpoint
        }
        {
          name: 'CosmosKey'
          value: cosmosAccount.listKeys().primaryMasterKey
        }
        {
          name: 'CosmosDatabase'
          value: databaseName
        }
        {
          name: 'CosmosContainer'
          value: containerName
        }
      ]
    }
  }
}

resource source 'Microsoft.Web/sites/sourcecontrols@2020-12-01' = {
  parent: webSite
  name: 'web'
  properties: {
    repoUrl: webSiteRepository
    branch: 'main'
    isManualIntegration: true
  }
}
