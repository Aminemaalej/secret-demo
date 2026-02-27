resource "google_secret_manager_secret" "db_password" {
  secret_id = "prod-db-password"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "db_password_val" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = "SuperSecretPassword123!" # In real life, don't hardcode this here!
}

# --- THE SWITCH (Uncomment this later!) ---
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_identity.email}"
}
