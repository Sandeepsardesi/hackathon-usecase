FROM node:18-alpine
WORKDIR /app
COPY src/package*.json ./
RUN npm ci --only=production || npm install --production
COPY src ./src
ENV PORT=3001
EXPOSE 3001
CMD ["node", "src/index.js"]
