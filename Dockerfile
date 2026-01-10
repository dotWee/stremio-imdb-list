# ========================================
# Multi-stage Dockerfile for Stremio IMDB List Add-on
# Best practices: security, size optimization, layer caching
# ========================================

# ========================================
# Stage 1: Dependencies
# ========================================
FROM node:25-alpine AS dependencies

# Set working directory
WORKDIR /app

# Install dependencies only when needed
COPY package.json ./

# Install dependencies
RUN npm install && \
    npm cache clean --force

# ========================================
# Stage 2: Production
# ========================================
FROM node:25-alpine AS production

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy dependencies from dependencies stage
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application files
COPY --chown=nodejs:nodejs package.json server.js index.js ./

# Switch to non-root user
USER nodejs

# Expose the application port
EXPOSE 7515

# Health check - verify the server is listening on port 7515
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('net').createConnection(7515, 'localhost', () => process.exit(0)).on('error', () => process.exit(1))"

# Start the application
CMD ["node", "server.js"]
