# =========================
# Etapa 1: Build
# =========================
FROM node:18-alpine AS builder

# Instalar pnpm
RUN npm install -g pnpm

# Crear directorio de trabajo
WORKDIR /app

# Copiar todos los archivos del monorepo
COPY . .

# Instalar dependencias del monorepo
RUN pnpm install --frozen-lockfile

# Compilar solo los paquetes necesarios
RUN pnpm turbo run build --filter=api-server --filter=web

# =========================
# Etapa 2: Runtime
# =========================
FROM node:18-alpine AS runner

# Instalar pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copiar los paquetes ya compilados desde el builder
COPY --from=builder /app ./

# Configurar variable de entorno (Render la sobreescribe si la defines en el dashboard)
ENV NODE_ENV=production
ENV PORT=3000

# Puerto que expondrá Render (ajusta según el tipo de servicio)
EXPOSE 3000

# =========================
# Selección del servicio
# =========================
# Si estás creando un servicio API:
# CMD ["pnpm", "--filter", "api-server", "start"]

# Si estás creando el servicio Web (Next.js frontend):
CMD ["pnpm", "--filter", "web", "start"]
