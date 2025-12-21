FROM alpine:3.19

# Install bash for script execution
RUN apk add --no-cache bash

# Copy the extraction script
COPY extract-env-id.sh /extract-env-id.sh

# Make script executable
RUN chmod +x /extract-env-id.sh

# Run the script
CMD ["/extract-env-id.sh"]
