FROM node:18
WORKDIR /app

# Copy backend package files and install dependencies
COPY backend/package*.json ./
RUN npm install

# Copy backend source code
COPY backend/ ./

# Expose backend port (update if your backend uses a different port)
EXPOSE 4000

# Start your backend
CMD ["npm", "start"]
