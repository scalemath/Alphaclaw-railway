FROM node:22-slim

RUN apt-get update && apt-get install -y git curl procps python3 make g++ cron && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV AUTOMEM_ENDPOINT=${AUTOMEM_ENDPOINT}
ENV AUTOMEM_API_TOKEN=${AUTOMEM_API_TOKEN}
ENV OPENCLAW_HOME=/data
RUN mkdir -p ${OPENCLAW_HOME}/.openclaw

COPY package.json ./
RUN npm install --omit=dev --prefer-online && npm cache clean --force
# RUN npx @verygoodplugins/mcp-automem openclaw --mode plugin --workspace "${OPENCLAW_HOME}/.openclaw" --endpoint "${RAILWAY_SERVICE_AUTOMEM_URL}" --api-key "${AUTOMEM_API_TOKEN}"

ENV PATH="/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

CMD ["alphaclaw", "start"]
