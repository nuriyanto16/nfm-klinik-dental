<script setup lang="ts">
import { ref, onMounted } from 'vue'

definePageMeta({
  title: 'Pengaturan',
  layout: 'default'
})

const toast = useToast()
const appSettings = useAppSettings()

const loading = ref(false)
const settings = ref({
  brand_name: '',
  logo_url: '',
  contact_phone: ''
})

onMounted(async () => {
  await fetchSettings()
})

const fetchSettings = async () => {
  loading.value = true
  try {
    const data = await $fetch('/api/v1/admin/settings')
    data.forEach((item: any) => {
      if (item.keyName in settings.value) {
        settings.value[item.keyName as keyof typeof settings.value] = item.valueData
      }
    })
  } catch (error) {
    toast.add({ title: 'Gagal memuat pengaturan', color: 'red' })
  } finally {
    loading.value = false
  }
}

const saveSetting = async (keyName: string, valueData: string) => {
  try {
    await $fetch(`/api/v1/admin/settings/${keyName}`, {
      method: 'PUT',
      body: { valueData }
    })
    toast.add({ title: 'Pengaturan berhasil disimpan', color: 'green' })
    // Update global store if brand/logo changes
    if (keyName === 'brand_name' || keyName === 'logo_url') {
      appSettings.fetchSettings()
    }
  } catch (error) {
    toast.add({ title: 'Gagal menyimpan pengaturan', color: 'red' })
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">Pengaturan Aplikasi</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">Konfigurasi nama brand, logo, dan profil klinik Anda.</p>
      </div>
    </div>

    <div v-if="loading" class="space-y-4">
      <USkeleton class="h-12 w-full" />
      <USkeleton class="h-12 w-full" />
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <UCard>
        <template #header>
          <h3 class="text-base font-semibold text-gray-900 dark:text-white">Identitas Brand</h3>
        </template>
        <div class="space-y-4">
          <UFormGroup label="Nama Klinik" hint="Muncul di header & cetakan">
            <div class="flex gap-2">
              <UInput v-model="settings.brand_name" class="flex-1" />
              <UButton label="Simpan" @click="saveSetting('brand_name', settings.brand_name)" />
            </div>
          </UFormGroup>

          <UFormGroup label="URL Logo Klinik" hint="Kosongkan jika menggunakan logo default">
            <div class="flex gap-2">
              <UInput v-model="settings.logo_url" class="flex-1" placeholder="https://..." />
              <UButton label="Simpan" @click="saveSetting('logo_url', settings.logo_url)" />
            </div>
          </UFormGroup>
        </div>
      </UCard>
      
      <UCard>
        <template #header>
          <h3 class="text-base font-semibold text-gray-900 dark:text-white">Kontak & Info</h3>
        </template>
        <div class="space-y-4">
          <UFormGroup label="WhatsApp Klinik" hint="Digunakan pada tombol chat">
            <div class="flex gap-2">
              <UInput v-model="settings.contact_phone" class="flex-1" placeholder="62812345678" />
              <UButton label="Simpan" @click="saveSetting('contact_phone', settings.contact_phone)" />
            </div>
          </UFormGroup>
        </div>
      </UCard>
    </div>
  </div>
</template>
