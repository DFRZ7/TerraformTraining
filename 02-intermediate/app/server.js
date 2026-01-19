/**
 * Terraform Training - Sample Node.js Application
 * 
 * This is a minimal Express.js server that displays a welcome message.
 * It's designed to be deployed to Azure App Service as part of Module 02.
 * 
 * The app reads configuration from environment variables set in App Service.
 */

const express = require('express');
const app = express();

// Port configuration - Azure App Service sets the PORT environment variable
const PORT = process.env.PORT || 8080;

// Environment information from App Service
const environment = process.env.APP_ENV || 'development';
const nodeVersion = process.version;

// HTML template for the welcome page
const welcomeHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Training - Azure App Service</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            max-width: 600px;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .emoji {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        .message {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            opacity: 0.95;
        }
        .info {
            background: rgba(255, 255, 255, 0.2);
            padding: 1rem;
            border-radius: 10px;
            margin-top: 1rem;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 0.5rem 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .label {
            font-weight: bold;
            opacity: 0.8;
        }
        .terraform-logo {
            font-size: 3rem;
            margin: 1rem 0;
        }
        footer {
            margin-top: 2rem;
            font-size: 0.9rem;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🎉</div>
        <h1>Hi, this is your Terraform training</h1>
        <p class="message">
            Congratulations! You've successfully deployed an Azure App Service using Terraform modules and remote state.
        </p>
        <div class="terraform-logo">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
                <path fill="#7B42BC" d="M23.5 10L0 23.5v27l23.5 13.5V37L47 23.5 23.5 10z"/>
                <path fill="#4040B2" d="M23.5 10v27l23.5 13.5V23.5L23.5 10z"/>
                <path fill="#5C4EE5" d="M47 50.5L23.5 37v27L47 77.5v-27z"/>
                <path fill="#7B42BC" d="M64 23.5L40.5 10v27L64 50.5v-27z"/>
            </svg>
        </div>
        <div class="info">
            <div class="info-item">
                <span class="label">Environment</span>
                <span>${environment}</span>
            </div>
            <div class="info-item">
                <span class="label">Node.js Version</span>
                <span>${nodeVersion}</span>
            </div>
            <div class="info-item">
                <span class="label">Server Time</span>
                <span>${new Date().toISOString()}</span>
            </div>
            <div class="info-item">
                <span class="label">Module</span>
                <span>02 - Remote State & Modules</span>
            </div>
        </div>
        <footer>
            Terraform Training Program • Powered by Azure App Service
        </footer>
    </div>
</body>
</html>
`;

// Routes
app.get('/', (req, res) => {
    res.send(welcomeHTML);
});

// Health check endpoint for Azure
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: environment,
        nodeVersion: nodeVersion
    });
});

// API endpoint for testing
app.get('/api/info', (req, res) => {
    res.json({
        message: 'Hi, this is your Terraform training',
        module: '02 - Remote State, Variables, and Modules',
        environment: environment,
        nodeVersion: nodeVersion,
        timestamp: new Date().toISOString(),
        hostname: req.hostname
    });
});

// Start the server
app.listen(PORT, () => {
    console.log(`🚀 Terraform Training App running on port ${PORT}`);
    console.log(`   Environment: ${environment}`);
    console.log(`   Node.js: ${nodeVersion}`);
    console.log(`   Health check: http://localhost:${PORT}/health`);
});
