# Doktolib Load Generator

A Node.js service that simulates realistic user traffic on the Doktolib API to test performance, scalability, and system behavior under different load conditions.

## Features

🎭 **Realistic User Behavior**
- Simulates actual user journeys (search → view doctor → book appointment)
- Weighted request patterns based on real usage scenarios
- Random delays between actions to mimic human behavior

📊 **Multiple Load Scenarios**
- **Light**: 15 concurrent users, 30 req/min (development testing)
- **Normal**: 75 concurrent users, 150 req/min (typical production load)
- **Heavy**: 250 concurrent users, 500 req/min (peak hours simulation)
- **Stress**: 500 concurrent users, 1000 req/min (maximum load testing)

📈 **Comprehensive Statistics**
- Real-time request rates and success rates
- Response time percentiles (P50, P95, P99)
- Per-endpoint performance breakdown
- Error tracking and categorization

## Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Run with default (normal) scenario
npm start

# Run specific scenarios
npm run light    # Light load
npm run normal   # Normal load  
npm run heavy    # Heavy load
npm run stress   # Stress test
```

### Docker

```bash
# Build the image
docker build -t doktolib-load-generator .

# Run with environment variables
docker run -e API_URL=http://backend:8080 -e SCENARIO=normal doktolib-load-generator

# Run stress test for 30 minutes
docker run -e API_URL=http://backend:8080 -e SCENARIO=stress -e DURATION_MINUTES=30 doktolib-load-generator
```

### Docker Compose Integration

Add to your `docker-compose.yml`:

```yaml
load-generator:
  build: ./load-generator
  environment:
    - API_URL=http://backend:8080
    - SCENARIO=normal
    - DURATION_MINUTES=60
    - LOG_LEVEL=info
  depends_on:
    - backend
  profiles:
    - loadtest
```

Run with: `docker compose --profile loadtest up`

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `API_URL` | `http://localhost:8080` | Target API base URL |
| `SCENARIO` | `normal` | Load scenario (light/normal/heavy/stress) |
| `DURATION_MINUTES` | `60` | How long to run the test |
| `LOG_LEVEL` | `info` | Logging level (debug/info/warn/error) |

### Load Scenarios

#### Light Load
- **Use case**: Development testing, CI/CD pipelines
- **Users**: 15 concurrent
- **Rate**: 30 requests/minute
- **Appointment rate**: 10% of sessions

#### Normal Load  
- **Use case**: Typical production traffic simulation
- **Users**: 75 concurrent  
- **Rate**: 150 requests/minute
- **Appointment rate**: 15% of sessions

#### Heavy Load
- **Use case**: Peak hours, marketing campaign traffic
- **Users**: 250 concurrent
- **Rate**: 500 requests/minute  
- **Appointment rate**: 20% of sessions

#### Stress Test
- **Use case**: Maximum capacity testing, failure scenarios
- **Users**: 500 concurrent
- **Rate**: 1000 requests/minute
- **Appointment rate**: 25% of sessions

## User Behavior Simulation

The load generator simulates realistic user journeys:

### 1. Search Patterns (70% of sessions)
- Search by specialty and location
- Search by specialty only
- Search by location only  
- Browse all doctors

### 2. Doctor Details (40% of sessions)
- View individual doctor profiles
- Check availability and ratings
- Read doctor information

### 3. Appointment Booking (10-25% based on scenario)
- Generate realistic patient data
- Book future appointments (1-14 days ahead)
- Choose realistic appointment durations

### 4. Health Checks (1% of requests)
- Monitor API health status
- Simulate monitoring tools

## API Endpoints Tested

- `GET /api/v1/health` - Health checks
- `GET /api/v1/doctors` - Doctor listings with filters  
- `GET /api/v1/doctors/:id` - Individual doctor details
- `POST /api/v1/appointments` - Appointment bookings

## Statistics & Monitoring

### Real-time Output
```
📊 LOAD GENERATION STATISTICS
==================================================
⏱️  Runtime: 5.2 minutes
📈 Request Rate: 147.3 req/min
✅ Success Rate: 98.7% (765/775)
❌ Failed Requests: 10

🚀 RESPONSE TIMES:
Average: 142ms
P50: 89ms | P95: 267ms | P99: 445ms

🎯 ENDPOINT BREAKDOWN:
/api/v1/doctors: 423 req, 99.3% success, 95ms avg
/api/v1/doctors/:id: 187 req, 98.9% success, 134ms avg  
/api/v1/appointments: 145 req, 97.2% success, 256ms avg
/api/v1/health: 20 req, 100.0% success, 23ms avg
```

### Key Metrics
- **Request Rate**: Requests per minute
- **Success Rate**: Percentage of successful responses
- **Response Times**: P50, P95, P99 percentiles
- **Error Breakdown**: Types and frequency of errors
- **Endpoint Performance**: Per-endpoint statistics

## Production Usage

### Performance Testing
```bash
# Test API under normal load
docker run -e API_URL=https://your-api.com -e SCENARIO=normal doktolib-load-generator

# Stress test for capacity planning
docker run -e API_URL=https://your-api.com -e SCENARIO=stress -e DURATION_MINUTES=30 doktolib-load-generator
```

### CI/CD Integration
```yaml
# .github/workflows/load-test.yml
- name: Run Load Test
  run: |
    docker compose --profile loadtest up --abort-on-container-exit
    docker compose logs load-generator > load-test-results.txt
```

### Monitoring Integration
- Combine with Prometheus/Grafana for metrics visualization
- Use with APM tools like New Relic or DataDog
- Integrate with alerting systems for performance regression detection

## Safety Features

- **Gradual Ramp-up**: Workers start with random delays
- **Circuit Breaker**: Automatic backoff on persistent errors
- **Resource Limits**: Configurable concurrency and rate limits
- **Graceful Shutdown**: SIGINT/SIGTERM handling with statistics summary

## Best Practices

1. **Start Small**: Begin with light load and gradually increase
2. **Monitor Resources**: Watch CPU, memory, and network on both client and server
3. **Use Realistic Data**: The generator uses faker.js for realistic test data
4. **Test Different Scenarios**: Run various load patterns to identify bottlenecks
5. **Baseline First**: Establish performance baseline before optimization

## Troubleshooting

### Common Issues

**Connection Errors**
```bash
# Verify API connectivity
curl http://your-api-url/api/v1/health
```

**High Error Rates**
- Check server resources (CPU, memory, database connections)
- Verify database performance and connection pooling
- Monitor network latency and bandwidth

**Inconsistent Results**
- Run tests for sufficient duration (minimum 5-10 minutes)
- Ensure consistent test environment
- Account for warm-up time

## Contributing

This load generator is designed to be easily extensible:

- Add new user behavior patterns
- Create custom load scenarios
- Implement additional statistics
- Add support for authentication
- Integrate with monitoring tools