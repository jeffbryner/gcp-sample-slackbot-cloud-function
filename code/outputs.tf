output "function_url" {
  description = "url of the function"
  value       = google_cloudfunctions_function.project_function.https_trigger_url
}
