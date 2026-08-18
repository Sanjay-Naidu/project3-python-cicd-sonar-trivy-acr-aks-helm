# Setup Guide — Project 3: Python CI/CD on AKS

**Author: Sanjay Naidu**

This is the one-time bootstrap. Everything here is the "chicken-and-egg" part that pipelines can't do for themselves: state storage, identity federation (OIDC), GitHub configuration, SonarCloud. All commands are PowerShell-ready. Budget ~45–60 minutes.

> **Placeholders used throughout** — pick your values once and reuse them:
>
> | Placeholder | Example | Rule |
> |---|---|---|
> | `<SUBSCRIPTION_ID>` | from `az account show` | — |
> | `<GITHUB_USER>` | your GitHub username | — |
> | `<STORAGE_ACCOUNT>` | `stp3tfstatesanjay01` | globally unique, 3–24 chars, lowercase+digits |
> | `<ACR_NAME>` | `acrproject3sanjay01` | globally unique, 5–50 chars, alphanumeric |

The repo name used everywhere: **`project3-python-cicd-sonar-trivy-acr-aks-helm`**

---

## Phase 0 — Prerequisites

```powershell
az version          # Azure CLI
terraform version   # >= 1.9
git --version
# helm is only needed for local linting (pipelines have it preinstalled):
winget install Helm.Helm
```

Log in and capture your IDs:

```powershell
az login
az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
$SUB_ID    = (az account show --query id -o tsv)
$TENANT_ID = (az account show --query tenantId -o tsv)
```

---

## Phase 1 — Terraform state backend (manual, once)

Why manual: Terraform cannot store its state inside a storage account it hasn't created yet.

```powershell
az group create --name rg-project3-tfstate --location eastus

az storage account create `
  --name <STORAGE_ACCOUNT> `
  --resource-group rg-project3-tfstate `
  --location eastus `
  --sku Standard_LRS `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false

az storage container create `
  --name tfstate `
  --account-name <STORAGE_ACCOUNT> `
  --auth-mode login
```

Give **yourself** data-plane access to the state blobs (we use Entra ID auth, not storage keys):

```powershell
$MY_ID = (az ad signed-in-user show --query id -o tsv)
az role assignment create `
  --assignee $MY_ID `
  --role "Storage Blob Data Contributor" `
  --scope "/subscriptions/$SUB_ID/resourceGroups/rg-project3-tfstate/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>"
```

Then edit **`terraform/backend.hcl`**: set `storage_account_name = "<STORAGE_ACCOUNT>"`.

---

## Phase 2 — Entra ID app registration + OIDC federation

This is what lets GitHub Actions authenticate to Azure **without any stored password**.

### 2.1 Create the app registration + service principal

```powershell
$APP_ID = (az ad app create --display-name "github-project3-cicd" --query appId -o tsv)
az ad sp create --id $APP_ID
$APP_OBJ_ID = (az ad app show --id $APP_ID --query id -o tsv)
echo "AZURE_CLIENT_ID = $APP_ID"
```

### 2.2 Federated credentials (one per GitHub context)

GitHub sends a different OIDC `subject` depending on where the workflow runs — each needs its own federated credential. **Four are required** for this project:

```powershell
# 1. Pushes to main (build-and-push job, terraform plan on main)
az ad app federated-credential create --id $APP_OBJ_ID --parameters '{
  \"name\": \"gh-main-branch\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:<GITHUB_USER>/project3-python-cicd-sonar-trivy-acr-aks-helm:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}'

# 2. Pull requests (terraform plan on PRs)
az ad app federated-credential create --id $APP_OBJ_ID --parameters '{
  \"name\": \"gh-pull-requests\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:<GITHUB_USER>/project3-python-cicd-sonar-trivy-acr-aks-helm:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}'

# 3. Jobs bound to the dev environment (deploy-dev)
az ad app federated-credential create --id $APP_OBJ_ID --parameters '{
  \"name\": \"gh-env-dev\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:<GITHUB_USER>/project3-python-cicd-sonar-trivy-acr-aks-helm:environment:dev\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}'

# 4. Jobs bound to the prod environment (deploy-prod, terraform apply)
az ad app federated-credential create --id $APP_OBJ_ID --parameters '{
  \"name\": \"gh-env-prod\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:<GITHUB_USER>/project3-python-cicd-sonar-trivy-acr-aks-helm:environment:prod\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}'
```

### 2.3 Azure role assignments for the service principal

```powershell
$SP_ID = (az ad sp show --id $APP_ID --query id -o tsv)

# Contributor: create/manage all workload resources (also covers ACR push/pull)
az role assignment create --assignee $SP_ID --role "Contributor" --scope "/subscriptions/$SUB_ID"

# User Access Administrator: Terraform creates ONE role assignment (AcrPull
# for the AKS kubelet identity) - Contributor alone cannot grant roles.
# (Least-privilege alternative: scope this to the two resource groups only.)
az role assignment create --assignee $SP_ID --role "User Access Administrator" --scope "/subscriptions/$SUB_ID"

# State blob access (Entra ID auth to the backend)
az role assignment create `
  --assignee $SP_ID `
  --role "Storage Blob Data Contributor" `
  --scope "/subscriptions/$SUB_ID/resourceGroups/rg-project3-tfstate/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>"
```

---

## Phase 3 — GitHub repository

### 3.1 Create and push

Create a **public** repo named `project3-python-cicd-sonar-trivy-acr-aks-helm` on github.com (public = free unlimited Actions minutes + free SonarCloud + free Security tab uploads + environment protection rules on the Free plan). Then:

```powershell
cd "<this project folder>"
git init -b main
git add .
git commit -m "Project 3: Python app CI/CD on AKS - initial commit"
git remote add origin https://github.com/<GITHUB_USER>/project3-python-cicd-sonar-trivy-acr-aks-helm.git
git push -u origin main
```

### 3.2 Secrets (Settings → Secrets and variables → Actions → *Secrets*)

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `$APP_ID` from Phase 2.1 |
| `AZURE_TENANT_ID` | `$TENANT_ID` from Phase 0 |
| `AZURE_SUBSCRIPTION_ID` | `$SUB_ID` from Phase 0 |
| `SONAR_TOKEN` | from Phase 4 below |

(The three `AZURE_*` values are identifiers, not passwords — OIDC means there is no password. They're stored as secrets by convention.)

### 3.3 Variables (same page → *Variables* tab)

| Variable | Value |
|---|---|
| `ACR_NAME` | `<ACR_NAME>` (must match `terraform/terraform.tfvars`) |
| `AKS_CLUSTER_NAME` | `aks-project3` |
| `AKS_RESOURCE_GROUP` | `rg-project3-aks` |

### 3.4 Environments (Settings → Environments)

| Environment | Protection |
|---|---|
| `dev` | none — deploys automatically |
| `prod` | **Required reviewers: you** — every prod deploy and every terraform apply/destroy pauses for your approval |

### 3.5 Branch protection (Settings → Branches → Add rule for `main`)

Require a pull request before merging + require status checks (select the PR Validation jobs after their first run). This makes the PR pipeline an actual gate, not decoration.

---

## Phase 4 — SonarCloud

1. Go to [sonarcloud.io](https://sonarcloud.io) → **Log in with GitHub** → import your organization (free plan).
2. **Analyze new project** → select this repo.
3. **Important:** in the SonarCloud project → Administration → Analysis Method → **turn OFF "Automatic Analysis"** (it conflicts with CI-based analysis — the pipeline would fail with "You are running CI analysis while Automatic Analysis is enabled").
4. Copy the **organization key** and **project key** into `sonar-project.properties`.
5. My Account → Security → **Generate token** → save as the `SONAR_TOKEN` GitHub secret.

---

## Phase 5 — Edit placeholders, then provision

Files to touch (all placeholders say `CHANGE_ME`):

| File | What to set |
|---|---|
| `terraform/backend.hcl` | `storage_account_name` |
| `terraform/terraform.tfvars` | `acr_name`, confirm `budget_alert_email` |
| `sonar-project.properties` | `sonar.projectKey`, `sonar.organization` |
| `README.md` + `Dockerfile` | your GitHub username in badge/label URLs |

First apply — run **locally** (simplest way to bootstrap; afterwards use the gated workflow):

```powershell
cd terraform
$env:ARM_SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
terraform init -backend-config=backend.hcl
terraform plan     # review: ~12 resources
terraform apply    # 5-10 minutes (AKS takes the longest)
terraform output   # confirm the values match your GitHub variables
```

Commit + push the placeholder edits — that push triggers the first full **Build and Deploy** run.

---

## Phase 6 — Verify end-to-end

Watch the Actions tab: quality → build/scan/push → deploy dev → **waiting for approval** → approve → deploy prod.

```powershell
az aks get-credentials --resource-group rg-project3-aks --name aks-project3

kubectl get pods -n dev
kubectl get pods -n prod

# Dev (no ingress by design):
kubectl -n dev port-forward svc/python-app 8080:80
# then browse http://localhost:8080/  and  /docs

# Prod (public via managed nginx):
kubectl -n app-routing-system get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# then browse http://<PUBLIC-IP>/  - note "environment": "prod" and the sha version
```

Demo-worthy check: the `version` field on `/` equals the image tag `sha-<commit>` of your latest merge — provable traceability from commit to running pod.

---

## Phase 7 — Cost controls (do this religiously on a trial)

```powershell
# Pause compute when not demoing (~$0 compute while stopped):
az aks stop --name aks-project3 --resource-group rg-project3-aks
az aks start --name aks-project3 --resource-group rg-project3-aks   # ~3 min

# Nuke everything when you are done (state survives in rg-project3-tfstate):
# GitHub -> Actions -> "Terraform Infra" -> Run workflow -> action: destroy -> approve
# (or locally: terraform destroy)
```

Budget alerts (50%/80% actual, 100% forecast of $80) email `raghumanda24@gmail.com` automatically — they're Terraform-managed.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `AADSTS700213: no matching federated identity record` | The OIDC `subject` doesn't match a federated credential. Check repo name/username spelling in Phase 2.2; remember `environment:` jobs use the environment subject, not the branch one. |
| `Automatic Analysis is enabled` (Sonar step) | Phase 4 step 3 was skipped — disable Automatic Analysis in SonarCloud. |
| Trivy fails the build on image vulns | That's it working. Bump the base image / dependency it names, or if unfixed, note it — `ignore-unfixed: true` already skips unpatchable ones. |
| `terraform init` 403 on state | Missing "Storage Blob Data Contributor" (Phases 1/2.3) — RBAC can take ~5 min to propagate. |
| AKS create: quota/SKU error | Free trial regional limits. Change `location` in `terraform.tfvars` (try `westus2`, `centralindia`, `southeastasia`); keep `max_node_count = 2` (4 vCPU cap). |
| `code scanning is not enabled` on SARIF upload | Repo Settings → Security → Code scanning → enable. Works free on public repos. |
| Two hostless ingresses conflict | By design only prod has ingress enabled; dev is port-forward. If you enable dev ingress too, give each a distinct `host` (e.g. nip.io names). |

---

*Setup guide by Sanjay Naidu — Project 3, July 2026.*
