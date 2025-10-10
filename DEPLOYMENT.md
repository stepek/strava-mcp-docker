# GCP Cloud Run Deployment Guide

## Prerequisites

1. **GCP CLI installed**: Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)
2. **Docker installed**: For local testing
3. **GCP Project**: Have a GCP project with billing enabled
4. **Authentication**: Run `gcloud auth login` and `gcloud auth configure-docker`

## MCP Server Architecture

✅ **This MCP server supports both transports:**

- **stdio transport** (`src/server.ts`): For local use with Claude Desktop
- **HTTP/SSE transport** (`src/server-http.ts`): For cloud deployment and remote MCP clients like Poke

The Dockerfile uses the HTTP/SSE version (`server-http.js`) for Cloud Run deployment.

## Environment Variables

Your application requires the following environment variables (see `.env.example`):

- `STRAVA_CLIENT_ID`: Your Strava API client ID
- `STRAVA_CLIENT_SECRET`: Your Strava API client secret
- `STRAVA_REFRESH_TOKEN`: Your Strava refresh token
- `STRAVA_ACCESS_TOKEN`: Your Strava access token

## Deployment Steps

### 1. Set Your GCP Project

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"  # Choose your preferred region
export SERVICE_NAME="strava-mcp-server"

gcloud config set project $PROJECT_ID
```

### 2. Build and Push Docker Image to Google Container Registry

```bash
# Build the Docker image
docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME:latest .

# Push to Google Container Registry
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME:latest
```

Alternatively, use Cloud Build (recommended):

```bash
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME:latest
```

### 3. Deploy to Cloud Run

```bash
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars "STRAVA_CLIENT_ID=your_client_id,STRAVA_CLIENT_SECRET=your_client_secret,STRAVA_REFRESH_TOKEN=your_refresh_token" \
  --memory 512Mi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 10 \
  --port 8080
```

**For production, use Secret Manager for sensitive variables:**

```bash
# Create secrets
echo -n "your_client_secret" | gcloud secrets create strava-client-secret --data-file=-
echo -n "your_refresh_token" | gcloud secrets create strava-refresh-token --data-file=-
echo -n "your_access_token" | gcloud secrets create strava-access-token --data-file=-

# Deploy with secrets
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
  --platform managed \
  --region $REGION \
  --set-env-vars "STRAVA_CLIENT_ID=your_client_id" \
  --set-secrets "STRAVA_CLIENT_SECRET=strava-client-secret:latest,STRAVA_REFRESH_TOKEN=strava-refresh-token:latest,STRAVA_ACCESS_TOKEN=strava-access-token:latest" \
  --memory 512Mi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 10 \
  --port 8080
```

### 4. Verify Deployment

```bash
# Get the service URL
gcloud run services describe $SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --format 'value(status.url)'

# Test the endpoint (adjust based on your server's HTTP interface)
curl https://your-service-url.run.app
```

Alternatively, use Postman to test your endpoint.

## Local Testing with Docker

Before deploying to Cloud Run, test locally:

```bash
# Build the image
docker build -t strava-mcp-server:local .

# Run locally
docker run -p 8080:8080 \
  -e STRAVA_CLIENT_ID="your_client_id" \
  -e STRAVA_CLIENT_SECRET="your_client_secret" \
  -e STRAVA_REFRESH_TOKEN="your_refresh_token" \
  -e STRAVA_ACCESS_TOKEN="your_access_token" \
  strava-mcp-server:local
```

## Monitoring and Logs

View logs:
```bash
gcloud run services logs read $SERVICE_NAME \
  --region $REGION \
  --limit 50
```

Monitor in Cloud Console:
- Navigate to Cloud Run in GCP Console
- Select your service
- View Metrics, Logs, and Revisions tabs

## Updating the Service

To deploy a new version:

```bash
# Build new image
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME:latest

# Deploy automatically uses the latest tag
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
  --platform managed \
  --region $REGION
```

## Cost Optimization

- Cloud Run charges only for request time
- Set appropriate memory limits (512Mi should be sufficient)
- Configure `--max-instances` to prevent unexpected scaling
- Use `--min-instances 0` for infrequent use (cold starts apply)
- Use `--min-instances 1` for consistent low latency (always warm)

## Troubleshooting

### Server won't start
- Check logs: `gcloud run services logs read $SERVICE_NAME`
- Verify environment variables are set correctly
- Ensure the container listens on `0.0.0.0:$PORT` (Cloud Run sets PORT env var)

### Stdio Transport Issues
- Your server uses stdio transport which isn't suitable for HTTP
- Consider implementing an HTTP transport layer
- Or use Cloud Run Jobs instead of Cloud Run Services

### Authentication Issues
- Verify Strava API credentials
- Ensure refresh token is valid
- Check Secret Manager permissions if using secrets

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Run Best Practices](https://cloud.google.com/run/docs/tips)
- [Secret Manager Guide](https://cloud.google.com/secret-manager/docs)
