# =========================
# Etapa 1: Build
# =========================
FROM node:22-alpine AS builder

RUN apk add --no-cache bash libc6-compat python3 make g++
RUN npm install -g pnpm turbo

WORKDIR /app
COPY . .

RUN pnpm install --frozen-lockfile
RUN pnpm turbo run build --filter=plane-api --filter=web

# =========================
# Etapa 2: Runtime
# =========================
FROM node:22-alpine AS runner

RUN npm install -g pnpm
WORKDIR /app
COPY --from=builder /app .

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# =========================
# Comando dinámico de inicio
# =========================
CMD sh -c 'if [ "$SERVICE" = "api" ]; then \
      echo "🚀 Iniciando Plane API..."; \
      node apps/api/dist/main.js; \
    else \
      echo "🌐 Iniciando Plane Web (Next.js)..."; \
      pnpm --filter web start; \
    fi'
