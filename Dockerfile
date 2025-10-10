# Multi-stage build for optimal image size
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies (including devDependencies for building)
RUN npm ci

# Copy source code
COPY src ./src

# Build TypeScript code
RUN npm run build

# Production stage
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy .env.example as reference (don't copy actual .env for security)
COPY .env.example ./

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Cloud Run expects the app to listen on the PORT environment variable
# If your MCP server needs to run on HTTP, you'll need to adapt server.ts
ENV NODE_ENV=production

# Health check (optional, adjust based on your server capabilities)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD node --eval "process.exit(0)" || exit 1

# Cloud Run will inject the PORT environment variable
# Expose port 8080 as default (Cloud Run can override this)
EXPOSE 8080

# Start the HTTP/SSE server (for Cloud Run and Poke)
CMD ["node", "dist/server-http.js"]
