# Sample Node.js Application

This is a minimal Node.js/Express application for the Terraform Training Module 02.

## Features

- Simple Express.js web server
- Displays "Hi, this is your Terraform training" message
- Shows deployment environment and Node.js version
- Health check endpoint for Azure monitoring
- API endpoint for programmatic access

## Endpoints

| Endpoint        | Description                        |
| --------------- | ---------------------------------- |
| `GET /`         | Welcome page with training message |
| `GET /health`   | Health check (JSON response)       |
| `GET /api/info` | API info endpoint (JSON response)  |

## Local Development

```bash
# Install dependencies
npm install

# Run the server
npm start

# Server runs on http://localhost:8080
```

## Deployment

This app is designed to be deployed to Azure App Service via:

1. **Terraform** (optional): Set `deploy_sample_app = true` in your tfvars
2. **Azure CLI**: Manual deployment using `az webapp deploy`
3. **CI/CD**: GitHub Actions or Azure DevOps pipelines (recommended for production)

### Manual Deployment

```powershell
# Zip the app
Compress-Archive -Path * -DestinationPath ../app.zip -Force

# Deploy to Azure
az webapp deploy `
  --resource-group "rg-tftraining-dev" `
  --name "tftraining-webapp-dev" `
  --src-path "../app.zip" `
  --type zip
```

## Environment Variables

The app reads these environment variables (set in App Service):

| Variable  | Description                | Default     |
| --------- | -------------------------- | ----------- |
| `PORT`    | Server port (set by Azure) | 8080        |
| `APP_ENV` | Environment name           | development |

## Security Notes

- Never commit secrets to this file
- Use Azure Key Vault for sensitive configuration
- Use Managed Identity for Azure service access
