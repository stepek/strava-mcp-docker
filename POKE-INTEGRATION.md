# Integrating Strava MCP Server with Poke

This guide explains how to integrate your Strava MCP server with Poke using the HTTP/SSE transport.

## Overview

Poke supports custom MCP server integrations via HTTP/SSE endpoints. Your Strava MCP server now supports this transport method, allowing you to use it with Poke seamlessly.

## Prerequisites

1. **Deployed MCP Server**: Your server must be accessible via a public URL
   - Use GCP Cloud Run (see `DEPLOYMENT.md`)
   - Or use a service like ngrok for local testing
2. **Strava API Credentials**: Configured as environment variables in your deployment

## Deployment Options

### Option 1: Deploy to GCP Cloud Run (Recommended)

Follow the deployment guide in `DEPLOYMENT.md` to deploy your server to Cloud Run. This will give you a public HTTPS URL like:
```
https://strava-mcp-server-abc123-uc.a.run.app
```

### Option 2: Local Testing with ngrok

For testing purposes, you can run the server locally and expose it via ngrok:

```bash
# Terminal 1: Start the server
npm run start:http

# Terminal 2: Expose via ngrok
ngrok http 8080
```

This will give you a temporary public URL like:
```
https://abc123.ngrok.io
```

## Adding to Poke

1. **Open Poke** and navigate to the integrations or settings page

2. **Click "New Integration"** or "Add MCP Server"

3. **Fill in the details**:

   - **Name**: `Strava MCP` (or any name you prefer)
   
   - **Server URL**: Your server's SSE endpoint
     ```
     https://your-server-url.run.app/sse
     ```
     or for ngrok:
     ```
     https://abc123.ngrok.io/sse
     ```
   
   - **API Key** (optional): Leave empty if not using authentication

4. **Click "Add Integration"**

5. **Test the connection**: Poke should connect to your server and discover available tools

## Available Strava Tools

Once connected, you'll have access to the following tools in Poke:

### Athlete Information
- **get-athlete-profile**: Get the authenticated athlete's profile
- **get-athlete-stats**: Retrieve athlete statistics
- **get-athlete-zones**: Get configured heart rate and power zones

### Activities
- **get-recent-activities**: List recent activities
- **get-all-activities**: Get all activities with pagination
- **get-activity-details**: Detailed information about a specific activity
- **get-activity-streams**: Time-series data (GPS, heart rate, power, etc.)
- **get-activity-laps**: Lap data for an activity

### Segments
- **get-segment**: Get segment details
- **list-starred-segments**: List athlete's starred segments
- **explore-segments**: Search for segments in an area
- **get-segment-effort**: Details of a specific segment attempt
- **list-segment-efforts**: List all efforts for a segment

### Routes
- **list-athlete-routes**: List athlete's routes
- **get-route**: Get route details

### Social
- **list-athlete-clubs**: List athlete's clubs

## Example Queries in Poke

Once integrated, you can ask Poke questions like:

- "Show me my recent activities"
- "What are my running statistics for this year?"
- "Find popular cycling segments near San Francisco"
- "Get detailed data for my last run"
- "Show me all my starred segments"

## Troubleshooting

### Connection Issues

**Problem**: Poke can't connect to the server

**Solutions**:
- Verify the server is running: `curl https://your-server-url/health`
- Check that the URL includes `/sse` at the end
- Ensure Cloud Run service allows unauthenticated requests
- Check Cloud Run logs: `gcloud run services logs read strava-mcp-server`

### Missing Environment Variables

**Problem**: Server starts but API calls fail

**Solutions**:
- Verify Strava credentials are set in Cloud Run environment variables
- Check that `STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`, `STRAVA_ACCESS_TOKEN` and `STRAVA_REFRESH_TOKEN` are configured
- Test token refresh by making a manual API call

### CORS Issues

**Problem**: Browser-based access fails with CORS errors

**Solutions**:
- The server already has CORS enabled with `origin: '*'`
- For production, configure specific allowed origins in `src/server-http.ts`

### Rate Limiting

**Problem**: Strava API returns 429 errors

**Solutions**:
- Strava has rate limits (100 requests per 15 minutes, 1000 per day)
- Wait before retrying
- Consider caching frequently accessed data

## Security Considerations

### Production Deployment

For production use:

1. **Configure CORS**: Update `src/server-http.ts` to allow only specific origins:
   ```typescript
   cors({
       origin: ['https://poke.example.com'],
       exposedHeaders: ['Mcp-Session-Id'],
       allowedHeaders: ['Content-Type', 'Mcp-Session-Id']
   })
   ```

2. **Use Secret Manager**: Store Strava credentials in GCP Secret Manager (see `DEPLOYMENT.md`)

3. **Enable Authentication**: Add API key authentication if needed

4. **Monitor Usage**: Set up Cloud Run alerts for unusual traffic patterns

### API Key Rotation

If your Strava tokens expire:

1. Generate new tokens using `npm run setup-auth`
2. Update the secrets in Cloud Run:
   ```bash
   echo -n 'new_refresh_token' | gcloud secrets versions add strava-refresh-token --data-file=-
   ```
3. Redeploy or restart the Cloud Run service

## Advanced Configuration

### Custom Port

To run on a different port locally:
```bash
PORT=3000 npm run start:http
```

### Enable Session Management

For stateful sessions, modify `src/server-http.ts` to enable session management (see MCP SDK documentation).

### Add Authentication

To require API key authentication, add middleware in `src/server-http.ts`:
```typescript
app.use((req, res, next) => {
    const apiKey = req.headers['authorization'];
    if (apiKey !== `Bearer ${process.env.API_KEY}`) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
});
```

## Support

- **MCP Documentation**: https://modelcontextprotocol.io
- **Strava API Docs**: https://developers.strava.com
- **GitHub Issues**: Report issues in the project repository

## Next Steps

- Explore all available tools in Poke
- Check Cloud Run metrics and logs
- Set up monitoring and alerts
- Consider adding caching for frequently accessed data
