# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
# Copy dependency files first to use Layer Caching
COPY package*.json ./
RUN npm install
# Copy the rest of your code
COPY . .

# Stage 2: Final Image
FROM node:18-alpine
WORKDIR /app
# Copy only the necessary files from the builder stage
COPY --from=builder /app .
EXPOSE 3000
CMD ["node", "app.js"]
