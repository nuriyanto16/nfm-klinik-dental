// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  devtools: {
    enabled: true
  },

  // Overridable at runtime (no rebuild needed) via NUXT_APP_BASE_URL — set
  // to e.g. '/product/klinik/' when this app is served from a path prefix
  // behind a reverse proxy, so internal routes/redirects/assets resolve
  // correctly instead of assuming they own the domain root.
  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || '/'
  },

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    // Server-only: used for SSR fetches from inside the admin-frontend
    // container, over the docker-compose network (service name, not
    // localhost).
    apiBaseInternal: process.env.API_BASE_INTERNAL || 'http://core-api:8080/api/v1',
    public: {
      // Client-side: used by the browser, which hits the host-mapped port.
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080/api/v1'
    }
  },

  compatibilityDate: '2026-06-30',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
