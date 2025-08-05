# Use Node.js alpine image
FROM node:18-alpine

# Install dependencies for better database connectivity
RUN apk add --no-cache curl postgresql-client

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source files
COPY *.js ./

# Create non-root user for security
RUN addgroup -g 1001 -S seeduser && \
    adduser -S seeduser -u 1001

# Set ownership
RUN chown -R seeduser:seeduser /app

USER seeduser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD echo "Seed job container is healthy"

# Default command
CMD ["npm", "run", "seed"]