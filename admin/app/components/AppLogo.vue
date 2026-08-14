<script setup lang="ts">
const { settings } = useAppSettings()

const initials = computed(() => {
  if (!settings.value.brand_name) return 'NDC'
  return settings.value.brand_name.split(' ').map(n => n[0]).join('').substring(0, 3).toUpperCase()
})
</script>

<template>
  <div class="flex items-center gap-2 font-semibold">
    <img v-if="settings.logo_url" :src="settings.logo_url" alt="Logo" class="w-8 h-8 rounded-lg object-cover shadow-sm" />
    <span v-else class="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-primary-700 text-white text-xs font-semibold shadow-sm">
      {{ initials }}
    </span>
    <span class="hidden sm:inline">{{ settings.brand_name || 'Klinik Gigi' }}</span>
  </div>
</template>
