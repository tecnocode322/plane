# =========================
# Etapa 1: Build
# =========================
FROM node:22-alpine AS builder

# Instalar dependencias del sistema necesarias (por si algún paquete las requiere)
RUN apk add --no-cache bash libc6-compat python3 make g++

# Instalar pnpm y turbo globalmente
RUN npm install -g pnpm turbo

# Crear directorio de trabajo
WORKDIR /app

# Copiar todos los archivos del monorepo
COPY . .

# Instalar dependencias del monorepo
RUN pnpm install --frozen-lockfile

# Compilar solo los paquetes necesarios
RUN pnpm turbo run build --filter=plane-api --filter=web


# =========================
# Etapa 2: Runtime
# =========================
FROM node:22-alpine AS runner

# Instalar pnpm globalmente (para ejecutar scripts del monorepo)
RUN npm install -g pnpm

# Crear directorio de trabajo
WORKDIR /app

# Copiar los artefactos compilados desde el builder
COPY --from=builder /app .

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# =========================
# Comando de inicio dinámico
# =========================
# Render usará la variable SERVICE para decidir qué iniciar:
#  - SERVICE=api  → ejecuta Plane API
#  - SERVICE=web  → ejecuta el frontend Next.js
#
# Ejemplo:
#   En Render > Environment > Add variable → SERVICE=api  (para backend)
#   o SERVICE=web  (para frontend)
#
CMD sh -c 'if [ "$SERVICE" = "api" ]; then \
      echo "🚀 Iniciando Plane API..."; \
      node apps/api/dist/main.js; \
    else \
      echo "🌐 Iniciando Plane Web (Next.js)..."; \
      pnpm --filter web start; \
    fi'
