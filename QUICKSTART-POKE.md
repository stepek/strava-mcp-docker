# Quick Start: Deploy Strava MCP Server for Poke

This is the fastest way to get your Strava MCP server running and integrated with Poke.

## 🚀 Quick Deploy to Cloud Run

### Step 1: Install Dependencies
```bash
npm install
npm run build
```

### Step 2: Set Your GCP Project
```bash
export GCP_PROJECT_ID="your-gcp-project-id"
export GCP_REGION="us-central1"
```

### Step 3: Create Strava API Secrets
```bash
# Get your credentials from https://www.strava.com/settings/api
echo -n "your_client_id" | gcloud secrets create strava-client-id --data-file=-
echo -n "your_client_secret" | gcloud secrets create strava-client-secret --data-file=-
echo -n "your_refresh_token" | gcloud secrets create strava-refresh-token --data-file=-
echo -n "your_access_token" | gcloud secrets create strava-access-token --data-file=-
```

> **How to get a refresh token**: Run `npm run setup-auth` locally first to obtain your refresh token.

### Step 4: Deploy with the Script
```bash
./deploy-cloud-run.sh
```

Or manually:
```bash
# Build and push
gcloud builds submit --tag gcr.io/$GCP_PROJECT_ID/strava-mcp-server:latest

# Deploy
gcloud run deploy strava-mcp-server \
  --image gcr.io/$GCP_PROJECT_ID/strava-mcp-server:latest \
  --platform managed \
  --region $GCP_REGION \
  --allow-unauthenticated \
  --set-secrets "STRAVA_CLIENT_ID=strava-client-id:latest,STRAVA_CLIENT_SECRET=strava-client-secret:latest,STRAVA_REFRESH_TOKEN=strava-refresh-token:latest,STRAVA_ACCESS_TOKEN=strava-access-token:latest" \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --port 8080
```

### Step 5: Get Your URL
```bash
gcloud run services describe strava-mcp-server \
  --region $GCP_REGION \
  --format 'value(status.url)'
```

You'll get something like: `https://strava-mcp-server-abc123-uc.a.run.app`

## 🔌 Add to Poke

1. Open Poke and go to integrations
2. Click "New Integration"
3. Fill in:
   - **Name**: Strava MCP
   - **Server URL**: `https://your-service-url.run.app/sse`
   - **API Key**: Leave empty
4. Click "Add Integration"

## ✅ Test It

In Poke, try asking:
- "Show me my recent Strava activities"
- "What are my running stats this year?"
- "Find cycling segments near San Francisco"

## 🧪 Local Testing (Optional)

Test locally before deploying:

```bash
# Start the HTTP server
npm run start:http

# In another terminal, test the endpoints
curl http://localhost:8080/health
curl http://localhost:8080/

# Expose with ngrok for Poke testing
ngrok http 8080
# Use the ngrok URL in Poke: https://abc123.ngrok.io/sse
```

## 📚 Documentation

- **Full deployment guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Poke integration details**: [POKE-INTEGRATION.md](POKE-INTEGRATION.md)
- **All setup options**: [README.md](README.md)

## 🔧 Troubleshooting

### Server not responding
```bash
# Check logs
gcloud run services logs read strava-mcp-server --region $GCP_REGION --limit 50

# Test health endpoint
curl https://your-service-url.run.app/health
```

### Poke can't connect
- Verify URL ends with `/sse`
- Check Cloud Run allows unauthenticated requests
- Test the endpoint: `curl https://your-service-url.run.app/`

### Strava API errors
- Verify secrets are set correctly
- Check refresh token is valid
- Run `npm run setup-auth` to get a new token

## 💡 Tips

- **Cost**: Cloud Run is free for the first 2 million requests/month
- **Scaling**: Starts at 0, scales automatically
- **Security**: Use Secret Manager (included in commands above)
- **Monitoring**: Check Cloud Run dashboard for metrics

## 🎉 You're Done!

Your Strava MCP server is now running on Cloud Run and ready to use with Poke!
