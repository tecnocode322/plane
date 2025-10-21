# ---------------------------------------------------
# Etapa 1: Construcción (Turborepo + Next.js + API)
# ---------------------------------------------------
FROM node:22-alpine AS builder

# Instala dependencias del sistema necesarias
RUN apk add --no-cache bash libc6-compat python3 make g++

WORKDIR /apps

# Copiar todos los archivos
COPY . .

# Habilitar pnpm (usado por Plane)
RUN corepack enable && corepack prepare pnpm@9.7.0 --activate

# Instalar dependencias usando pnpm
RUN pnpm install --frozen-lockfile

# Construir los paquetes necesarios (Server y Client)
RUN pnpm turbo run build --filter=api --filter=web
# ---------------------------------------------------
# Etapa 2: Ejecución
# ---------------------------------------------------
FROM node:22-alpine AS runner

# Crear usuario sin privilegios (Render recomienda no usar root)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar artefactos del builder
COPY --from=builder /app/apps/api ./apps/api
COPY --from=builder /app/apps/web ./apps/web
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/node_modules ./node_modules

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=10000

# Puerto para Render
EXPOSE 10000

# Cambiar a usuario sin privilegios
USER appuser

# Comando de inicio del backend de Plane
CMD ["node", "apps/api/dist/main.js"]
