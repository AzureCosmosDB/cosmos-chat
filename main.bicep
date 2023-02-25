targetScope = 'resourceGroup'


param location string = resourceGroup().location

@description('Specifies the name of the chat application.')
param chatAppName string

var cosmosDBAccountName = '${chatAppName}-cosmos'
var hostingPlanName = '${chatAppName}-hostingplan'
var webSiteName = '${chatAppName}-webapp'
var websiteSourceRepository = 'https://github.com/AzureCosmosDB/cosmos-chat.git'

@description('Specifies app plan SKU')
param skuName string = 'F1'

@description('Specifies app plan capacity')
param skuCapacity int = 1


resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: cosmosDBAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
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
  name: 'ChatDatabase'
  parent: cosmosDBAccount
  properties: {
    resource: {
      id: 'ChatDatabase'
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: 'ChatContainer'
  parent: database
  properties: {
    resource: {
      id: 'ChatContainer'
      partitionKey: {
        paths: [
          '/chatSessionId'
        ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'Consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}


resource hostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: hostingPlanName
  dependsOn: [
    cosmosDBAccount
  ]
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
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
          value: 'ChatDatabase'
        }
        {
          name: 'CosmosCollection'
          value: 'ChatContainer'
        }
      ]

    }
  }
}

resource webSiteSourceControl 'Microsoft.Web/sites/sourcecontrols@2020-12-01' = {
  name: '${webSite.name}/web'
  properties: {
    repoUrl: websiteSourceRepository
    branch: 'main'
    isManualIntegration: true
  }
}


