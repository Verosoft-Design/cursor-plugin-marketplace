---
name: al-init-keyvault
description: Wire Azure Key Vault into an AL-Go repository so secrets live in KV instead of GitHub Secrets, plus optionally configure Azure-Trusted-Signing for .app codesign. Use when the user wants centralized secret rotation, fewer per-repo GitHub Secrets, or KV-based codesigning.
disable-model-invocation: true
---

# Initialize Azure Key Vault for AL-Go

Walks through wiring an Azure Key Vault to an AL-Go repository.

## Why Key Vault

- Secrets rotate centrally; many repos share one KV.
- GitHub Secret count stays small (1 — `Azure_Credentials` — instead of dozens).
- Required for the modern (post-2023-06-01) AL-Go codesigning path.

## Two paths to authenticate to KV

### Path A — Managed Identity + Federated Credential (RECOMMENDED, no secrets)

Best for production. No client secret to rotate.

1. In Azure: create a User-Assigned Managed Identity (or use one).
2. Grant the MI access to the KV:
   - Built-in: KV → Access policies → add `Get` + `List` for the MI on Secrets (and Certificates if using KV codesign).
   - Or RBAC: assign `Key Vault Secrets User` to the MI on the KV's resource group.
3. Create a federated credential on the MI pointing at the GitHub repo:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:<owner>/<repo>:ref:refs/heads/main` (adjust ref pattern per env)
   - Audience: `api://AzureADTokenExchange`
4. Mint the `Azure_Credentials` JSON:

```powershell
@{
  keyVaultName = '<kv name>'
  clientId     = '<MI client id>'
  tenantId     = '<MI tenant id>'
} | ConvertTo-Json -Compress | Set-Clipboard
gh secret set Azure_Credentials --body "$(pbpaste)"
```

5. Reference the KV in `.github/AL-Go-Settings.json`:

```json
"keyVaultName": "<kv name>"
```

(Optional — keyVaultName can also live inside the `Azure_Credentials` JSON. Either works.)

### Path B — App Registration + Client Secret (simpler setup, requires rotation)

1. Create an Entra app registration.
2. Generate a client secret.
3. Grant the app access to the KV (same as MI: access policy or RBAC).
4. Mint the `Azure_Credentials` JSON:

```powershell
@{
  keyVaultName = '<kv name>'
  clientId     = '<app client id>'
  tenantId     = '<tenant id>'
  clientSecret = '<secret>'
} | ConvertTo-Json -Compress | Set-Clipboard
gh secret set Azure_Credentials --body "$(pbpaste)"
```

## Migrate existing secrets to KV

Once `Azure_Credentials` is wired, AL-Go can read any secret from KV instead of GitHub Secrets. Move secrets one at a time:

1. Read the GitHub Secret value (this requires asking the user, since gh cannot read secret values back — only their names).
2. Write it to KV: Azure Portal → KV → Secrets → Generate/Import, OR via Azure CLI:

```bash
az keyvault secret set --vault-name <kv name> --name <SecretName> --value "<value>"
```

3. Delete from GitHub: `gh secret delete <SecretName>`.

If the secret name in KV differs from the AL-Go default name (e.g. KV won't allow names with capital letters in some configs), set the `<secret>SecretName` indirection in `.AL-Go/settings.json`. The full list:

- `licenseFileUrlSecretName` (default `LicenseFileUrl`)
- `ghTokenWorkflowSecretName` (default `GhTokenWorkflow`)
- `adminCenterApiCredentialsSecretName` (default `AdminCenterApiCredentials`)
- `codeSignCertificateUrlSecretName` (default `CodeSignCertificateUrl`)
- `codeSignCertificatePasswordSecretName` (default `CodeSignCertificatePassword`)
- `storageContextSecretName` (default `StorageContext`)
- `applicationInsightsConnectionStringSecretName` (default `applicationInsightsConnectionString`)

## KV-based codesigning (new path)

The legacy codesign path uses `CodeSignCertificateUrl` + `CodeSignCertificatePassword` (a PFX file + password). The new path stores the certificate in a Premium-SKU KV and signs with .NET Sign.

Prerequisites:

- Premium SKU KV (required for Certificates).
- The MI / app reg used in `Azure_Credentials` needs the RBAC roles **Key Vault Crypto User** AND **Key Vault Certificate User** on the KV's resource group.
- A code signing certificate uploaded to the KV's Certificates section.

Then in `.AL-Go/settings.json`:

```json
"keyVaultCodesignCertificateName": "<certificate name in KV>",
"useCompilerFolder": true
```

(`useCompilerFolder: true` is required when using the new codesign path.)

## Trusted Signing (Azure-Trusted-Signing service)

For .app files signed via Microsoft's Trusted Signing service (post-2024 recommended path):

```json
"trustedSigning": {
  "Account": "<trusted signing account>",
  "Endpoint": "<endpoint URL>",
  "CertificateProfile": "<profile name>"
}
```

The `Azure_Credentials` MI / app reg must have **Trusted Signing Certificate Profile Signer** role on the Trusted Signing resource.

## Verify

After wiring, run `/al-troubleshoot` to confirm `Azure_Credentials` is visible to workflows and `keyVaultName` is present in the resolved settings. Then run a CI/CD build and watch the "Read Secrets" job — it should successfully fetch from KV.

## Failure modes

- "Cannot find secret in vault" — name mismatch between AL-Go expectation and KV. Either rename in KV or set the corresponding `*SecretName` setting.
- "Forbidden" on KV access — RBAC role not granted; OR access policy missing the MI/app reg.
- "AADSTS70021: No matching federated identity record found" — federated credential subject pattern doesn't match the workflow's GitHub OIDC token. Verify the `repo:<owner>/<repo>:ref:refs/heads/<branch>` shape exactly.
