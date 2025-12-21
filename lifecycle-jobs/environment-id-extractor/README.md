# Environment ID Extractor - Lifecycle Job

This lifecycle job extracts the first 8 characters from the Qovery environment ID and makes it available as an environment variable to all services in the environment.

## Purpose

When deploying AWS resources (RDS Aurora, Lambda, S3), we need unique resource names per environment to support environment cloning. This job extracts the environment ID prefix and shares it with all terraform services.

## How It Works

1. **Reads** the `QOVERY_ENVIRONMENT_ID` environment variable (automatically injected by Qovery)
2. **Extracts** the first 8 characters (e.g., `76916317` from `76916317-c11a-469e-9314-0e2835460f53`)
3. **Writes** to `/qovery-output/qovery-output.json` in the format:
   ```json
   {
     "ENVIRONMENT_ID_FIRST_DIGITS": {
       "sensitive": false,
       "value": "76916317"
     }
   }
   ```
4. **Makes available** the `ENVIRONMENT_ID_FIRST_DIGITS` variable to all services via `{{ENVIRONMENT_ID_FIRST_DIGITS}}`

## Usage in Terraform Services

After this job runs, all terraform services can reference the variable:

```hcl
variables = [
  {
    key       = "cluster_name"
    value     = "qovery-{{ENVIRONMENT_ID_FIRST_DIGITS}}-doktolib-aurora"
    is_secret = false
  }
]
```

## Configuration in Qovery

This job should be configured as a **lifecycle job** in the **database deployment stage** with:
- **Event**: `START` (runs when environment starts)
- **Order**: Before terraform services
- **Schedule**: On environment start only

## Files

- `extract-env-id.sh` - Bash script that extracts the environment ID
- `Dockerfile` - Container image definition
- `README.md` - This file

## Example Output

```
Environment ID: 76916317-c11a-469e-9314-0e2835460f53
First 8 digits: 76916317
Successfully wrote ENVIRONMENT_ID_FIRST_DIGITS to /qovery-output/qovery-output.json
{
  "ENVIRONMENT_ID_FIRST_DIGITS": {
    "sensitive": false,
    "value": "76916317"
  }
}
```

## Benefits

✅ **DRY Principle**: Extract environment ID once, use everywhere
✅ **Environment Cloning**: Each clone gets unique AWS resource names
✅ **Qovery Native**: Uses Qovery's lifecycle job mechanism
✅ **Simple & Reliable**: Minimal bash script, no dependencies
