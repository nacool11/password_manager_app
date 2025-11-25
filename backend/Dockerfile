FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE <your-port>
CMD ["node", "<your-main-file>.js"]
