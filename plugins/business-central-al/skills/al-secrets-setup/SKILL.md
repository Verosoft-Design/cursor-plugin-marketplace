---
name: al-secrets-setup
description: Interactive wizard for minting the JSON-shaped secrets that AL-Go workflows need (AuthContext, AppSourceContext, GhTokenWorkflow, AdminCenterApiCredentials, StorageContext, NuGetContext, GitHubPackagesContext). Use when an AL-Go workflow fails on missing or expired secrets, or when first wiring up CI/CD.
disable-model-invocation: true
---

# AL-Go secrets setup wizard

Guides the user through minting and installing each AL-Go secret they need. Most secrets are JSON blobs created by BcContainerHelper PowerShell helpers and stored via `gh secret set`.

## How to use this command

Ask the user which secret they need to set up. Walk them through ONE secret at a time. For each, follow the recipe below.

## Prerequisites for the user

- PowerShell 7+ on Windows / macOS / Linux (or PowerShell 5.1 on Windows).
- BcContainerHelper installed: `Install-Module BCContainerHelper -AllowPrerelease`.
- `gh` CLI authenticated.

## Recipe per secret

### `GhTokenWorkflow` — needed for Update System Files, Create Release, Increment Version, Create a new app family

**Recommended: GitHub App** (no human creator, bot commits, no expiry).

1. Create a GitHub App: visit `https://github.com/settings/apps/new` (personal) or `https://github.com/organizations/<org>/settings/apps/new` (org).
2. Configure permissions:
   - Repository → Contents: Read & write
   - Repository → Pull requests: Read & write
   - Repository → Workflows: Read & write
   - Repository → Actions: Read
3. Generate a private key (`.pem` file).
4. Install the app in the target repo(s).
5. Mint the JSON:

```powershell
$appId = '<client id from app overview>'
$pk    = '<path to downloaded .pem>'
@{
  "GitHubAppClientId" = $appId
  "PrivateKey"        = ([string]::Join('', [IO.File]::ReadAllLines($pk)))
} | ConvertTo-Json -Compress -Depth 99 | Set-Clipboard
```

6. Set the secret:

```bash
gh secret set GhTokenWorkflow --body "$(pbpaste)"
# On Windows: gh secret set GhTokenWorkflow --body "$(Get-Clipboard)"
```

**Alternative: PAT** (fine-grained preferred). Permissions: same as the GitHub App above. Set as `gh secret set GhTokenWorkflow --body "<token>"`.

### `AuthContext` / `<EnvName>_AuthContext` — needed for Publish To Environment

Two flavors:

**S2S (recommended for production / automation)** — requires an Entra app registered against the BC tenant per `https://go.microsoft.com/fwlink/?linkid=2217415`. Then:

```powershell
$ac = New-BcAuthContext -tenantID '<tenant id>' -clientID '<client id>' -clientSecret '<secret>' -scopes 'https://api.businesscentral.dynamics.com/.default'
New-ALGoAuthContext -bcAuthContext $ac | Set-Clipboard
```

**Refresh-token impersonation (dev / quick start)** — ~90-day expiry, prompts a browser sign-in:

```powershell
$ac = New-BcAuthContext -includeDeviceLogin
New-ALGoAuthContext -bcAuthContext $ac | Set-Clipboard
```

Then for the secret target:

- Repo-wide: `gh secret set AuthContext --body "$(pbpaste)"`
- Env-scoped: `gh secret set <EnvName>_AuthContext --body "$(pbpaste)" --env <EnvName>`

### `AppSourceContext` — needed for Publish To AppSource

S2S against Partner Center API. Requires registering an Entra app and adding it as a Partner Center API user (Microsoft Learn: "Manage your accounts, users, and subscriptions in Partner Center").

```powershell
$ac = New-BcAuthContext -tenantID '<tenant id>' -clientID '<client id>' -clientSecret '<secret>' -scopes 'https://api.partner.microsoft.com/.default'
New-ALGoAppSourceContext -bcAuthContext $ac | Set-Clipboard
gh secret set AppSourceContext --body "$(pbpaste)"
```

### `AdminCenterApiCredentials` — needed for Create Online Dev. Environment

Refresh-token flow (the BC Admin Center API has no S2S today):

```powershell
$ac = New-BcAuthContext -includeDeviceLogin
@{ refreshtoken = $ac.refreshToken } | ConvertTo-Json -Compress | Set-Clipboard
gh secret set AdminCenterApiCredentials --body "$(pbpaste)"
```

### `StorageContext` — needed for Deliver to Azure Storage

Several auth options; managed identity / federated credentials are recommended. For app-reg with secret:

```powershell
$sc = @{
  storageAccount    = '<account>'
  clientId          = '<client id>'
  clientSecret      = '<secret>'
  tenantId          = '<tenant id>'
  containerName     = 'al-go-{project}-{branch}'
  blobName          = '{project}-{type}-{version}.zip'
} | ConvertTo-Json -Compress
$sc | Set-Clipboard
gh secret set StorageContext --body "$(pbpaste)"
```

Placeholders `{project}`, `{branch}`, `{version}`, `{type}` are substituted at delivery time.

### `NuGetContext` — needed for Deliver to NuGet (e.g. Azure DevOps Artifacts, NuGet.org)

Provider-specific JSON. For Azure DevOps Artifacts:

```powershell
@{
  serverUrl = 'https://pkgs.dev.azure.com/<org>/_packaging/<feed>/nuget/v3/index.json'
  token     = '<PAT with packaging-write scope>'
} | ConvertTo-Json -Compress | Set-Clipboard
gh secret set NuGetContext --body "$(pbpaste)"
```

Note: `NuGetContext` is for DELIVERY only. To also use a NuGet feed for symbol/dependency RESOLUTION, add it to `trustedNuGetFeeds` in `.AL-Go/settings.json`.

### `GitHubPackagesContext` — needed for Deliver to GitHub Packages

Auto-used for both delivery AND resolution within the same org.

```powershell
@{
  serverUrl = 'https://nuget.pkg.github.com/<org>/index.json'
  token     = '<classic PAT with write:packages + read:packages (+ repo for private)>'
} | ConvertTo-Json -Compress | Set-Clipboard
gh secret set GitHubPackagesContext --body "$(pbpaste)"
```

Currently requires a CLASSIC PAT (fine-grained tokens do not yet support packages scopes).

### `LicenseFileUrl` — needed for AppSource apps on BC pre-22 (CRONUS license suffices for BC 22+)

Set the direct URL of the `.bclicense` file:

```bash
gh secret set LicenseFileUrl --body "<URL to .bclicense file>"
```

### `applicationInsightsConnectionString` — telemetry connection string injected into the apps

```bash
gh secret set applicationInsightsConnectionString --body "<Application Insights connection string>"
```

## Verifying

After setting each secret, confirm with:

```bash
gh secret list
# or for env-scoped:
gh secret list --env <EnvName>
```

The secret should appear by name (values are never visible after setting).

## Putting them behind Azure Key Vault

Once the user has more than 2–3 secrets, consider migrating them to Azure Key Vault. `/al-init-keyvault` wraps that flow. After KV is wired, the same secret NAMES live in KV instead of GitHub Secrets, and AL-Go reads them via the `Azure_Credentials` secret only.

## When to re-run

- A workflow fails with an auth error → the secret is missing or expired. For refresh-token-based secrets (impersonation `AuthContext`, `AdminCenterApiCredentials`), re-mint roughly every 90 days.
- A new env is added → mint a new `<EnvName>_AuthContext`.
- The first time a new delivery target is wired → mint the corresponding `<Target>Context`.
