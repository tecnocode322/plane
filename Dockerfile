# ---------------------------------------------------
# Etapa 1: Construcción (Turborepo + Next.js + API)
# ---------------------------------------------------
FROM node:22-alpine AS builder

WORKDIR /app

# Copiamos los archivos de configuración del monorepo
COPY . .

# Instalar pnpm (usado por Plane)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Instalar dependencias con pnpm
RUN pnpm install --frozen-lockfile

# Construir todos los paquetes (API y Web)
RUN pnpm turbo run build --filter=@plane/web --filter=@plane/api-server

# ---------------------------------------------------
# Etapa 2: Imagen final de ejecución
# ---------------------------------------------------
FROM node:22-alpine AS runner

WORKDIR /app

# Copiamos los artefactos del builder
COPY --from=builder /app/apps/web ./apps/web
COPY --from=builder /app/apps/api ./apps/api
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages

# Variables de entorno obligatorias
ENV NODE_ENV=production
ENV PORT=10000

# Exponemos el puerto que Render usará
EXPOSE 10000

# Comando de inicio (puedes ajustar según backend o frontend)
CMD ["node", "apps/api/dist/main.js"]
