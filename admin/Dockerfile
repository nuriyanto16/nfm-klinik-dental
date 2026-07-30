FROM node:22-alpine AS build
WORKDIR /src
RUN corepack enable
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
# Nitro's server bundling step needs more headroom than V8's default old-space
# ceiling on a low-memory host (hit "JavaScript heap out of memory" on a
# 3.6GB VPS otherwise) — raise it explicitly rather than relying on the
# auto-detected default.
ENV NODE_OPTIONS=--max-old-space-size=3072
RUN pnpm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=build /src/.output ./.output
EXPOSE 3000
ENV HOST=0.0.0.0
ENV PORT=3000
CMD ["node", ".output/server/index.mjs"]
