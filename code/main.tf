terraform {
  required_version = ">=1.0"
  required_providers {
    google      = "~> 3.0"
    google-beta = "~> 3.0"
  }

}

locals {
  project_id           = var.project_id
  function_bucket_name = "bkt-function-${local.project_id}"
  function_name        = "fnct-${var.function_name}-${local.project_id}"
  services             = ["cloudfunctions.googleapis.com", "secretmanager.googleapis.com"]
}


data "google_project" "target" {
  project_id = local.project_id
}

# enable servies
resource "google_project_service" "services" {
  for_each           = toset(local.services)
  project            = data.google_project.target.project_id
  service            = each.value
  disable_on_destroy = false
}

# source code zip file to send to the cloud function
data "archive_file" "source_zip" {
  type        = "zip"
  source_dir  = "${path.root}/source/"
  output_path = "${path.root}/function.zip"
}

# storage bucket for our code/zip file
resource "google_storage_bucket" "function_bucket" {

  project                     = data.google_project.target.project_id
  name                        = local.function_bucket_name
  location                    = var.default_region
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
}

# upload zipped code to the bucket
resource "google_storage_bucket_object" "function_zip" {
  name   = format("%s-%s.zip", local.function_name, data.archive_file.source_zip.output_md5)
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.root}/function.zip"
}

# secrets for the bot function
resource "google_secret_manager_secret" "slack_bot_token" {
  secret_id = "slack_bot_token"
  project   = data.google_project.target.project_id

  labels = {
    label = "secret-slack-bot-token"
  }

  replication {
    user_managed {
      replicas {
        location = var.default_region
      }
    }
  }
  depends_on = [
    google_project_service.services
  ]
}

# value for the slack_bot_token
resource "google_secret_manager_secret_version" "slack_bot_token" {

  secret      = google_secret_manager_secret.slack_bot_token.id
  secret_data = var.slack_bot_token
}

# signing secret
resource "google_secret_manager_secret" "slack_signing_secret" {
  secret_id = "slack_signing_secret"
  project   = data.google_project.target.project_id

  labels = {
    label = "secret-slack-signing-secret"
  }

  replication {
    user_managed {
      replicas {
        location = var.default_region
      }
    }
  }
  depends_on = [
    google_project_service.services
  ]
}

# value for the slack_signing_secret
resource "google_secret_manager_secret_version" "slack_signing_secret" {

  secret      = google_secret_manager_secret.slack_signing_secret.id
  secret_data = var.slack_signing_secret
}

# allow the project service account to access the secrets
resource "google_secret_manager_secret_iam_member" "slack_bot_token" {
  project   = google_secret_manager_secret.slack_bot_token.project
  secret_id = google_secret_manager_secret.slack_bot_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member = format("serviceAccount:%s@appspot.gserviceaccount.com", data.google_project.target.project_id
  )
}
resource "google_secret_manager_secret_iam_member" "slack_signing_secret" {
  project   = google_secret_manager_secret.slack_signing_secret.project
  secret_id = google_secret_manager_secret.slack_signing_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member = format("serviceAccount:%s@appspot.gserviceaccount.com", data.google_project.target.project_id
  )
}

# create the cloud function
resource "google_cloudfunctions_function" "project_function" {
  project               = data.google_project.target.project_id
  name                  = local.function_name
  description           = format("%s-%s", local.function_name, data.archive_file.source_zip.output_md5)
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  timeout               = 60
  entry_point           = "hello_slackbot"
  trigger_http          = true
  runtime               = "python38"
  region                = var.default_region
  environment_variables = {
    SLACK_BOT_TOKEN      = google_secret_manager_secret_version.slack_bot_token.secret_data,
    SLACK_SIGNING_SECRET = google_secret_manager_secret_version.slack_signing_secret.secret_data
  }
  depends_on = [
    google_storage_bucket_object.function_zip, google_project_service.services
  ]
}


# IAM entry making this public and allowing all users to invoke the function
# ensure this is what you want, or change the membership accordingly
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.project_function.project
  region         = google_cloudfunctions_function.project_function.region
  cloud_function = google_cloudfunctions_function.project_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
