output "project_id" {
  description = "The ID of the created project"
  value       = qovery_project.doktolib.id
}

output "environment_id" {
  description = "The ID of the production environment"
  value       = qovery_environment.production.id
}

output "database_host" {
  description = "PostgreSQL database host"
  value       = qovery_database.postgres.internal_host
  sensitive   = true
}

output "database_port" {
  description = "PostgreSQL database port"
  value       = qovery_database.postgres.port
}

output "backend_url" {
  description = "Backend application URL"
  value       = "https://${qovery_application.backend.external_host}"
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "https://${qovery_application.frontend.external_host}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : null
}

output "seed_job_id" {
  description = "The ID of the seed data job"
  value       = qovery_job.seed_data.id
}

output "qovery_console_url" {
  description = "Qovery console URL for this project"
  value       = "https://console.qovery.com/platform/organization/${var.qovery_organization_id}/projects/${qovery_project.doktolib.id}/environments/${qovery_environment.production.id}/applications"
}

output "seed_configuration" {
  description = "Seed data configuration"
  value = {
    doctor_count = var.seed_doctor_count
    force_seed   = var.force_seed
    ssl_mode     = var.db_ssl_mode
  }
}