FROM node:18-alpine
WORKDIR /app
COPY src/package*.json ./
RUN npm ci --only=production || npm install --production
COPY src ./src
ENV PORT=3000
EXPOSE 3000
CMD ["node", "src/index.js"]
