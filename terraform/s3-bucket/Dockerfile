# Terraform lifecycle job for S3 bucket creation
# This container will be used by Qovery as a lifecycle job to create the S3 bucket

FROM hashicorp/terraform:1.6.6

# Install additional tools for lifecycle job
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    aws-cli

# Set working directory
WORKDIR /terraform

# Copy Terraform configuration files
COPY main.tf variables.tf outputs.tf ./

# Create entrypoint script
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Create validation script
RUN echo '#!/bin/bash' > validate.sh && \
    echo 'echo "🔍 Validating Terraform configuration..."' >> validate.sh && \
    echo 'terraform validate' >> validate.sh && \
    echo 'if [ $? -eq 0 ]; then' >> validate.sh && \
    echo '  echo "✅ Terraform configuration is valid"' >> validate.sh && \
    echo 'else' >> validate.sh && \
    echo '  echo "❌ Terraform configuration is invalid"' >> validate.sh && \
    echo '  exit 1' >> validate.sh && \
    echo 'fi' >> validate.sh && \
    chmod +x validate.sh

# Create destroy script for cleanup
RUN echo '#!/bin/bash' > destroy.sh && \
    echo 'echo "🗑️  Destroying S3 bucket infrastructure..."' >> destroy.sh && \
    echo 'terraform init' >> destroy.sh && \
    echo 'terraform destroy -auto-approve' >> destroy.sh && \
    echo 'if [ $? -eq 0 ]; then' >> destroy.sh && \
    echo '  echo "✅ S3 bucket infrastructure destroyed successfully"' >> destroy.sh && \
    echo 'else' >> destroy.sh && \
    echo '  echo "❌ Failed to destroy S3 bucket infrastructure"' >> destroy.sh && \
    echo '  exit 1' >> destroy.sh && \
    echo 'fi' >> destroy.sh && \
    chmod +x destroy.sh

# Set entrypoint
ENTRYPOINT ["./entrypoint.sh"]

# Default command is to apply
CMD ["apply"]