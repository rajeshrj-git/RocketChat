# Stage 1: Dependencies - Install npm modules from the extracted source
FROM node:18.18-alpine AS deps

# Install OS build dependencies for native npm modules (like bcrypt)
RUN apk add --no-cache \
    python3 \
    make \
    g++

# Create and set the app directory
WORKDIR /app

# Copy the entire extracted bundle from the host into the image
COPY ./bundle ./

# Set correct ownership for the app directory
RUN chown -R node:node .

# Switch to non-root user for security
USER node

# Install ALL npm dependencies (including devDependencies for a potential build)
# The dependencies are located in the 'programs/server' directory
RUN cd programs/server && \
    npm install --production=false

# Stage 2: Build - (Typically a no-op for pre-built tarballs)
FROM deps AS build
WORKDIR /app
COPY --from=deps /app .
USER node
# RUN ... any build commands would go here if needed.

# Stage 3: Runtime - Create the final, minimal image
FROM node:18.18-alpine AS runtime

# Install runtime dependencies & create user
RUN apk add --no-cache curl

# Create a non-root user and group with dynamically assigned IDs
RUN addgroup -S rocketchat && \
    adduser -S rocketchat -G rocketchat

# Set workdir and copy ONLY the app and its installed node_modules
WORKDIR /app
COPY --from=build --chown=rocketchat:rocketchat /app ./

# Switch to the non-root user
USER rocketchat

# Expose the correct port
EXPOSE 4000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/api/v1/info || exit 1

# Set runtime environment variables
ENV PORT=4000 \
    ROOT_URL=http://localhost:4000 \
    MONGO_URL=mongodb://mongodb:27017/rocketchat

# Copy and set entrypoint script
COPY docker-entrypoint.sh ./
ENTRYPOINT ["./docker-entrypoint.sh"]

# The default command to run the application
CMD ["node", "main.js"]