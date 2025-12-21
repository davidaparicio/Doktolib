output "environment_id" {
  description = "Qovery environment ID"
  value       = qovery_environment.doktolib.id
}

output "environment_name" {
  description = "Qovery environment name"
  value       = qovery_environment.doktolib.name
}

output "environment_url" {
  description = "Qovery environment console URL"
  value       = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}"
}

# ========================================
# Database Outputs
# ========================================

output "database_id" {
  description = "PostgreSQL database ID"
  value       = var.use_managed_database ? "Using managed database" : qovery_database.postgres[0].id
}

output "database_name" {
  description = "PostgreSQL database name"
  value       = var.use_managed_database ? "doktolib" : "postgres"
}

output "database_type" {
  description = "Database type"
  value       = var.use_managed_database ? "MANAGED (RDS Aurora)" : "CONTAINER (Qovery-managed)"
}

# ========================================
# Backend Application Outputs
# ========================================

output "backend_id" {
  description = "Backend application ID"
  value       = qovery_application.backend.id
}

output "backend_url" {
  description = "Backend application public URL"
  value       = "https://${qovery_application.backend.id}.qovery.io"
}

output "backend_internal_url" {
  description = "Backend application internal URL"
  value       = qovery_application.backend.internal_host
}

output "backend_console_url" {
  description = "Backend application console URL"
  value       = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/application/${qovery_application.backend.id}"
}

# ========================================
# Frontend Application Outputs
# ========================================

output "frontend_id" {
  description = "Frontend application ID"
  value       = qovery_application.frontend.id
}

output "frontend_url" {
  description = "Frontend application public URL (use this for Cloudflare origin_url)"
  value       = "https://${qovery_application.frontend.id}.qovery.io"
}

output "frontend_internal_url" {
  description = "Frontend application internal URL"
  value       = qovery_application.frontend.internal_host
}

output "frontend_console_url" {
  description = "Frontend application console URL"
  value       = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/application/${qovery_application.frontend.id}"
}

# ========================================
# Seed Job Outputs
# ========================================

output "seed_job_id" {
  description = "Seed data job ID"
  value       = var.enable_seed_job ? qovery_job.seed_data[0].id : "Seed job disabled"
}

output "seed_job_console_url" {
  description = "Seed data job console URL"
  value       = var.enable_seed_job ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/job/${qovery_job.seed_data[0].id}" : "Seed job disabled"
}

# ========================================
# Load Generator Outputs
# ========================================

output "load_generator_id" {
  description = "Load generator application ID"
  value       = var.enable_load_generator ? qovery_application.load_generator[0].id : "Load generator disabled"
}

output "load_generator_console_url" {
  description = "Load generator console URL"
  value       = var.enable_load_generator ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/application/${qovery_application.load_generator[0].id}" : "Load generator disabled"
}

# ========================================
# Deployment Stage Outputs
# ========================================

output "deployment_stages" {
  description = "Deployment stages"
  value = {
    database = qovery_deployment_stage.database.id
    backend  = qovery_deployment_stage.backend.id
    frontend = qovery_deployment_stage.frontend.id
    jobs     = qovery_deployment_stage.jobs.id
  }
}

# ========================================
# Quick Access URLs
# ========================================

output "application_urls" {
  description = "All application URLs"
  value = {
    frontend = "https://${qovery_application.frontend.id}.qovery.io"
    backend  = "https://${qovery_application.backend.id}.qovery.io"
    backend_health = "https://${qovery_application.backend.id}.qovery.io/api/v1/health"
  }
}

output "console_urls" {
  description = "Qovery console URLs"
  value = {
    environment    = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}"
    backend        = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/application/${qovery_application.backend.id}"
    frontend       = "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/application/${qovery_application.frontend.id}"
  }
}

# ========================================
# Configuration Summary
# ========================================

output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    environment = {
      name    = qovery_environment.doktolib.name
      mode    = var.environment_mode
      cluster = var.qovery_cluster_id
    }
    database = {
      type = var.use_managed_database ? "MANAGED (RDS Aurora)" : "CONTAINER (Qovery)"
      name = var.use_managed_database ? "doktolib" : "postgres"
    }
    backend = {
      cpu       = "${var.backend_cpu}m"
      memory    = "${var.backend_memory}MB"
      instances = "${var.backend_min_instances}-${var.backend_max_instances}"
      url       = "https://${qovery_application.backend.id}.qovery.io"
    }
    frontend = {
      cpu       = "${var.frontend_cpu}m"
      memory    = "${var.frontend_memory}MB"
      instances = "${var.frontend_min_instances}-${var.frontend_max_instances}"
      url       = "https://${qovery_application.frontend.id}.qovery.io"
    }
    seed_job = {
      enabled     = var.enable_seed_job
      num_doctors = var.seed_num_doctors
    }
    load_generator = {
      enabled = var.enable_load_generator
    }
  }
}

# ========================================
# Cloudflare Integration Output
# ========================================

output "cloudflare_origin_url" {
  description = "Use this URL as origin_url in Cloudflare Terraform (without https://)"
  value       = "${qovery_application.frontend.id}.qovery.io"
}

output "cloudflare_integration_command" {
  description = "Command to deploy Cloudflare CDN with this frontend"
  value       = <<-EOT
    cd terraform/cloudflare-cdn
    terraform apply -var="origin_url=${qovery_application.frontend.id}.qovery.io"
  EOT
}

# ========================================
# Next Steps
# ========================================

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    ✅ Deployment Complete!

    🌐 Access your applications:
    • Frontend: https://${qovery_application.frontend.id}.qovery.io
    • Backend API: https://${qovery_application.backend.id}.qovery.io
    • Backend Health: https://${qovery_application.backend.id}.qovery.io/api/v1/health

    📊 Qovery Console:
    • Environment: https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}

    🔄 Next Steps:
    ${var.enable_seed_job ? "1. Run seed data job from Qovery console to populate database" : ""}
    2. Configure Cloudflare CDN:
       cd terraform/cloudflare-cdn
       terraform apply -var="origin_url=${qovery_application.frontend.id}.qovery.io"

    3. Deploy Lambda visio health check:
       cd terraform/visio-service
       ./deploy.sh

    4. Monitor your application in Qovery console
  EOT
}

# ========================================
# Terraform Services Outputs
# ========================================

output "rds_aurora_service_id" {
  description = "RDS Aurora Terraform service ID"
  value       = length(qovery_terraform_service.rds_aurora) > 0 ? qovery_terraform_service.rds_aurora[0].id : null
}

output "rds_aurora_console_url" {
  description = "RDS Aurora Terraform service console URL"
  value       = length(qovery_terraform_service.rds_aurora) > 0 ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/terraform/${qovery_terraform_service.rds_aurora[0].id}" : null
}

output "lambda_visio_service_id" {
  description = "Lambda Visio Terraform service ID"
  value       = length(qovery_terraform_service.lambda_visio) > 0 ? qovery_terraform_service.lambda_visio[0].id : null
}

output "lambda_visio_console_url" {
  description = "Lambda Visio Terraform service console URL"
  value       = length(qovery_terraform_service.lambda_visio) > 0 ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/terraform/${qovery_terraform_service.lambda_visio[0].id}" : null
}

output "cloudflare_cdn_service_id" {
  description = "Cloudflare CDN Terraform service ID"
  value       = length(qovery_terraform_service.cloudflare_cdn) > 0 ? qovery_terraform_service.cloudflare_cdn[0].id : null
}

output "cloudflare_cdn_console_url" {
  description = "Cloudflare CDN Terraform service console URL"
  value       = length(qovery_terraform_service.cloudflare_cdn) > 0 ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/terraform/${qovery_terraform_service.cloudflare_cdn[0].id}" : null
}

output "s3_bucket_service_id" {
  description = "S3 Bucket Terraform service ID"
  value       = length(qovery_terraform_service.s3_bucket) > 0 ? qovery_terraform_service.s3_bucket[0].id : null
}

output "s3_bucket_console_url" {
  description = "S3 Bucket Terraform service console URL"
  value       = length(qovery_terraform_service.s3_bucket) > 0 ? "https://console.qovery.com/organization/${var.qovery_organization_id}/project/${var.qovery_project_id}/environment/${qovery_environment.doktolib.id}/terraform/${qovery_terraform_service.s3_bucket[0].id}" : null
}
