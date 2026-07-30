<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const showPassword = ref(false)
const loading = ref(false)
const error = ref('')

const { question: captchaQuestion, userAnswer: captchaAnswer, isValid: captchaValid, refresh: refreshCaptcha } = useMathCaptcha()

// Captcha is checked client-side only for now (no backend verification
// token yet) — real login itself is wired to POST /api/v1/auth/login.
async function onSubmit() {
  if (!captchaValid.value) {
    error.value = 'Jawaban verifikasi salah. Coba lagi.'
    refreshCaptcha()
    return
  }

  loading.value = true
  error.value = ''
  try {
    await login(email.value, password.value)
    await navigateTo('/')
  } catch (err) {
    error.value = apiErrorMessage(err)
    refreshCaptcha()
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <UCard :ui="{ root: 'shadow-xl ring-1 ring-default' }">
    <template #header>
      <div>
        <h1 class="text-lg font-semibold">
          Masuk ke Office Panel
        </h1>
        <p class="text-sm text-muted">
          Khusus staf Nina Dental Care.
        </p>
      </div>
    </template>

    <form
      class="space-y-4"
      @submit.prevent="onSubmit"
    >
      <UFormField
        label="Email"
        name="email"
      >
        <UInput
          v-model="email"
          type="email"
          placeholder="staf@ninadentalcare.com"
          class="w-full"
          icon="i-lucide-mail"
          autocomplete="username"
          required
        />
      </UFormField>

      <UFormField
        label="Password"
        name="password"
      >
        <UInput
          v-model="password"
          :type="showPassword ? 'text' : 'password'"
          placeholder="••••••••"
          class="w-full"
          icon="i-lucide-lock"
          autocomplete="current-password"
          required
        >
          <template #trailing>
            <UButton
              :icon="showPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              color="neutral"
              variant="link"
              size="xs"
              :padded="false"
              :aria-label="showPassword ? 'Sembunyikan password' : 'Tampilkan password'"
              @click="showPassword = !showPassword"
            />
          </template>
        </UInput>
      </UFormField>

      <div class="flex items-center justify-between">
        <UCheckbox
          v-model="rememberMe"
          label="Ingat saya"
        />
        <UButton
          variant="link"
          color="neutral"
          size="xs"
          label="Lupa password?"
          :padded="false"
        />
      </div>

      <UFormField
        label="Verifikasi keamanan"
        name="captcha"
      >
        <div class="flex items-center gap-2">
          <div
            class="flex-1 flex items-center justify-center h-10 rounded-md border border-default bg-elevated font-mono text-sm tracking-widest select-none"
            aria-hidden="true"
          >
            {{ captchaQuestion }} = ?
          </div>
          <UButton
            icon="i-lucide-refresh-cw"
            color="neutral"
            variant="soft"
            aria-label="Ganti soal verifikasi"
            @click="refreshCaptcha"
          />
        </div>
        <UInput
          v-model="captchaAnswer"
          type="text"
          inputmode="numeric"
          pattern="[0-9]*"
          placeholder="Masukkan jawaban"
          class="w-full mt-2"
          required
        />
      </UFormField>

      <UAlert
        v-if="error"
        color="error"
        variant="subtle"
        icon="i-lucide-alert-circle"
        :description="error"
      />

      <UButton
        type="submit"
        block
        :loading="loading"
        label="Masuk"
        icon="i-lucide-log-in"
      />
    </form>

    <template #footer>
      <p class="text-xs text-muted text-center">
        Demo: <code class="font-mono">admin@ninadentalcare.com</code> / <code class="font-mono">NinaDental#2026</code>
      </p>
    </template>
  </UCard>
</template>
