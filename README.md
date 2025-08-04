# Doktolib - Doctor Appointment Booking Platform

A modern Doctolib clone built to showcase Qovery's powerful deployment and DevOps capabilities. This project demonstrates how to build and deploy a production-ready application with microservices architecture.

![Doktolib Screenshot](https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop)

## 🏗️ Architecture

### Services
- **Frontend**: Next.js 14 with TypeScript and Tailwind CSS
- **Backend**: Go with Gin framework and PostgreSQL
- **Database**: PostgreSQL 15 with sample data
- **Infrastructure**: Deployed on Qovery with Terraform

### Key Features
- 📱 Responsive Doctolib-style UI
- 👨‍⚕️ Doctor listing with search and filters
- 📅 Appointment booking system
- 🏥 Doctor profiles with ratings and availability
- 🔍 Real-time search by specialty and location
- 📊 Health checks and monitoring
- 🚀 Auto-deployment with GitOps

## 🚀 Quick Start

### Local Development

#### Option 1: Quick Start Script (Recommended)
```bash
git clone <your-repo-url>
cd doktolib
./run-local.sh
```

This script will:
- Build the backend binary
- Start PostgreSQL with Docker
- Start the backend and frontend
- Run health checks
- Provide URLs for testing

#### Option 2: Manual Setup

1. **Prerequisites**:
   ```bash
   # Install Go 1.21+, Node.js 18+, and Docker
   ```

2. **Start Database**:
   ```bash
   docker compose -f docker-compose.simple.yml up -d
   ```

3. **Start Backend**:
   ```bash
   cd backend
   export DATABASE_URL="postgres://doktolib:password123@localhost:5432/doktolib"
   export DB_SSL_MODE="disable"
   go run .
   ```

4. **Start Frontend** (in another terminal):
   ```bash
   cd frontend
   npm install
   export NEXT_PUBLIC_API_URL="http://localhost:8080"
   npm run dev
   ```

5. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080/api/v1
   - Database: localhost:5432

#### Option 3: Full Docker Compose
```bash
docker compose up --build
```
*Note: Docker builds may take time depending on network speed*

### Production Deployment with Qovery

1. **Setup Terraform variables**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your Qovery credentials
   ```

2. **Deploy to Qovery**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access your deployed application** via the URLs provided in Terraform outputs.

## 🏥 Demo Features

### For Patients
- **Search Doctors**: Find doctors by specialty, location, and rating
- **View Profiles**: See doctor details, experience, and availability  
- **Book Appointments**: Select date/time and book appointments online
- **Responsive Design**: Works perfectly on desktop and mobile

### For DevOps Engineers
- **Container-First**: Both services are containerized with optimized Dockerfiles
- **Health Checks**: Kubernetes-ready health endpoints
- **Environment Management**: Easy configuration via environment variables
- **Monitoring Ready**: Structured logging and metrics endpoints
- **Auto-Scaling Ready**: Stateless design with external database

## 🛠️ Technology Stack

### Frontend
- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Icons**: Heroicons
- **HTTP Client**: Axios
- **Notifications**: React Hot Toast

### Backend  
- **Language**: Go 1.21
- **Framework**: Gin (HTTP router)
- **Database**: PostgreSQL with native driver
- **Migrations**: SQL-based migrations
- **CORS**: Enabled for frontend integration
- **Health Checks**: Built-in health endpoints

### Infrastructure
- **Containerization**: Docker multi-stage builds
- **Orchestration**: Qovery (Kubernetes abstraction)
- **Database**: Managed PostgreSQL
- **SSL/TLS**: Automatic Let's Encrypt certificates
- **CI/CD**: GitOps-based auto-deployment

## 📊 API Endpoints

### Doctors
- `GET /api/v1/doctors` - List all doctors with optional filters
- `GET /api/v1/doctors/:id` - Get doctor details

### Appointments  
- `POST /api/v1/appointments` - Create new appointment
- `GET /api/v1/appointments` - List appointments (with optional doctor filter)

### Health
- `GET /api/v1/health` - Health check endpoint

## 🗄️ Database Schema

### Doctors Table
```sql
- id (UUID, Primary Key)
- name (VARCHAR)
- specialty (VARCHAR) 
- location (VARCHAR)
- rating (DECIMAL)
- price_per_hour (INTEGER)
- avatar (TEXT)
- experience_years (INTEGER)
- languages (TEXT)
```

### Appointments Table
```sql
- id (UUID, Primary Key)
- doctor_id (UUID, Foreign Key)
- patient_name (VARCHAR)
- patient_email (VARCHAR)
- date_time (TIMESTAMP)
- duration_minutes (INTEGER)
- status (VARCHAR)
```

## 🔧 Configuration

### Environment Variables

#### Backend
- `DATABASE_URL`: PostgreSQL connection string
- `DB_SSL_MODE`: SSL mode for database connection (disable/require/verify-ca/verify-full, default: disable)
- `DB_SSL_CERT`: Path to SSL client certificate (optional)
- `DB_SSL_KEY`: Path to SSL client key (optional)
- `DB_SSL_ROOT_CERT`: Path to SSL root certificate (optional)
- `PORT`: Server port (default: 8080)
- `GIN_MODE`: Gin mode (release/debug)

#### Frontend
- `NEXT_PUBLIC_API_URL`: Backend API URL
- `PORT`: Frontend port (default: 3000)
- `NODE_ENV`: Node environment

## 🐳 Docker Configuration

### Backend Dockerfile
- Multi-stage build for optimized size
- Non-root user for security
- Health checks included
- Alpine-based for minimal footprint

### Frontend Dockerfile  
- Next.js standalone output for efficiency
- Static asset optimization
- Security-focused user management
- Production-ready configuration

## ☁️ Qovery Deployment

### What Qovery Provides
- **Simplified Kubernetes**: No YAML complexity
- **Auto-Scaling**: Horizontal pod autoscaling
- **SSL Certificates**: Automatic HTTPS with Let's Encrypt
- **Database Management**: Managed PostgreSQL with backups
- **Environment Management**: Multiple environments (dev, staging, prod)
- **GitOps CI/CD**: Auto-deploy on git push
- **Monitoring**: Built-in application monitoring
- **Security**: Network policies and secrets management

### Terraform Resources Created
- Qovery Project and Environment
- PostgreSQL Database (managed)
- Backend Application (containerized)
- Frontend Application (containerized) 
- Custom Domain (optional)
- SSL Certificates
- Health Checks and Probes

## 🚀 Why This Showcases Qovery's Power

### For DevOps Engineers
1. **No Kubernetes YAML**: Deploy complex apps without writing manifests
2. **Database Management**: Automatic backups, monitoring, and scaling
3. **GitOps Integration**: Push to git, auto-deploy to production
4. **Multi-Environment**: Easy staging and production environments
5. **Security Built-in**: Network policies, secrets management, SSL
6. **Monitoring Included**: APM, logs, and metrics out-of-the-box

### Compared to Traditional DevOps
- **Kubernetes**: Hundreds of lines of YAML → ~100 lines of Terraform
- **Database Setup**: Manual RDS/CloudSQL setup → One resource block
- **SSL Certificates**: Manual cert-manager setup → Automatic
- **Monitoring**: Complex Prometheus setup → Built-in dashboards
- **CI/CD**: Complex Jenkins/GitHub Actions → GitOps auto-deploy

## 🎯 Demo Script for Presentations

1. **Show the Application**: Live demo of doctor search and booking
2. **Code Walkthrough**: Simple, clean code structure
3. **Terraform Configuration**: How easy it is to deploy
4. **Qovery Console**: Show the beautiful UI and monitoring
5. **GitOps Demo**: Push code and watch it auto-deploy
6. **Environment Management**: Create staging environment
7. **Database Management**: Show backups and monitoring
8. **Cost Optimization**: Show resource usage and scaling

## 🔧 Database SSL Configuration

The application supports flexible SSL configuration for PostgreSQL connections:

### SSL Modes
- **`disable`** (default): No SSL connection
- **`require`**: SSL connection required, but no certificate verification
- **`verify-ca`**: SSL connection required, verify certificate authority
- **`verify-full`**: SSL connection required, verify certificate authority and hostname

### Configuration Examples

#### Local Development (No SSL)
```bash
export DB_SSL_MODE=disable
```

#### Production with SSL
```bash
export DB_SSL_MODE=require
# or for stricter verification:
export DB_SSL_MODE=verify-full
export DB_SSL_ROOT_CERT=/path/to/ca-cert.pem
```

#### Qovery Deployment
In Terraform, set the SSL mode:
```hcl
db_ssl_mode = "require"  # or "disable" for development
```

### Troubleshooting SSL Issues

If you encounter `SSL is not enabled on the server`:
1. Set `DB_SSL_MODE=disable` for development/testing
2. For production, ensure your PostgreSQL server supports SSL
3. Use `require` mode if you need SSL but don't have certificates

## 📈 Production Readiness

### What's Included
- ✅ Health checks and readiness probes
- ✅ Structured logging
- ✅ Error handling and validation
- ✅ Database connection pooling
- ✅ CORS configuration
- ✅ Security headers
- ✅ Container security (non-root user)
- ✅ Resource limits and requests
- ✅ Database migrations
- ✅ Environment-specific configurations

### What Could Be Added
- 🔄 Redis for caching and sessions
- 📧 Email notifications for appointments
- 📱 SMS notifications
- 🔍 Full-text search with Elasticsearch
- 📊 Analytics and metrics collection
- 🔐 OAuth authentication
- 📄 PDF appointment confirmations
- 🌍 Multi-language support

## 🤝 Contributing

This is a demo project to showcase Qovery's capabilities. Feel free to fork and extend it with additional features to demonstrate more Qovery functionality.

## 📞 Support

For Qovery-related questions:
- 📖 [Qovery Documentation](https://hub.qovery.com/docs/)
- 💬 [Qovery Community](https://discuss.qovery.com/)
- 🐦 [Twitter](https://twitter.com/qovery_io)

---

**Built with ❤️ to showcase the power and simplicity of Qovery for DevOps Engineers**