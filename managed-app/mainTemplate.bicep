// managed-app/mainTemplate.bicep — Azure Marketplace Managed Application template
//
// Deploys campfire cf-mcp into the CUSTOMER's subscription when they purchase
// from Azure Marketplace. The operator (3DL) retains management access via
// the managed resource group.
//
// What gets deployed:
//   - Azure Storage Account (Table Storage for campfire data + Functions runtime)
//   - Log Analytics workspace + Application Insights (optional)
//   - Azure Functions App (Consumption plan, custom handler runtime)
//
// This template is intentionally CUSTOMER-PARAMETERIZED:
//   - No hardcoded subscription IDs, resource groups, or domains
//   - No Key Vault references (customer provides their own session token as a parameter)
//   - All naming uses a customer-supplied prefix + unique suffix
//
// Package: zip mainTemplate.json createUiDefinition.json → app.zip for Partner Center
//
// Reference: campfire-hosting/infra/functions/ for the resource pattern.
// Differences from hosting template:
//   1. No custom domain binding (customer manages their own DNS)
//   2. CF_SESSION_TOKEN passed as a secure parameter (not Key Vault reference)
//   3. App Insights is optional (controlled by enableMonitoring parameter)
//   4. All resources tagged managedBy=campfire per marketplace convention

targetScope = 'resourceGroup'

// ─── Parameters ──────────────────────────────────────────────────────────────

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Naming prefix for all resources (2-8 lowercase alphanumeric characters).')
@minLength(2)
@maxLength(8)
param namePrefix string = 'cf'

@description('Campfire session token for cf-mcp authentication. Treated as a secure string.')
@secure()
param cfSessionToken string

@description('Campfire domain — the public hostname customers use to reach cf-mcp.')
param cfDomain string = ''

@description('Whether to deploy Application Insights and Log Analytics for monitoring.')
param enableMonitoring bool = true

@description('Storage account SKU. Standard_LRS is lowest cost; use Standard_ZRS for higher durability.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])
param storageSku string = 'Standard_LRS'

// ─── Variables ───────────────────────────────────────────────────────────────

// Unique suffix derived from resource group ID — avoids global naming collisions across customers.
var uniqueSuffix = take(uniqueString(resourceGroup().id), 6)

var storageAccountName = '${toLower(namePrefix)}st${uniqueSuffix}'   // max 24 chars, lowercase, no hyphens
var hostingPlanName    = '${namePrefix}-plan-${uniqueSuffix}'
var functionAppName    = '${namePrefix}-func-${uniqueSuffix}'
var appInsightsName    = '${namePrefix}-appi-${uniqueSuffix}'
var logAnalyticsName   = '${namePrefix}-log-${uniqueSuffix}'

// Effective domain: use provided value or fall back to the default Functions hostname
var effectiveDomain = empty(cfDomain) ? '${functionAppName}.azurewebsites.net' : cfDomain

var tags = {
  managedBy: 'campfire'                  // required by marketplace convention (see CLAUDE.md)
  project: 'campfire-mcp'
  namePrefix: namePrefix
}

// ─── Storage Account ─────────────────────────────────────────────────────────

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true          // Functions runtime requires shared key access
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Storage connection string — passed to Function App settings.
// Tables (cfoperators, cfapikeys, cfsessions, cfmessages) are created at runtime by cf-mcp.
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

// ─── Monitoring (optional) ───────────────────────────────────────────────────

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (enableMonitoring) {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ─── Hosting Plan (Consumption Y1) ───────────────────────────────────────────

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: false    // Windows Consumption plan; custom handler Go binary runs on Windows
  }
}

// ─── Function App ─────────────────────────────────────────────────────────────

// App settings assembled as a variable to keep resource block readable.
// Monitoring settings are conditionally included based on enableMonitoring.
var baseAppSettings = [
  // ── Functions runtime ──────────────────────────────────────────────────────
  {
    name: 'AzureWebJobsStorage'
    value: storageConnectionString
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnectionString
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(functionAppName)
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'custom'
  }

  // ── cf-mcp configuration ───────────────────────────────────────────────────
  {
    name: 'AZURE_STORAGE_CONNECTION_STRING'
    value: storageConnectionString
  }
  {
    name: 'CF_SESSION_TOKEN'
    value: cfSessionToken
  }
  {
    name: 'CF_DOMAIN'
    value: effectiveDomain
  }
]

// Use null-coalescing to safely access conditional resource properties.
// appInsights is conditionally deployed; when disabled, these values are empty strings.
var monitoringAppSettings = enableMonitoring ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.?properties.ConnectionString ?? ''
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.?properties.InstrumentationKey ?? ''
  }
] : []

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat(baseAppSettings, monitoringAppSettings)
      minTlsVersion: '1.2'
      http20Enabled: true
      use32BitWorkerProcess: false
      // Custom handler: cf-mcp Go binary.
      // The binary must be deployed as a zip package via WEBSITE_RUN_FROM_PACKAGE.
      // host.json must configure:
      //   { "customHandler": { "description": { "defaultExecutablePath": "cf-mcp" },
      //       "enableForwardingHttpRequest": true } }
    }
  }
  // No explicit dependsOn needed — Bicep infers dependencies from property references above.
}

// ─── Outputs ─────────────────────────────────────────────────────────────────

@description('Function App default hostname (Azure-assigned).')
output functionAppHostname string = functionApp.properties.defaultHostName

@description('Function App URL.')
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'

@description('Storage account name.')
output storageAccountName string = storageAccount.name

@description('Application Insights connection string (empty if monitoring disabled).')
output appInsightsConnectionString string = appInsights.?properties.ConnectionString ?? ''

@description('Function App system-assigned managed identity principal ID.')
output functionAppPrincipalId string = functionApp.identity.principalId

@description('Function App resource ID.')
output functionAppId string = functionApp.id
