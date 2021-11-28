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
  services             = ["cloudfunctions.googleapis.com"]
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

# create the cloud function
resource "google_cloudfunctions_function" "project_function" {
  project               = data.google_project.target.project_id
  name                  = local.function_name
  description           = format("%s-%s", local.function_name, data.archive_file.source_zip.output_md5)
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  timeout               = 60
  entry_point           = "hello_world"
  trigger_http          = true
  runtime               = "python38"
  region                = var.default_region
  depends_on = [
    google_storage_bucket_object.function_zip,
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
