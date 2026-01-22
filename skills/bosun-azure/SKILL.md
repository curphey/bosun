---
name: bosun-azure
description: Microsoft Azure security and best practices. Use when reviewing Azure infrastructure, RBAC policies, Storage accounts, Azure Functions, or ARM/Bicep templates. Provides patterns for secure Azure deployments.
tags: [azure, cloud, security, rbac, storage, functions, infrastructure]
---

# Bosun Azure Skill

Azure security patterns and infrastructure best practices for secure cloud deployments.

## When to Use

- Reviewing Azure RBAC and managed identities
- Auditing Storage account configurations
- Securing Azure Functions and App Service
- Reviewing ARM templates or Bicep files
- Setting up VNet and network security groups
- Configuring Azure SQL security

## When NOT to Use

- General infrastructure patterns (use bosun-devops)
- AWS-specific (use bosun-aws)
- GCP-specific (use bosun-gcp)
- Kubernetes (use bosun-devops)

## RBAC Security

### Managed Identity Best Practices

```bicep
// User-assigned managed identity (preferred)
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'app-identity'
  location: location
}

// Role assignment with least privilege
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, 'Storage Blob Data Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### RBAC Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| Owner role | Full control | Use specific roles |
| Contributor role | Too broad | Scope to service-specific roles |
| Classic administrators | Legacy, hard to audit | Use RBAC only |
| Service principal secrets | Credential management | Use managed identities |
| Subscription-level assignments | Blast radius | Scope to resource group |

### Secure Role Assignment

```bicep
// ❌ BAD: Owner at subscription level
resource badAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'owner')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635') // Owner
    principalId: principalId
  }
  scope: subscription()
}

// ✅ GOOD: Specific role at resource scope
resource goodAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'blob-reader')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  scope: storageAccount
}
```

## Storage Account Security

### Secure Storage Configuration

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'  // Geo-redundant
  }
  kind: 'StorageV2'
  properties: {
    // Disable public access
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false  // Use Azure AD only!

    // Require secure transfer
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'

    // Network restrictions
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnet.id
          action: 'Allow'
        }
      ]
    }

    // Encryption
    encryption: {
      services: {
        blob: { enabled: true, keyType: 'Account' }
        file: { enabled: true, keyType: 'Account' }
      }
      keySource: 'Microsoft.Keyvault'  // Customer-managed keys
      keyvaultproperties: {
        keyname: keyVaultKey.name
        keyvaulturi: keyVault.properties.vaultUri
      }
    }
  }
}

// Enable soft delete
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}
```

### Storage Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `allowBlobPublicAccess: true` | Public containers | Set to false |
| `allowSharedKeyAccess: true` | Key-based access | Use Azure AD |
| HTTP allowed | Unencrypted traffic | `supportsHttpsTrafficOnly: true` |
| TLS 1.0/1.1 | Weak encryption | `minimumTlsVersion: 'TLS1_2'` |
| No network rules | Open to internet | Use VNet rules or private endpoints |
| No soft delete | Data loss | Enable retention policies |

## Azure Functions Security

### Secure Function Configuration

```bicep
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true

    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true

      // VNet integration
      vnetRouteAllEnabled: true

      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultSecret.properties.secretUri})'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }

    virtualNetworkSubnetId: subnet.id
  }
}

// Restrict access to function
resource functionAccessRestriction 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    ipSecurityRestrictions: [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 100
        name: 'Allow Front Door'
      }
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
      }
    ]
  }
}
```

### Functions Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| Anonymous auth | Public endpoint | Use function keys or Azure AD |
| System-assigned identity | Lifecycle issues | Use user-assigned |
| Secrets in app settings | Visible in portal | Use Key Vault references |
| No VNet integration | Public network | Enable VNet integration |
| FTP enabled | Legacy, insecure | Set `ftpsState: 'Disabled'` |

## VNet & NSG Security

### Network Security Group Rules

```bicep
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      // ❌ BAD: Open SSH
      // {
      //   name: 'AllowSSH'
      //   properties: {
      //     priority: 100
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'  // From anywhere!
      //     destinationPortRange: '22'
      //   }
      // }

      // ✅ GOOD: Restricted HTTPS from App Gateway
      {
        name: 'AllowAppGateway'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}
```

### VNet Best Practices

| Practice | Implementation |
|----------|----------------|
| Private endpoints | Access PaaS services privately |
| Service endpoints | VNet-to-service traffic |
| NSG Flow Logs | Network monitoring |
| Azure Bastion | Secure VM access |
| No public IPs | Use NAT Gateway for outbound |
| Network Watcher | Diagnostics and monitoring |

## Azure SQL Security

### Secure SQL Configuration

```bicep
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    // Azure AD only authentication
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: aadAdminGroup
      sid: aadAdminGroupId
      tenantId: subscription().tenantId
    }

    // Disable public access
    publicNetworkAccess: 'Disabled'

    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    // Transparent Data Encryption
    // (enabled by default, but can use customer-managed keys)
  }
}

// Private endpoint
resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${sqlServerName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${sqlServerName}-plsc'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}
```

### SQL Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| SQL authentication | Weak credentials | Use Azure AD only |
| Public network access | Direct internet access | Use private endpoints |
| TLS < 1.2 | Weak encryption | Set `minimalTlsVersion: '1.2'` |
| No auditing | No visibility | Enable auditing to Log Analytics |
| Firewall rule 0.0.0.0 | Allow all Azure | Use private endpoints |

## Key Vault Security

### Using Key Vault

```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId

    // RBAC instead of access policies
    enableRbacAuthorization: true

    // Soft delete and purge protection
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true

    // Network restrictions
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        { id: subnet.id }
      ]
    }
  }
}

// Grant access via RBAC
resource kvSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, 'secrets-user')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Secrets in App Settings

```bicep
// Reference Key Vault secrets in app settings
appSettings: [
  {
    name: 'DatabasePassword'
    value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/db-password/)'
  }
]
```

## Quick Reference

### Security Checklist

**RBAC:**
- [ ] No Owner/Contributor at subscription level
- [ ] Managed identities (not service principal secrets)
- [ ] Scope assignments to resource groups
- [ ] Custom roles for fine-grained access

**Storage:**
- [ ] Public blob access disabled
- [ ] Shared key access disabled (Azure AD only)
- [ ] HTTPS only, TLS 1.2+
- [ ] Private endpoints or VNet rules
- [ ] Soft delete enabled

**Functions/App Service:**
- [ ] HTTPS only
- [ ] User-assigned managed identity
- [ ] Secrets from Key Vault
- [ ] VNet integration
- [ ] Access restrictions configured

**Network:**
- [ ] No public IPs on VMs
- [ ] NSG rules are restrictive
- [ ] NSG Flow Logs enabled
- [ ] Azure Bastion for admin access

**Data:**
- [ ] Azure AD authentication only
- [ ] Private endpoints for PaaS
- [ ] TLS 1.2+ required
- [ ] Auditing enabled

### Azure Security Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| Microsoft Defender for Cloud | Security posture | Portal |
| Azure Policy | Compliance enforcement | Portal/CLI |
| Azure Advisor | Best practice recommendations | Portal |
| Network Watcher | Network diagnostics | Portal/CLI |
| az cli | CLI management | `az` commands |
| Checkov | IaC security | `checkov -f main.bicep` |
| tfsec | Terraform security | `tfsec .` |

## References

See `references/` for detailed documentation:
- `rbac-patterns.md` - Advanced RBAC patterns
- `network-security.md` - VNet and NSG patterns
- `defender.md` - Microsoft Defender configuration
