# GCP Secret Manager Demo with Cloud Functions

This demo provisions a **Cloud Function (Gen 2)** that attempts to access a secret stored in **Google Cloud Secret Manager**. It illustrates how GCP IAM controls access to secrets through service account identity, by toggling a single IAM binding between a "failure" and "success" state.

## Architecture

- **Secret Manager** stores a secret (`prod-db-password`).
- A **Service Account** (`secure-app-sa`) acts as the application's identity.
- A **Cloud Function (Gen 2)** runs with that service account and tries to read the secret at invocation time.
- An **IAM binding** (the "switch") grants or denies the service account access to the secret.

## Prerequisites

- A GCP project with billing enabled
- `gcloud` CLI installed and authenticated (`gcloud auth application-default login`)
- Terraform >= 1.0 installed

## File Structure

| File | Description |
|---|---|
| `versions.tf` | Terraform version and required providers |
| `provider.tf` | Google provider configuration |
| `variables.tf` | Input variable declarations |
| `main.tf` | API enablement and service account |
| `secrets.tf` | Secret Manager resources and IAM access binding |
| `function.tf` | Cloud Function, source archive, and storage bucket |
| `outputs.tf` | Output values (function URL) |
| `terraform.tfvars` | Project-specific variable values (git-ignored) |

## Getting Started

1. **Clone and configure:**

   ```bash
   cd secret-demo
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` and set your GCP project ID.

2. **Initialize Terraform:**

   ```bash
   terraform init
   ```

## Demo Walkthrough

### Step 1 — Deploy the "Failure" State

Before deploying, make sure the IAM binding in `secrets.tf` is **commented out**:

```hcl
# resource "google_secret_manager_secret_iam_member" "secret_access" {
#   secret_id = google_secret_manager_secret.db_password.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.app_identity.email}"
# }
```

Then apply:

```bash
terraform apply
```

> Cloud Functions can take 2-3 minutes to deploy.

Once complete, open the `function_uri` output URL in your browser.

**Expected result:** `FAILURE! Access Denied...` — the function's service account has no permission to read the secret.

### Step 2 — Flip the Switch to "Success"

1. Open `secrets.tf` and **uncomment** the `google_secret_manager_secret_iam_member` block.
2. Apply again:

   ```bash
   terraform apply
   ```

   This is fast (~10 seconds) since it only updates an IAM policy.

3. Refresh the function URL in your browser.

**Expected result:** `SUCCESS! I accessed the vault...` — the service account now has the `secretmanager.secretAccessor` role.

## Cleanup

```bash
terraform destroy
```

## Key Takeaway

Access to secrets in GCP is not controlled by network rules or API keys — it is controlled by **IAM bindings on the secret resource itself**. An application (service account) can only read a secret if it has been explicitly granted the `roles/secretmanager.secretAccessor` role on that specific secret.
