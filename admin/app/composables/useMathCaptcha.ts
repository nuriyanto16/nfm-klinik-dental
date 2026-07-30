/**
 * Lightweight self-hosted captcha (no external account/site-key needed).
 * Good enough to stop naive scripted submissions on a form that doesn't
 * even have a backend to verify against yet. Swap for a real provider
 * (Cloudflare Turnstile recommended — free, privacy-friendly) once the
 * auth backend exists to verify a token server-side (Fase 1).
 */
export function useMathCaptcha() {
  const a = ref(0)
  const b = ref(0)
  const userAnswer = ref('')

  function refresh() {
    a.value = Math.floor(Math.random() * 8) + 1
    b.value = Math.floor(Math.random() * 8) + 1
    userAnswer.value = ''
  }
  refresh()

  const question = computed(() => `${a.value} + ${b.value}`)
  const isValid = computed(() => userAnswer.value !== '' && Number(userAnswer.value) === a.value + b.value)

  return { question, userAnswer, isValid, refresh }
}
