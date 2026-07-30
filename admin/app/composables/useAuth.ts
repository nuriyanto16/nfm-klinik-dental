export interface AuthUser {
  id: string
  fullName: string
  email: string
  phoneWa: string | null
  role: string
}

const TOKEN_COOKIE = 'ndc_token'
const USER_COOKIE = 'ndc_user'
// Fixed 30-day session for now — the login form's "Ingat saya" checkbox
// doesn't yet shorten this for the unchecked case. Real refresh-token
// rotation/expiry policy is Fase 1 work (see docs/architecture.md §5).
const COOKIE_MAX_AGE = 60 * 60 * 24 * 30

export function useAuthToken() {
  return useCookie<string | null>(TOKEN_COOKIE, { default: () => null, maxAge: COOKIE_MAX_AGE, sameSite: 'lax' })
}

export function useAuthUser() {
  return useCookie<AuthUser | null>(USER_COOKIE, { default: () => null, maxAge: COOKIE_MAX_AGE, sameSite: 'lax' })
}

export function isAuthenticated(): boolean {
  return !!useAuthToken().value
}

export async function login(email: string, password: string): Promise<AuthUser> {
  const data = await $fetch<{ token: string, user: AuthUser }>(apiUrl('/auth/login'), {
    method: 'POST',
    body: { email, password }
  })
  useAuthToken().value = data.token
  useAuthUser().value = data.user
  return data.user
}

export function logout() {
  useAuthToken().value = null
  useAuthUser().value = null
}

/** Merge into $fetch options once RBAC starts checking this on the backend. */
export function authHeaders(): Record<string, string> {
  const token = useAuthToken().value
  return token ? { Authorization: `Bearer ${token}` } : {}
}
