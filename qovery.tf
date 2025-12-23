terraform {
  required_version = ">= 1.0"

  required_providers {
    qovery = {
      source  = "qovery/qovery"
      version = "0.54.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "qovery" {
  token = var.qovery_access_token
}

# ========================================
# Environment
# ========================================

resource "qovery_environment" "doktolib" {
  project_id = var.qovery_project_id
  cluster_id = var.qovery_cluster_id
  name       = var.environment_name
  mode       = var.environment_mode # PRODUCTION, STAGING, DEVELOPMENT
}

# ========================================
# Deployment Stages
# ========================================

# Stage 0: Initialization (lifecycle jobs)
resource "qovery_deployment_stage" "initialization" {
  environment_id = qovery_environment.doktolib.id
  name           = "Initialization"
  description    = "Lifecycle jobs and environment setup"
}

# Stage 1: Infrastructure (terraform services)
resource "qovery_deployment_stage" "infrastructure" {
  environment_id = qovery_environment.doktolib.id
  name           = "Infrastructure"
  description    = "AWS infrastructure provisioning (RDS, Lambda, S3)"
  is_after       = qovery_deployment_stage.initialization.id
}

# Stage 2: Database
resource "qovery_deployment_stage" "database" {
  environment_id = qovery_environment.doktolib.id
  name           = "Database"
  description    = "PostgreSQL database deployment"
  is_after       = qovery_deployment_stage.infrastructure.id
}

# Stage 2: Backend API
resource "qovery_deployment_stage" "backend" {
  environment_id = qovery_environment.doktolib.id
  name           = "Backend"
  description    = "Go backend API deployment"
  is_after       = qovery_deployment_stage.database.id
}

# Stage 3: Frontend Application
resource "qovery_deployment_stage" "frontend" {
  environment_id = qovery_environment.doktolib.id
  name           = "Frontend"
  description    = "Next.js frontend deployment"
  is_after       = qovery_deployment_stage.backend.id
}

# Stage 4: Jobs (seed data, etc.)
resource "qovery_deployment_stage" "jobs" {
  environment_id = qovery_environment.doktolib.id
  name           = "Jobs"
  description    = "Background jobs and data seeding"
  is_after       = qovery_deployment_stage.backend.id
}

# ========================================
# Lifecycle Jobs
# ========================================

# Environment ID Extractor - Runs first to extract environment ID prefix
resource "qovery_job" "env_id_extractor" {
  environment_id = qovery_environment.doktolib.id
  name           = "env-id-extractor"
  icon_uri       = "app://qovery-console/shell"

  # Git repository configuration
  source = {
    docker = {
      git_repository = {
        url       = var.git_repository_url
        branch    = var.git_branch
        root_path = "/lifecycle-jobs/environment-id-extractor"
      }
      dockerfile_path = "Dockerfile"
    }
  }

  # Lifecycle job - runs on environment start
  schedule = {
    on_start = {
      enabled   = true
      arguments = []
    }
    on_stop = {
      enabled   = false
      arguments = []
    }
    on_delete = {
      enabled   = false
      arguments = []
    }
  }

  # Resource configuration
  cpu    = 100   # millicores
  memory = 128   # MB

  # Deployment stage - runs in initialization stage (very first stage)
  deployment_stage_id = qovery_deployment_stage.initialization.id

  # Maximum duration (5 minutes - should complete in seconds)
  max_duration_seconds = 300
  max_nb_restart       = 0  # Don't restart on failure

  # Auto-deploy with environment
  auto_deploy = true

  # Health checks (required for jobs)
  healthchecks = {
    liveness_probe = {
      type = {
        exec = {
          command = ["echo", "ok"]
        }
      }
      initial_delay_seconds = 5
      period_seconds        = 10
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 3
    }
  }
}

# ========================================
# Database
# ========================================

resource "qovery_database" "postgres" {
  count = var.use_managed_database ? 0 : 1

  environment_id = qovery_environment.doktolib.id
  name           = "postgres"
  type           = "POSTGRESQL"
  version        = "17.6"
  mode           = "CONTAINER"  # Use MANAGED for RDS
  storage        = 10           # GB
  accessibility  = "PRIVATE"

  deployment_stage_id = qovery_deployment_stage.database.id
}

# ========================================
# Backend Application (Go + Gin)
# ========================================

resource "qovery_application" "backend" {
  environment_id = qovery_environment.doktolib.id
  name           = "backend"
  icon_uri       = "app://qovery-console/golang"

  # Git repository configuration
  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/backend"
  }

  # Build configuration
  build_mode      = "DOCKER"
  dockerfile_path = "Dockerfile"

  # Deployment configuration
  deployment_stage_id   = qovery_deployment_stage.backend.id
  cpu                   = var.backend_cpu        # in millicores (e.g., 500 = 0.5 CPU)
  memory                = var.backend_memory     # in MB
  min_running_instances = var.backend_min_instances
  max_running_instances = var.backend_max_instances

  # Auto-deploy configuration
  auto_deploy = var.auto_deploy_enabled

  # Port configuration
  ports = [
    {
      internal_port       = 8080
      external_port       = 443
      protocol            = "HTTP"
      publicly_accessible = true
      name                = "api"
    }
  ]

  # Health checks
  healthchecks = {
    liveness_probe = {
      type = {
        http = {
          port   = 8080
          scheme = "HTTP"
          path   = "/api/v1/health"
        }
      }
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 3
    }
    readiness_probe = {
      type = {
        http = {
          port   = 8080
          scheme = "HTTP"
          path   = "/api/v1/health"
        }
      }
      initial_delay_seconds = 5
      period_seconds        = 10
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 3
    }
  }

  # Environment variables
  environment_variables = [
    {
      key   = "PORT"
      value = "8080"
    },
    {
      key   = "GIN_MODE"
      value = var.environment_mode == "PRODUCTION" ? "release" : "debug"
    },
    {
      key   = "CORS_ALLOWED_ORIGINS"
      value = var.cors_allowed_origins
    }
  ]

  # Secret environment variables
  secrets = var.jwt_secret != "" ? [
    {
      key   = "JWT_SECRET"
      value = var.jwt_secret
    }
  ] : []

  # Note: DB_* variables are automatically injected by the managed database
  # via the RDS Aurora terraform service output (database_url)
}

# ========================================
# Frontend Application (Next.js)
# ========================================

resource "qovery_application" "frontend" {
  environment_id = qovery_environment.doktolib.id
  name           = "frontend"
  icon_uri       = "app://qovery-console/nextjs"

  # Git repository configuration
  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/frontend"
  }

  # Build configuration
  build_mode      = "DOCKER"
  dockerfile_path = "Dockerfile"

  # Deployment configuration
  deployment_stage_id   = qovery_deployment_stage.frontend.id
  cpu                   = var.frontend_cpu
  memory                = var.frontend_memory
  min_running_instances = var.frontend_min_instances
  max_running_instances = var.frontend_max_instances

  # Auto-deploy configuration
  auto_deploy = var.auto_deploy_enabled

  # Port configuration
  ports = [
    {
      internal_port       = 3000
      external_port       = 443
      protocol            = "HTTP"
      publicly_accessible = true
      name                = "web"
    }
  ]

  # Health checks
  healthchecks = {
    liveness_probe = {
      type = {
        http = {
          port   = 3000
          scheme = "HTTP"
          path   = "/"
        }
      }
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 3
    }
  }

  # Environment variables
  environment_variables = concat(
    [
      {
        key   = "NODE_ENV"
        value = var.environment_mode == "PRODUCTION" ? "production" : "development"
      },
      {
        key   = "NEXT_PUBLIC_API_URL"
        value = "https://{{BACKEND_HOST_EXTERNAL}}"
      },
      {
        key   = "BACKEND_URL"
        value = "https://{{BACKEND_HOST_EXTERNAL}}"
      }
    ],
    var.visio_health_url != "" ? [
      {
        key   = "NEXT_PUBLIC_VISIO_HEALTH_URL"
        value = var.visio_health_url
      }
    ] : []
  )

  # Reference backend external host via alias
  environment_variable_aliases = [
    {
      key   = "BACKEND_HOST_EXTERNAL"
      value = "QOVERY_APPLICATION_Z${upper(element(split("-", qovery_application.backend.id), 0))}_HOST_EXTERNAL"
    }
  ]
}

# ========================================
# Seed Data Job
# ========================================

resource "qovery_job" "seed_data" {
  count = var.enable_seed_job ? 1 : 0

  environment_id = qovery_environment.doktolib.id
  name           = "seed-data"
  icon_uri       = "app://qovery-console/nodejs"

  # Git repository configuration
  source = {
    docker = {
      git_repository = {
        url       = var.git_repository_url
        branch    = var.git_branch
        root_path = "/seed-data"
      }
      dockerfile_path = "Dockerfile"
    }
  }

  # Job configuration - only enable on_start schedule
  schedule = {
    on_start = {
      enabled   = true
      arguments = []
    }
    on_stop = {
      enabled   = false
      arguments = []
    }
  }

  # Resource configuration
  cpu    = 500   # millicores
  memory = 512   # MB

  # Deployment stage
  deployment_stage_id = qovery_deployment_stage.jobs.id

  # Maximum duration (30 minutes)
  max_duration_seconds = 1800
  max_nb_restart       = 0  # Don't restart on failure

  # Auto-deploy
  auto_deploy = false  # Manual trigger recommended for seed jobs

  # Health checks (required for jobs)
  healthchecks = {
    liveness_probe = {
      type = {
        exec = {
          command = ["echo", "ok"]
        }
      }
      initial_delay_seconds = 5
      period_seconds        = 10
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 3
    }
  }

  # Environment variables
  environment_variables = [
    {
      key   = "NUM_DOCTORS"
      value = var.seed_num_doctors
    },
    {
      key   = "FORCE_SEED"
      value = var.seed_force
    }
  ]

  # Note: DB_* variables are automatically injected by the managed database
  # via the RDS Aurora terraform service output (database_url)
}

# ========================================
# Load Generator (Optional)
# ========================================

resource "qovery_application" "load_generator" {
  count = var.enable_load_generator ? 1 : 0

  environment_id = qovery_environment.doktolib.id
  name           = "load-generator"
  icon_uri       = "app://qovery-console/nodejs"

  # Git repository configuration
  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/load-generator"
  }

  # Build configuration
  build_mode      = "DOCKER"
  dockerfile_path = "Dockerfile"

  # Deployment configuration
  deployment_stage_id   = qovery_deployment_stage.frontend.id
  cpu                   = 500
  memory                = 512
  min_running_instances = 1
  max_running_instances = 1

  # Auto-deploy
  auto_deploy = false

  # Health checks
  healthchecks = {
    liveness_probe = {
      type = {
        exec = {
          command = ["echo", "ok"]
        }
      }
      initial_delay_seconds = 5
      period_seconds        = 30
      timeout_seconds       = 5
      success_threshold     = 1
      failure_threshold     = 5
    }
  }

  # Environment variables
  environment_variables = [
    {
      key   = "LOAD_SCENARIO"
      value = var.load_scenario
    },
    {
      key   = "DURATION"
      value = var.load_duration
    },
    {
      key   = "BACKEND_URL"
      value = "https://{{BACKEND_HOST_EXTERNAL}}"
    }
  ]

  # Reference backend external host via alias
  environment_variable_aliases = [
    {
      key   = "BACKEND_HOST_EXTERNAL"
      value = "QOVERY_APPLICATION_Z${upper(element(split("-", qovery_application.backend.id), 0))}_HOST_EXTERNAL"
    }
  ]
}

# ========================================
# Terraform Services (Infrastructure)
# ========================================

# RDS Aurora Serverless PostgreSQL
resource "qovery_terraform_service" "rds_aurora" {
  count = var.enable_rds_aurora ? 1 : 0

  environment_id      = qovery_environment.doktolib.id
  deployment_stage_id = qovery_deployment_stage.infrastructure.id
  name                = "rds-aurora"
  description         = "AWS RDS Aurora Serverless v2 - PostgreSQL database with auto-scaling"
  icon_uri            = "app://qovery-console/postgresql"

  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/terraform/rds-aurora"
  }

  auto_deploy = true

  # Ensure this deploys after env-id-extractor job completes
  depends_on = [qovery_job.env_id_extractor]

  # Terraform engine configuration (required)
  engine = "TERRAFORM"
  engine_version = {
    explicit_version = "1.13"
  }

  # State backend configuration - using Kubernetes backend
  backend = {
    kubernetes = {}
  }

  # Job resources (required)
  job_resources = {
    cpu    = 500
    memory = 512
  }

  # Variables for Terraform
  variables = [
    {
      key       = "aws_region"
      value     = "{{QOVERY_CLOUD_PROVIDER_REGION}}"
      is_secret = false
    },
    {
      key       = "assume_role_arn"
      value     = var.aws_assume_role_arn
      is_secret = false
    },
    {
      key       = "assume_role_external_id"
      value     = var.aws_assume_role_external_id
      is_secret = true
    },
    {
      key       = "use_default_vpc"
      value     = "false"
      is_secret = false
    },
    {
      key       = "vpc_id"
      value     = "{{QOVERY_KUBERNETES_CLUSTER_VPC_ID}}"
      is_secret = false
    },
    {
      key       = "publicly_accessible"
      value     = "false"
      is_secret = false
    },
    {
      key       = "cluster_name"
      value     = "qovery-{{ENVIRONMENT_ID_FIRST_DIGITS}}-doktolib-aurora"
      is_secret = false
    },
    {
      key       = "tags"
      value     = jsonencode({
        Project        = "Doktolib"
        QoveryProject  = "{{QOVERY_PROJECT_ID}}"
        QoveryEnvironment = "{{QOVERY_ENVIRONMENT_ID}}"
        ManagedBy      = "Terraform"
      })
      is_secret = false
    }
  ]

  # Tfvars files (required - empty list means use environment variables)
  tfvars_files = []
}

# Lambda Visio Health Service
resource "qovery_terraform_service" "lambda_visio" {
  count = var.enable_lambda_visio ? 1 : 0

  environment_id      = qovery_environment.doktolib.id
  deployment_stage_id = qovery_deployment_stage.infrastructure.id
  name                = "lambda-visio"
  description         = "AWS Lambda - Visio conference health check service"
  icon_uri            = "app://qovery-console/lambda"

  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/terraform/visio-service"
  }

  auto_deploy = true

  # Ensure this deploys after env-id-extractor job completes
  depends_on = [qovery_job.env_id_extractor]

  # Terraform engine configuration (required)
  engine = "TERRAFORM"
  engine_version = {
    explicit_version = "1.13"
  }

  # State backend configuration - using Kubernetes backend
  backend = {
    kubernetes = {}
  }

  # Job resources (required)
  job_resources = {
    cpu    = 500
    memory = 512
  }

  # Variables for Terraform
  variables = [
    {
      key       = "aws_region"
      value     = "{{QOVERY_CLOUD_PROVIDER_REGION}}"
      is_secret = false
    },
    {
      key       = "assume_role_arn"
      value     = var.aws_assume_role_arn
      is_secret = false
    },
    {
      key       = "assume_role_external_id"
      value     = var.aws_assume_role_external_id
      is_secret = true
    },
    {
      key       = "function_name"
      value     = "qovery-{{ENVIRONMENT_ID_FIRST_DIGITS}}-doktolib-visio-health"
      is_secret = false
    },
    {
      key       = "tags"
      value     = jsonencode({
        Project        = "Doktolib"
        QoveryProject  = "{{QOVERY_PROJECT_ID}}"
        QoveryEnvironment = "{{QOVERY_ENVIRONMENT_ID}}"
        ManagedBy      = "Terraform"
      })
      is_secret = false
    }
  ]

  # Tfvars files (required - empty list means use environment variables)
  tfvars_files = []
}

# Cloudflare CDN
resource "qovery_terraform_service" "cloudflare_cdn" {
  count = var.enable_cloudflare_cdn && var.cloudflare_domain_name != "" ? 1 : 0

  environment_id      = qovery_environment.doktolib.id
  deployment_stage_id = qovery_deployment_stage.infrastructure.id
  name                = "cloudflare-cdn"
  description         = "Cloudflare CDN - Frontend edge caching and DDoS protection"
  icon_uri            = "app://qovery-console/cloudflare"

  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/terraform/cloudflare-cdn"
  }

  auto_deploy = true

  # Terraform engine configuration (required)
  engine = "TERRAFORM"
  engine_version = {
    explicit_version = "1.13"
  }

  # State backend configuration - using Kubernetes backend
  backend = {
    kubernetes = {}
  }

  # Ensure this deploys after env-id-extractor job completes
  depends_on = [qovery_job.env_id_extractor]

  # Job resources (required)
  job_resources = {
    cpu    = 500
    memory = 512
  }

  # Variables for Terraform
  variables = [
    {
      key       = "tags"
      value     = jsonencode({
        Project        = "Doktolib"
        QoveryProject  = "{{QOVERY_PROJECT_ID}}"
        QoveryEnvironment = "{{QOVERY_ENVIRONMENT_ID}}"
        ManagedBy      = "Terraform"
      })
      is_secret = false
    }
  ]

  # Tfvars files (required - empty list means use environment variables)
  tfvars_files = []
}

# S3 Bucket for Medical Files
resource "qovery_terraform_service" "s3_bucket" {
  count = var.enable_s3_bucket ? 1 : 0

  environment_id      = qovery_environment.doktolib.id
  deployment_stage_id = qovery_deployment_stage.infrastructure.id
  name                = "s3-bucket"
  description         = "AWS S3 - Medical files storage with encryption and versioning"
  icon_uri            = "app://qovery-console/s3"

  git_repository = {
    url       = var.git_repository_url
    branch    = var.git_branch
    root_path = "/terraform/s3-bucket"
  }

  auto_deploy = true

  # Ensure this deploys after env-id-extractor job completes
  depends_on = [qovery_job.env_id_extractor]

  # Terraform engine configuration (required)
  engine = "TERRAFORM"
  engine_version = {
    explicit_version = "1.13"
  }

  # State backend configuration - using Kubernetes backend
  backend = {
    kubernetes = {}
  }

  # Job resources (required)
  job_resources = {
    cpu    = 500
    memory = 512
  }

  # Variables for Terraform
  variables = [
    {
      key       = "aws_region"
      value     = "{{QOVERY_CLOUD_PROVIDER_REGION}}"
      is_secret = false
    },
    {
      key       = "assume_role_arn"
      value     = var.aws_assume_role_arn
      is_secret = false
    },
    {
      key       = "assume_role_external_id"
      value     = var.aws_assume_role_external_id
      is_secret = true
    },
    {
      key       = "bucket_name"
      value     = "qovery-{{ENVIRONMENT_ID_FIRST_DIGITS}}-doktolib-medical-files"
      is_secret = false
    }
  ]

  # Tfvars files (required - empty list means use environment variables)
  tfvars_files = []
}

# ========================================
# Data Sources
# ========================================

# Load Windmill Helm values from file
data "local_file" "windmill_values" {
  filename = "${path.module}/windmill-values.yaml"
}

# ========================================
# Helm Repositories
# ========================================

# Windmill Helm Repository
resource "qovery_helm_repository" "windmill" {
  count = var.enable_windmill ? 1 : 0

  organization_id = var.qovery_organization_id
  name            = "windmill"
  description     = "Windmill Labs Helm Charts Repository"
  kind            = "HTTPS"
  url             = "https://windmill-labs.github.io/windmill-helm-charts/"

  # Skip TLS verification if needed
  skip_tls_verification = false
}

# ========================================
# Helm Charts
# ========================================

# Windmill - Background Processing Service
resource "qovery_helm" "windmill" {
  count = var.enable_windmill ? 1 : 0

  environment_id      = qovery_environment.doktolib.id
  deployment_stage_id = qovery_deployment_stage.backend.id
  name                = "background-processing"
  description         = "Windmill workflow engine for background job processing"
  icon_uri            = "app://qovery-console/windmill"

  # Allow cluster-wide resources (needed for some CRDs)
  allow_cluster_wide_resources = false

  # Windmill Helm chart repository
  source = {
    helm_repository = {
      helm_repository_id = qovery_helm_repository.windmill[0].id
      chart_name         = "windmill"
      chart_version      = "4.0.10"
    }
  }

  # Auto-deploy configuration
  auto_deploy = true
  timeout_sec = 600  # 10 minutes for initial deployment

  # Helm values configuration - load from windmill-values.yaml
  values_override = {
    file = {
      raw = {
        file1 = {
          content = data.local_file.windmill_values.content
        }
      }
    }
  }

  # Port configuration for Windmill UI (map format)
  ports = {
    "web-ui" = {
      service_name        = "windmill"
      namespace           = null
      internal_port       = 8000
      external_port       = 443
      protocol            = "HTTP"
      publicly_accessible = true
      is_default          = false
    }
  }

  # Environment variables
  environment_variables = []

  # Note: DATABASE_CONNECTION_URL will be injected by RDS Aurora terraform service
  # The helm chart will automatically receive the RDS Aurora output if it's enabled
}
