<script setup lang="ts">
definePageMeta({ title: 'Profil Saya' })

const authUser = useAuthUser()

const roleLabels: Record<string, string> = {
  superadmin: 'Superadmin',
  admin_cabang: 'Admin Cabang',
  finance: 'Finance',
  perawat: 'Perawat',
  dokter: 'Dokter'
}

function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

// --- Profile form ---
const profileForm = reactive({ fullName: authUser.value?.fullName ?? '', phoneWa: authUser.value?.phoneWa ?? '' })
const savingProfile = ref(false)
const profileError = ref('')
const profileSuccess = ref(false)

async function onSaveProfile() {
  if (!profileForm.fullName) {
    profileError.value = 'Nama lengkap wajib diisi.'
    return
  }
  savingProfile.value = true
  profileError.value = ''
  profileSuccess.value = false
  try {
    const updated = await apiPut<{ id: string, fullName: string, email: string, phoneWa: string | null, role: string }>('/auth/me', {
      fullName: profileForm.fullName,
      phoneWa: profileForm.phoneWa || null
    })
    authUser.value = updated
    profileSuccess.value = true
  } catch (err) {
    profileError.value = apiErrorMessage(err)
  } finally {
    savingProfile.value = false
  }
}

// --- Change password form ---
const passwordForm = reactive({ currentPassword: '', newPassword: '', confirmPassword: '' })
const savingPassword = ref(false)
const passwordError = ref('')
const passwordSuccess = ref(false)

async function onChangePassword() {
  if (passwordForm.newPassword.length < 8) {
    passwordError.value = 'Password baru minimal 8 karakter.'
    return
  }
  if (passwordForm.newPassword !== passwordForm.confirmPassword) {
    passwordError.value = 'Konfirmasi password tidak cocok.'
    return
  }
  savingPassword.value = true
  passwordError.value = ''
  passwordSuccess.value = false
  try {
    await apiPost('/auth/change-password', {
      currentPassword: passwordForm.currentPassword,
      newPassword: passwordForm.newPassword
    })
    passwordForm.currentPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    passwordSuccess.value = true
  } catch (err) {
    passwordError.value = apiErrorMessage(err)
  } finally {
    savingPassword.value = false
  }
}
</script>

<template>
  <UContainer class="py-6 space-y-6 max-w-2xl">
    <div>
      <h1 class="text-xl font-semibold">
        Profil Saya
      </h1>
      <p class="text-sm text-muted">
        Kelola informasi akun dan password Anda.
      </p>
    </div>

    <div class="flex items-center gap-3">
      <UAvatar
        :text="authUser ? initials(authUser.fullName) : '?'"
        size="xl"
        class="bg-primary-100 text-primary-700"
      />
      <div>
        <p class="font-semibold">
          {{ authUser?.fullName }}
        </p>
        <p class="text-sm text-muted">
          {{ authUser?.email }}
        </p>
        <UBadge
          color="primary"
          variant="subtle"
          size="xs"
          class="mt-1"
        >
          {{ roleLabels[authUser?.role ?? ''] ?? authUser?.role }}
        </UBadge>
      </div>
    </div>

    <UCard>
      <template #header>
        <h2 class="font-medium">
          Informasi Akun
        </h2>
      </template>
      <form
        class="space-y-4"
        @submit.prevent="onSaveProfile"
      >
        <UFormField label="Nama Lengkap">
          <UInput
            v-model="profileForm.fullName"
            class="w-full"
          />
        </UFormField>
        <UFormField label="Email">
          <UInput
            :model-value="authUser?.email"
            disabled
            class="w-full"
          />
        </UFormField>
        <UFormField label="No. WhatsApp">
          <UInput
            v-model="profileForm.phoneWa"
            class="w-full"
          />
        </UFormField>
        <UAlert
          v-if="profileSuccess"
          color="success"
          variant="subtle"
          description="Profil berhasil diperbarui."
        />
        <UAlert
          v-if="profileError"
          color="error"
          variant="subtle"
          :description="profileError"
        />
        <UButton
          type="submit"
          :loading="savingProfile"
          label="Simpan Perubahan"
        />
      </form>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="font-medium">
          Ubah Password
        </h2>
      </template>
      <form
        class="space-y-4"
        @submit.prevent="onChangePassword"
      >
        <UFormField label="Password Saat Ini">
          <UInput
            v-model="passwordForm.currentPassword"
            type="password"
            class="w-full"
          />
        </UFormField>
        <div class="grid grid-cols-2 gap-4">
          <UFormField label="Password Baru">
            <UInput
              v-model="passwordForm.newPassword"
              type="password"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Konfirmasi Password Baru">
            <UInput
              v-model="passwordForm.confirmPassword"
              type="password"
              class="w-full"
            />
          </UFormField>
        </div>
        <UAlert
          v-if="passwordSuccess"
          color="success"
          variant="subtle"
          description="Password berhasil diubah."
        />
        <UAlert
          v-if="passwordError"
          color="error"
          variant="subtle"
          :description="passwordError"
        />
        <UButton
          type="submit"
          :loading="savingPassword"
          label="Ubah Password"
        />
      </form>
    </UCard>
  </UContainer>
</template>
