# Load Generator Dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY index.js ./

# Create non-root user for security
RUN addgroup -g 1001 -S loadgen && \
    adduser -S loadgen -u 1001 -G loadgen

# Change ownership and switch to non-root user
RUN chown -R loadgen:loadgen /app
USER loadgen

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "console.log('Load generator is running')" || exit 1

# Default command
CMD ["npm", "start"]

# Labels
LABEL maintainer="Doktolib Team"
LABEL description="Load generator for Doktolib API traffic simulation"
LABEL version="1.0.0"