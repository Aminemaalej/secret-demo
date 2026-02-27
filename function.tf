data "archive_file" "source" {
  type        = "zip"
  output_path = "/tmp/function.zip"
  source {
    content  = <<EOF
import functions_framework
from google.cloud import secretmanager
import os

@functions_framework.http
def hello_http(request):
    # 1. Setup the client
    client = secretmanager.SecretManagerServiceClient()
    
    # 2. Define the resource name of the secret
    # We grab the Project ID from the environment to make it portable
    project_id = os.environ.get('GCP_PROJECT')
    name = f"projects/{project_id}/secrets/prod-db-password/versions/latest"

    try:
        # 3. Attempt to access the secret
        response = client.access_secret_version(request={"name": name})
        secret_payload = response.payload.data.decode("UTF-8")
        
        # SUCCESS
        return f"✅ SUCCESS! I accessed the vault. The password is: {secret_payload}"
        
    except Exception as e:
        # FAILURE
        return f"❌ FAILURE! Access Denied. The Vault Manager stopped me.\nError: {e}", 403
EOF
    filename = "main.py"
  }
  source {
    content  = <<EOF
functions-framework==3.*
google-cloud-secret-manager
EOF
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket" "bucket" {
  name                        = "${var.project_id}-gcf-source"
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path
}

resource "google_cloudfunctions2_function" "function" {
  name        = "secret-demo-function"
  location    = "us-central1"
  description = "Demo function for Secret Manager"

  build_config {
    runtime     = "python310"
    entry_point = "hello_http"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.app_identity.email

    environment_variables = {
      GCP_PROJECT = var.project_id
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
