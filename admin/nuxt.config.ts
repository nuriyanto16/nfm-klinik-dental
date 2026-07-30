// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  devtools: {
    enabled: true
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
