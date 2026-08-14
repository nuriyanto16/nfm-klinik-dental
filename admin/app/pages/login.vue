<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const showPassword = ref(false)
const loading = ref(false)
const error = ref('')

const { question: captchaQuestion, userAnswer: captchaAnswer, isValid: captchaValid, refresh: refreshCaptcha } = useMathCaptcha()

function fillDemoAccount() {
  email.value = 'admin@ninadentalcare.com'
  password.value = 'NinaDental#2026'
}

async function onSubmit() {
  if (!captchaValid.value) {
    error.value = 'Jawaban verifikasi keamanan salah. Silakan coba lagi.'
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
  <div class="space-y-4">
    <!-- Quick Demo Auto-fill Banner -->
    <div class="p-3.5 rounded-2xl bg-gradient-to-r from-emerald-500/10 via-teal-500/10 to-cyan-500/10 border border-emerald-500/20 backdrop-blur-sm flex items-center justify-between gap-3 shadow-sm">
      <div class="flex items-center gap-2.5">
        <div class="w-8 h-8 rounded-xl bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold text-sm shrink-0">
          🔑
        </div>
        <div class="text-left">
          <p class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
            Uji Coba Sistem Demo
            <UBadge size="xs" color="emerald" variant="subtle">Admin Staf</UBadge>
          </p>
          <p class="text-[11px] text-gray-500 dark:text-gray-400">Klik tombol untuk langsung mengisi kredensial</p>
        </div>
      </div>
      <UButton
        size="xs"
        color="emerald"
        variant="soft"
        icon="i-lucide-zap"
        label="Isi Demo"
        class="font-semibold shrink-0"
        @click="fillDemoAccount"
      />
    </div>

    <UCard :ui="{ root: 'shadow-2xl ring-1 ring-gray-200 dark:ring-gray-800 rounded-3xl backdrop-blur-xl bg-white/90 dark:bg-slate-900/90 overflow-hidden' }">
      <template #header>
        <div class="space-y-1 text-left">
          <div class="flex items-center justify-between">
            <h1 class="text-xl font-bold tracking-tight text-gray-900 dark:text-white flex items-center gap-2">
              Office Portal
            </h1>
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 dark:bg-slate-800 text-gray-600 dark:text-gray-300 border border-slate-200 dark:border-slate-700">
              v1.0.0
            </span>
          </div>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Masukkan akun email resmi staf Nina Dental Care.
          </p>
        </div>
      </template>

      <form
        class="space-y-4"
        @submit.prevent="onSubmit"
      >
        <UFormField
          label="Alamat Email Staf"
          name="email"
        >
          <UInput
            v-model="email"
            type="email"
            placeholder="admin@ninadentalcare.com"
            class="w-full"
            icon="i-lucide-mail"
            autocomplete="username"
            required
            size="lg"
          />
        </UFormField>

        <UFormField
          label="Kata Sandi / Password"
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
            size="lg"
          >
            <template #trailing>
              <UButton
                :icon="showPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                color="neutral"
                variant="link"
                size="sm"
                :padded="false"
                :aria-label="showPassword ? 'Sembunyikan password' : 'Tampilkan password'"
                @click="showPassword = !showPassword"
              />
            </template>
          </UInput>
        </UFormField>

        <div class="flex items-center justify-between pt-1">
          <UCheckbox
            v-model="rememberMe"
            label="Ingat saya di perangkat ini"
          />
          <UButton
            variant="link"
            color="neutral"
            size="xs"
            label="Lupa password?"
            :padded="false"
          />
        </div>

        <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/60 space-y-2">
          <div class="flex items-center justify-between text-xs font-semibold text-gray-700 dark:text-gray-300">
            <span class="flex items-center gap-1.5">
              <UIcon name="i-lucide-shield-check" class="w-4 h-4 text-emerald-500" />
              Verifikasi Keamanan (Captcha)
            </span>
            <UButton
              icon="i-lucide-refresh-cw"
              color="neutral"
              variant="ghost"
              size="xs"
              label="Acak Soal"
              @click="refreshCaptcha"
            />
          </div>

          <div class="flex items-center gap-3">
            <div
              class="flex-1 flex items-center justify-center h-11 rounded-xl bg-emerald-500/10 border border-emerald-500/20 font-mono text-base font-bold text-emerald-700 dark:text-emerald-300 tracking-wider select-none"
              aria-hidden="true"
            >
              {{ captchaQuestion }} = ?
            </div>
            <UInput
              v-model="captchaAnswer"
              type="text"
              inputmode="numeric"
              pattern="[0-9]*"
              placeholder="Hasil"
              class="w-28"
              size="lg"
              required
            />
          </div>
        </div>

        <UAlert
          v-if="error"
          color="error"
          variant="subtle"
          icon="i-lucide-alert-circle"
          :description="error"
          class="rounded-xl"
        />

        <UButton
          type="submit"
          block
          size="lg"
          color="emerald"
          :loading="loading"
          label="Masuk Ke Dashboard"
          icon="i-lucide-log-in"
          class="font-bold shadow-lg shadow-emerald-500/20 hover:brightness-105 transition-all"
        />
      </form>

      <template #footer>
        <div class="space-y-3 text-center">
          <a
            href="/downloads/nina-dental-care.apk"
            download="nina-dental-care.apk"
            target="_blank"
            class="flex items-center justify-between p-3 rounded-2xl border border-emerald-500/20 bg-emerald-50/60 dark:bg-emerald-950/30 hover:bg-emerald-100/60 dark:hover:bg-emerald-900/40 transition-all group cursor-pointer"
          >
            <div class="flex items-center gap-2.5 text-left">
              <div class="w-8 h-8 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-600 dark:text-emerald-400 group-hover:scale-110 transition-transform">
                <UIcon name="i-lucide-smartphone" class="w-4 h-4" />
              </div>
              <div>
                <p class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                  Unduh APK Mobile Staf & Pasien
                  <UBadge size="xs" color="emerald" variant="solid">v1.0.0</UBadge>
                </p>
                <p class="text-[11px] text-gray-500 dark:text-gray-400">File APK Android Siap Install (57.9 MB)</p>
              </div>
            </div>
            <UIcon name="i-lucide-download" class="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          </a>

          <p class="text-[11px] text-gray-400 dark:text-gray-500">
            Akun Staf Demo: <code class="font-mono font-bold text-emerald-600 dark:text-emerald-400">admin@ninadentalcare.com</code>
          </p>
        </div>
      </template>
    </UCard>
  </div>
</template>

