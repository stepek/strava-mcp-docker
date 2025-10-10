#!/bin/bash

# Cloud Run Deployment Script for Strava MCP Server
# Usage: ./deploy-cloud-run.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - Update these values
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="strava-mcp-server"

echo -e "${GREEN}=== Strava MCP Server - Cloud Run Deployment ===${NC}\n"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Validate PROJECT_ID
if [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
    echo -e "${RED}Error: Please set your GCP_PROJECT_ID${NC}"
    echo "Usage: GCP_PROJECT_ID=your-project-id ./deploy-cloud-run.sh"
    exit 1
fi

echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"
echo ""

# Set the project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Build and submit to Cloud Build
echo -e "\n${YELLOW}Building Docker image with Cloud Build...${NC}"
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME:latest

# Check if secrets exist
echo -e "\n${YELLOW}Checking for secrets in Secret Manager...${NC}"
SECRET_EXISTS=$(gcloud secrets list --filter="name:strava-client-secret" --format="value(name)" 2>/dev/null || echo "")

if [ -z "$SECRET_EXISTS" ]; then
    echo -e "${YELLOW}Secrets not found. You'll need to create them manually:${NC}"
    echo ""
    echo "  echo -n 'your_client_secret' | gcloud secrets create strava-client-secret --data-file=-"
    echo "  echo -n 'your_refresh_token' | gcloud secrets create strava-refresh-token --data-file=-"
    echo "  echo -n 'your_access_token' | gcloud secrets create strava-access-token --data-file=-"
    echo ""
    read -p "Press enter to continue with environment variables instead (less secure)..."
    USE_SECRETS=false
else
    echo -e "${GREEN}Secrets found in Secret Manager${NC}"
    USE_SECRETS=true
fi

# Get Strava credentials if not using secrets
if [ "$USE_SECRETS" = false ]; then
    read -p "Enter STRAVA_CLIENT_ID: " STRAVA_CLIENT_ID
    read -sp "Enter STRAVA_CLIENT_SECRET: " STRAVA_CLIENT_SECRET
    echo ""
    read -sp "Enter STRAVA_REFRESH_TOKEN: " STRAVA_REFRESH_TOKEN
    echo ""
    read -sp "Enter STRAVA_ACCESS_TOKEN: " STRAVA_ACCESS_TOKEN
    echo ""
fi

# Deploy to Cloud Run
echo -e "\n${YELLOW}Deploying to Cloud Run...${NC}"

if [ "$USE_SECRETS" = true ]; then
    # Deploy with secrets
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --set-secrets "STRAVA_CLIENT_SECRET=strava-client-secret:latest,STRAVA_REFRESH_TOKEN=strava-refresh-token:latest,STRAVA_ACCESS_TOKEN=strava-access-token:latest" \
        --memory 512Mi \
        --cpu 1 \
        --timeout 300 \
        --max-instances 10 \
        --port 8080
else
    # Deploy with environment variables
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --set-env-vars "STRAVA_CLIENT_ID=$STRAVA_CLIENT_ID,STRAVA_CLIENT_SECRET=$STRAVA_CLIENT_SECRET,STRAVA_REFRESH_TOKEN=$STRAVA_REFRESH_TOKEN,STRAVA_ACCESS_TOKEN=$STRAVA_ACCESS_TOKEN" \
        --memory 512Mi \
        --cpu 1 \
        --timeout 300 \
        --max-instances 10 \
        --port 8080
fi

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --platform managed \
    --region $REGION \
    --format 'value(status.url)')

echo -e "\n${GREEN}=== Deployment Complete ===${NC}"
echo -e "Service URL: ${GREEN}$SERVICE_URL${NC}"
echo ""
echo "View logs:"
echo "  gcloud run services logs read $SERVICE_NAME --region $REGION --limit 50"
echo ""
echo -e "${YELLOW}Note: Your MCP server uses stdio transport. You may need to adapt it for HTTP.${NC}"
