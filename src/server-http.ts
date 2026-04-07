import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import * as dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

import { getAthleteProfile } from './tools/getAthleteProfile.js';
import { getAthleteStatsTool } from "./tools/getAthleteStats.js";
import { getActivityDetailsTool } from "./tools/getActivityDetails.js";
import { getRecentActivities } from "./tools/getRecentActivities.js";
import { listAthleteClubs } from './tools/listAthleteClubs.js';
import { listStarredSegments } from './tools/listStarredSegments.js';
import { getSegmentTool } from "./tools/getSegment.js";
import { exploreSegments } from './tools/exploreSegments.js';
import { getSegmentEffortTool } from './tools/getSegmentEffort.js';
import { listSegmentEffortsTool } from './tools/listSegmentEfforts.js';
import { listAthleteRoutesTool } from './tools/listAthleteRoutes.js';
import { getRouteTool } from './tools/getRoute.js';
import { getActivityStreamsTool } from './tools/getActivityStreams.js';
import { getActivityLapsTool } from './tools/getActivityLaps.js';
import { getAthleteZonesTool } from './tools/getAthleteZones.js';
import { getAllActivities } from './tools/getAllActivities.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const envPath = path.join(projectRoot, '.env');
dotenv.config({ path: envPath });

function registerTools(server: McpServer) {
    server.tool(getAthleteProfile.name, getAthleteProfile.description, {}, getAthleteProfile.execute);
    server.tool(getAthleteStatsTool.name, getAthleteStatsTool.description, getAthleteStatsTool.inputSchema?.shape ?? {}, getAthleteStatsTool.execute);
    server.tool(getActivityDetailsTool.name, getActivityDetailsTool.description, getActivityDetailsTool.inputSchema?.shape ?? {}, getActivityDetailsTool.execute);
    server.tool(getRecentActivities.name, getRecentActivities.description, getRecentActivities.inputSchema?.shape ?? {}, getRecentActivities.execute);
    server.tool(listAthleteClubs.name, listAthleteClubs.description, {}, listAthleteClubs.execute);
    server.tool(listStarredSegments.name, listStarredSegments.description, {}, listStarredSegments.execute);
    server.tool(getSegmentTool.name, getSegmentTool.description, getSegmentTool.inputSchema?.shape ?? {}, getSegmentTool.execute);
    server.tool(exploreSegments.name, exploreSegments.description, exploreSegments.inputSchema?.shape ?? {}, exploreSegments.execute);
    server.tool(getSegmentEffortTool.name, getSegmentEffortTool.description, getSegmentEffortTool.inputSchema?.shape ?? {}, getSegmentEffortTool.execute);
    server.tool(listSegmentEffortsTool.name, listSegmentEffortsTool.description, listSegmentEffortsTool.inputSchema?.shape ?? {}, listSegmentEffortsTool.execute);
    server.tool(listAthleteRoutesTool.name, listAthleteRoutesTool.description, listAthleteRoutesTool.inputSchema?.shape ?? {}, listAthleteRoutesTool.execute);
    server.tool(getRouteTool.name, getRouteTool.description, getRouteTool.inputSchema?.shape ?? {}, getRouteTool.execute);
    server.tool(getActivityStreamsTool.name, getActivityStreamsTool.description, getActivityStreamsTool.inputSchema?.shape ?? {}, getActivityStreamsTool.execute);
    server.tool(getActivityLapsTool.name, getActivityLapsTool.description, getActivityLapsTool.inputSchema?.shape ?? {}, getActivityLapsTool.execute);
    server.tool(getAthleteZonesTool.name, getAthleteZonesTool.description, getAthleteZonesTool.inputSchema?.shape ?? {}, getAthleteZonesTool.execute);
    server.tool(getAllActivities.name, getAllActivities.description, getAllActivities.inputSchema?.shape ?? {}, getAllActivities.execute);
}

const app = createMcpExpressApp({
    host: '0.0.0.0',
    allowedHosts: ['localhost', '127.0.0.1', '::1']
});

const server = new McpServer({
    name: "Strava MCP Server",
    version: "1.0.0"
});

registerTools(server);

app.post('/sse', async (req, res) => {
    try {
        const transport = new StreamableHTTPServerTransport({
            sessionIdGenerator: undefined,
            enableJsonResponse: true
        });
        res.on('close', () => {
            transport.close();
        });
        await server.connect(transport);
        await transport.handleRequest(req, res, req.body);
    } catch (error) {
        console.error('Error handling MCP request:', error);
        if (!res.headersSent) {
            res.status(500).json({
                jsonrpc: '2.0',
                error: {
                    code: -32603,
                    message: 'Internal server error'
                },
                id: null
            });
        }
    }
});

app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok' });
});

app.get('/', (_req, res) => {
    res.json({
        name: 'Strava MCP Server',
        version: '1.0.0',
        transport: 'HTTP/SSE',
        endpoints: {
            mcp: '/sse',
            health: '/health'
        }
    });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`Strava MCP Server (HTTP/SSE) running on port ${PORT}`);
    console.log(`MCP endpoint: http://localhost:${PORT}/sse`);
    console.log(`Health check: http://localhost:${PORT}/health`);
}).on('error', (error) => {
    console.error('Server error:', error);
    process.exit(1);
});
