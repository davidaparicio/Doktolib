terraform {
  required_providers {
    qovery = {
      source  = "qovery/qovery"
      version = "~> 0.38.0"
    }
  }
}

provider "qovery" {
  token = var.qovery_api_token
}

# Create organization (if you don't have one)
data "qovery_organization" "my_org" {
  id = var.qovery_organization_id
}

# Create project
resource "qovery_project" "doktolib" {
  organization_id = data.qovery_organization.my_org.id
  name           = "doktolib"
  description    = "Doctolib clone - Doctor appointment booking platform"
}

# Create environment
resource "qovery_environment" "production" {
  project_id = qovery_project.doktolib.id
  name       = "production"
  mode       = "PRODUCTION"
  
  # Deploy on AWS
  cluster_id = var.qovery_cluster_id
}

# PostgreSQL Database
resource "qovery_database" "postgres" {
  environment_id = qovery_environment.production.id
  name          = "doktolib-db"
  type          = "POSTGRESQL"
  version       = "15"
  mode          = "CONTAINER"
  storage       = 10
  accessibility = "PRIVATE"
  
  # Environment variables will be automatically injected
}

# Backend Application
resource "qovery_application" "backend" {
  environment_id = qovery_environment.production.id
  name          = "doktolib-backend"
  
  git_repository = {
    url       = var.git_repository_url
    branch    = "main"
    root_path = "/backend"
  }
  
  build_mode            = "DOCKER"
  dockerfile_path       = "Dockerfile"
  
  # Resources
  cpu    = 500  # 0.5 vCPU
  memory = 512  # 512 MB
  
  # Ports
  ports = [
    {
      internal_port       = 8080
      external_port       = 443
      protocol           = "HTTP"
      publicly_accessible = true
      name               = "http"
    }
  ]
  
  # Environment variables
  environment_variables = [
    {
      key   = "PORT"
      value = "8080"
    },
    {
      key   = "GIN_MODE"
      value = "release"
    },
    {
      key   = "DB_SSL_MODE"
      value = var.db_ssl_mode
    }
  ]
  
  # Database connection will be auto-injected by Qovery
  built_in_environment_variables = [
    {
      key = "DATABASE_URL"
    }
  ]
  
  # Auto-deploy on git push
  auto_deploy = true
  
  # Health checks
  healthchecks = {
    readiness_probe = {
      type = {
        http = {
          port = 8080
          path = "/api/v1/health"
        }
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      success_threshold    = 1
      failure_threshold    = 3
    }
    liveness_probe = {
      type = {
        http = {
          port = 8080
          path = "/api/v1/health"
        }
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      success_threshold    = 1
      failure_threshold    = 3
    }
  }
  
  depends_on = [qovery_database.postgres]
}

# Frontend Application
resource "qovery_application" "frontend" {
  environment_id = qovery_environment.production.id
  name          = "doktolib-frontend"
  
  git_repository = {
    url       = var.git_repository_url
    branch    = "main"
    root_path = "/frontend"
  }
  
  build_mode            = "DOCKER"
  dockerfile_path       = "Dockerfile"
  
  # Resources
  cpu    = 500  # 0.5 vCPU
  memory = 512  # 512 MB
  
  # Ports
  ports = [
    {
      internal_port       = 3000
      external_port       = 443
      protocol           = "HTTP"
      publicly_accessible = true
      name               = "http"
    }
  ]
  
  # Environment variables
  environment_variables = [
    {
      key   = "PORT"
      value = "3000"
    },
    {
      key   = "NODE_ENV"
      value = "production"
    },
    {
      key   = "NEXT_PUBLIC_API_URL"
      value = "https://${qovery_application.backend.external_host}"
    }
  ]
  
  # Auto-deploy on git push
  auto_deploy = true
  
  # Health checks
  healthchecks = {
    readiness_probe = {
      type = {
        http = {
          port = 3000
          path = "/"
        }
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      success_threshold    = 1
      failure_threshold    = 3
    }
    liveness_probe = {
      type = {
        http = {
          port = 3000
          path = "/"
        }
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      success_threshold    = 1
      failure_threshold    = 3
    }
  }
  
  depends_on = [qovery_application.backend]
}

# Custom domain for production (optional)
resource "qovery_custom_domain" "frontend_domain" {
  count          = var.custom_domain != "" ? 1 : 0
  application_id = qovery_application.frontend.id
  domain         = var.custom_domain
  
  # Generate Let's Encrypt SSL certificate
  generate_certificate = true
}

# Seed Data Lifecycle Job
resource "qovery_job" "seed_data" {
  environment_id = qovery_environment.production.id
  name          = "doktolib-seed-data"
  
  git_repository = {
    url       = var.git_repository_url
    branch    = "main"
    root_path = "/seed-data"
  }
  
  build_mode            = "DOCKER"
  dockerfile_path       = "Dockerfile"
  
  # Resources (smaller since it's a one-time job)
  cpu    = 256  # 0.25 vCPU
  memory = 512  # 512 MB
  
  # Job configuration
  max_nb_restart = 3
  max_duration_seconds = 1800  # 30 minutes timeout
  
  # Environment variables
  environment_variables = [
    {
      key   = "DB_SSL_MODE"
      value = var.db_ssl_mode
    },
    {
      key   = "DOCTOR_COUNT"
      value = tostring(var.seed_doctor_count)
    },
    {
      key   = "FORCE_SEED"
      value = tostring(var.force_seed)
    }
  ]
  
  # Database connection will be auto-injected by Qovery
  built_in_environment_variables = [
    {
      key = "DATABASE_URL"
    }
  ]
  
  # Job lifecycle - run after database is ready
  schedule = {
    lifecycle_type = "START"
  }
  
  depends_on = [qovery_database.postgres]
}

# Deploy the environment
resource "qovery_deployment" "deploy_production" {
  environment_id = qovery_environment.production.id
  desired_state  = "RUNNING"
  
  depends_on = [
    qovery_database.postgres,
    qovery_job.seed_data,
    qovery_application.backend,
    qovery_application.frontend
  ]
}