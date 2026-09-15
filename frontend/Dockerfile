FROM node:22-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build -- --configuration production

# ---- Runtime stage ----
FROM node:22-alpine AS runtime

WORKDIR /app

RUN npm install -g serve@14

COPY --from=build /app/dist/frontend/browser ./browser

EXPOSE 9091

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:9091/ || exit 1

CMD ["serve", "-s", "browser", "-l", "9091"]
