targetScope = 'resourceGroup'


param location string = resourceGroup().location

@description('Specifies the name of the chat application.')
param chatAppName string

var cosmosDBAccountName = '${chatAppName}-cosmos'
var hostingPlanName = '${chatAppName}-hostingplan'
var webSiteName = '${chatAppName}-webapp'
var webSourceName = '${chatAppName}-source'
var webSiteRepository = 'https://github.com/AzureCosmosDB/cosmos-chat.git'

var databaseName = 'ChatDatabase'
var containerName = 'ChatContainer'

@description('Specifies app plan SKU (F1 = Free Tier')
param appServicesSkuName string = 'F1'

@description('Specifies app plan capacity')
param appServicesSkuCapacity int = 1

@description('Enable Cosmos DB Free Tier')
param cosmosFreeTier bool = true

@description('Cosmos DB Container Throughput (<1000 for free tier')
param cosmosThroughput int = 400

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
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

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-08-15' = {
  name: databaseName
  parent: cosmosDBAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: containerName
  parent: database
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
    options:{
      throughput: cosmosThroughput
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
      appSettings:[
        {
          name: 'CosmosUri'
          value: cosmosDBAccount.properties.documentEndpoint
        }
        {
          name: 'CosmosKey'
          value: listKeys(cosmosDBAccount.id, '2022-08-15').primaryMasterKey
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

resource webSiteSource 'Microsoft.Web/sites/sourcecontrols@2020-12-01' = {
  name: webSourceName
  dependsOn: [
	webSite
  ]
  properties: {
    repoUrl: webSiteRepository
    branch: 'main'
    isManualIntegration: true
  }
}


