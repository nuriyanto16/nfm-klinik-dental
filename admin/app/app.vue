<script setup>
const appSettings = useAppSettings()
await useAsyncData('appSettings', () => appSettings.fetchSettings())

const siteTitle = computed(() => `${appSettings.settings.brand_name || 'Klinik Gigi'} — Office Panel`)
const siteDescription = computed(() => `Panel administrasi ${appSettings.settings.brand_name || 'Klinik Gigi'}: reservasi, rekam medis, dokter, billing, dan konten.`)

useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'icon', href: (useRuntimeConfig().app.baseURL + 'favicon.ico').replace('//', '/') }
  ],
  htmlAttrs: {
    lang: 'id'
  }
})

useSeoMeta({
  title: siteTitle,
  description: siteDescription
})
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
