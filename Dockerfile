FROM node:22-slim

RUN apt-get update && apt-get install -y git curl procps python3 make g++ cron tini && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --prefer-online && npm cache clean --force

# The shim directory comes FIRST so `openclaw` resolves to it and not to the real binary
# in node_modules/.bin. See shims/openclaw for why.
COPY shims/openclaw /opt/shims/openclaw
RUN chmod +x /opt/shims/openclaw

# alphaclaw seeds a legacy exec-approvals.json on every boot; OpenClaw 2.0 refuses all
# runtime access while that file exists. See the script for the full explanation.
COPY shims/disable-legacy-exec-approvals.js /opt/shims/disable-legacy-exec-approvals.js
RUN node /opt/shims/disable-legacy-exec-approvals.js
ENV PATH="/opt/shims:/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["alphaclaw", "start"]
