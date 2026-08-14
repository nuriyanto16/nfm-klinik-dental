// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  colorMode: {
    preference: 'light',
    fallback: 'light'
  },

  icon: {
    clientBundle: {
      icons: [
        // --- lucide icons (all usages across pages, components, composables) ---
        'lucide:activity',
        'lucide:alert-circle',
        'lucide:alert-triangle',
        'lucide:archive',
        'lucide:arrow-left',
        'lucide:arrow-right',
        'lucide:arrow-right-circle',
        'lucide:award',
        'lucide:badge-check',
        'lucide:banknote',
        'lucide:bar-chart-2',
        'lucide:bar-chart-3',
        'lucide:barcode',
        'lucide:bell',
        'lucide:bell-ring',
        'lucide:book',
        'lucide:book-open',
        'lucide:building',
        'lucide:building-2',
        'lucide:calculator',
        'lucide:calendar',
        'lucide:calendar-check',
        'lucide:calendar-clock',
        'lucide:calendar-days',
        'lucide:check',
        'lucide:check-circle',
        'lucide:check-circle-2',
        'lucide:chevron-left',
        'lucide:chevron-right',
        'lucide:chevrons-up-down',
        'lucide:circle',
        'lucide:clock',
        'lucide:code-2',
        'lucide:coins',
        'lucide:copy',
        'lucide:credit-card',
        'lucide:download',
        'lucide:edit-2',
        'lucide:external-link',
        'lucide:eye',
        'lucide:eye-off',
        'lucide:file-edit',
        'lucide:file-heart',
        'lucide:file-spreadsheet',
        'lucide:file-text',
        'lucide:grid',
        'lucide:id-card',
        'lucide:image',
        'lucide:inbox',
        'lucide:info',
        'lucide:key-round',
        'lucide:landmark',
        'lucide:layers',
        'lucide:layout-dashboard',
        'lucide:link',
        'lucide:list',
        'lucide:list-checks',
        'lucide:loader-circle',
        'lucide:lock',
        'lucide:log-in',
        'lucide:log-out',
        'lucide:mail',
        'lucide:map-pin',
        'lucide:message-circle',
        'lucide:minus',
        'lucide:monitor',
        'lucide:moon',
        'lucide:newspaper',
        'lucide:pencil',
        'lucide:percent',
        'lucide:phone',
        'lucide:piggy-bank',
        'lucide:pill',
        'lucide:plus',
        'lucide:plus-circle',
        'lucide:printer',
        'lucide:receipt',
        'lucide:receipt-text',
        'lucide:refresh-cw',
        'lucide:rocket',
        'lucide:rotate-ccw',
        'lucide:rotate-cw',
        'lucide:save',
        'lucide:search',
        'lucide:search-x',
        'lucide:send',
        'lucide:shield-alert',
        'lucide:shield-check',
        'lucide:shopping-bag',
        'lucide:shopping-cart',
        'lucide:sliders',
        'lucide:smartphone',
        'lucide:smile',
        'lucide:sparkles',
        'lucide:star',
        'lucide:stethoscope',
        'lucide:sun',
        'lucide:tag',
        'lucide:tags',
        'lucide:ticket-percent',
        'lucide:trash-2',
        'lucide:trending-up',
        'lucide:triangle-alert',
        'lucide:undo-2',
        'lucide:upload-cloud',
        'lucide:user',
        'lucide:user-check',
        'lucide:user-plus',
        'lucide:user-round',
        'lucide:user-x',
        'lucide:users',
        'lucide:wallet',
        'lucide:x',
        'lucide:x-circle',
        'lucide:zap'
      ],
      scan: true
    }
  },

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
