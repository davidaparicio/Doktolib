# Doktolib Seed Data

This directory contains tools to generate and inject realistic fake doctor data into the Doktolib database.


## 🎯 Purpose

- Generate 1500+ realistic French doctors with diverse specialties
- Populate database for demo and testing purposes
- Support Qovery lifecycle jobs for automated seeding
- Provide local testing capabilities

## 📁 Files

- `generate-doctors.js` - Generates fake doctor data with realistic French names and medical specialties
- `seed.js` - Injects generated data into PostgreSQL database
- `package.json` - Node.js dependencies and scripts
- `Dockerfile` - Container for Qovery lifecycle job
- `test-local.sh` - Local testing script

## 🚀 Usage

### Local Testing

```bash
# Install dependencies
npm install

# Generate test data (50 doctors)
node generate-doctors.js 50

# Test with database
DATABASE_URL="postgres://user:pass@localhost:5432/doktolib" npm run seed

# Force seed (clear existing data)
DATABASE_URL="postgres://user:pass@localhost:5432/doktolib" npm run seed-force
```

### With Docker

```bash
# Build container
docker build -t doktolib-seed .

# Run seeding
docker run --rm \
  -e DATABASE_URL="postgres://user:pass@host:5432/doktolib" \
  -e DB_SSL_MODE="disable" \
  -e DOCTOR_COUNT="1500" \
  doktolib-seed
```

### With Qovery

The Terraform configuration automatically creates a lifecycle job that:
1. Builds the seed container from this directory
2. Runs after the database is ready
3. Injects the configured number of doctors
4. Uses environment variables for configuration

## 🔧 Configuration

### Environment Variables

- `DATABASE_URL` - PostgreSQL connection string (required)
- `DB_SSL_MODE` - SSL mode (disable/require/verify-ca/verify-full)
- `DOCTOR_COUNT` - Number of doctors to generate (default: 1500)
- `FORCE_SEED` - Force seeding even if data exists (default: false)

### Terraform Variables

```hcl
seed_doctor_count = 1500  # Number of doctors to generate
force_seed = false        # Force seed even if data exists
db_ssl_mode = "disable"   # Database SSL mode
```

## 📊 Generated Data

### Doctor Attributes
- **Names**: Realistic French first and last names
- **Specialties**: 35+ medical specialties (généraliste, cardiologue, etc.)
- **Locations**: Paris districts and nearby cities
- **Ratings**: 3.0-5.0 (weighted toward higher ratings)
- **Prices**: €50-200 (specialists cost more)
- **Experience**: 3-40 years
- **Languages**: French combinations with other languages
- **Avatars**: Professional photos from Unsplash

### Statistics (1500 doctors)
- 35+ medical specialties
- 40+ locations in Paris region
- Average rating: ~4.5/5
- Average price: ~€95/hour
- Average experience: ~22 years
- Gender distribution: 60% women, 40% men

## 🧪 Sample Data

```json
{
  "id": 1,
  "name": "Dr. Marie Dubois",
  "specialty": "Médecin généraliste",
  "location": "Paris 1er",
  "rating": 4.8,
  "price_per_hour": 60,
  "avatar": "https://images.unsplash.com/photo-1559839734-2b71ea197ec2",
  "experience_years": 15,
  "languages": "Français, Anglais"
}
```

## 🔍 Database Schema

The seeder expects this table structure:

```sql
CREATE TABLE doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    specialty VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.0,
    price_per_hour INTEGER DEFAULT 0,
    avatar TEXT,
    experience_years INTEGER DEFAULT 0,
    languages TEXT DEFAULT 'French',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🛡️ Safety Features

- **Non-destructive by default**: Won't overwrite existing data unless forced
- **Batch processing**: Inserts in batches of 100 for better performance
- **Connection retries**: Handles temporary database unavailability
- **Validation**: Ensures data quality and constraints
- **Indexes**: Creates performance indexes automatically
- **Statistics**: Reports on inserted data

## 🚨 Troubleshooting

### SSL Connection Issues

If you see `The server does not support SSL connections`:
```bash
# Disable SSL for local development or non-SSL databases
export DB_SSL_MODE="disable"
npm run seed
```

If you see `SSL connection has been closed unexpectedly`:
```bash
# Use require mode (SSL without certificate verification)
export DB_SSL_MODE="require"
npm run seed
```

### Connection Issues
```bash
# Check database connectivity
psql "$DATABASE_URL" -c "SELECT 1"

# Test all SSL modes automatically
DATABASE_URL="your-database-url" npm run test-ssl

# Test different SSL modes manually
export DB_SSL_MODE="disable"    # No SSL
export DB_SSL_MODE="require"    # SSL without verification
export DB_SSL_MODE="verify-ca"  # SSL with CA verification
export DB_SSL_MODE="verify-full" # Full SSL verification
```

### SSL Mode Reference
- **`disable`**: No SSL connection (default for local development)
- **`require`**: SSL connection required, but no certificate verification
- **`verify-ca`**: SSL connection required, verify certificate authority
- **`verify-full`**: SSL connection required, verify certificate authority and hostname

### Force Re-seeding
```bash
export FORCE_SEED="true"
npm run seed
```

### Docker Issues
```bash
# Check container logs
docker logs <container-id>

# Run interactively for debugging
docker run -it --rm doktolib-seed /bin/sh
```

## 📈 Performance

- **Generation**: ~1500 doctors in <5 seconds
- **Database insertion**: ~1500 doctors in ~30 seconds
- **Memory usage**: <100MB
- **CPU usage**: Minimal (optimized for batch processing)

Perfect for development, testing, and demo environments! 🎉
