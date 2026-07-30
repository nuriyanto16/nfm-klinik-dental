/**
 * Mutations always run client-side (triggered by a user action), unlike
 * useApiFetch's GET calls which also run during SSR — so these always use
 * the public/host-mapped base URL, never the internal docker hostname.
 */
export function apiUrl(path: string): string {
  const config = useRuntimeConfig()
  return `${config.public.apiBase}${path}`
}

export async function apiPost<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return await $fetch<T>(apiUrl(path), { method: 'POST', body, headers: authHeaders() })
}

export async function apiPut<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return await $fetch<T>(apiUrl(path), { method: 'PUT', body, headers: authHeaders() })
}

export async function apiPatch<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return await $fetch<T>(apiUrl(path), { method: 'PATCH', body, headers: authHeaders() })
}

export async function apiDelete(path: string): Promise<void> {
  await $fetch(apiUrl(path), { method: 'DELETE', headers: authHeaders() })
}

// core-api's default Fiber error handler sends the message as a plain-text
// body (no JSON envelope), so this covers both that and any future JSON
// `{ message }` shape without caring which one shows up.
export function apiErrorMessage(error: unknown): string {
  if (error && typeof error === 'object') {
    const e = error as { data?: unknown, message?: string }
    if (typeof e.data === 'string' && e.data) return e.data
    if (e.data && typeof e.data === 'object' && 'message' in e.data) return String((e.data as { message: unknown }).message)
    if (e.message) return e.message
  }
  return 'Terjadi kesalahan tak terduga'
}
