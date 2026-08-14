import { ref, readonly } from 'vue'

const settings = ref<Record<string, string>>({
  brand_name: 'Nina Dental Care',
  logo_url: '',
  contact_phone: ''
})

export const useAppSettings = () => {
  const fetchSettings = async () => {
    try {
      const data = await $fetch<Record<string, string>>('/api/v1/settings/public')
      settings.value = { ...settings.value, ...data }
    } catch (error) {
      console.error('Failed to fetch app settings:', error)
    }
  }

  return {
    settings: readonly(settings),
    fetchSettings
  }
}
