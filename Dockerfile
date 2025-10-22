# =========================
# Etapa 1: Build
# =========================
FROM node:18-alpine AS builder

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
FROM node:18-alpine AS runner

# Crear directorio de trabajo
WORKDIR /app

# Copiar los artefactos compilados desde el builder
COPY --from=builder /app .

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000

# Exponer puerto (Render detecta este puerto para hacer health check)
EXPOSE 3000

# =========================
# Comando de inicio
# =========================
# Si tu servicio en Render será el BACKEND (Plane API)
# CMD ["node", "apps/api/dist/main.js"]

# Si tu servicio será el FRONTEND (Next.js)
CMD ["pnpm", "--filter", "web", "start"]
