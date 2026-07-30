/**
 * Fetches from core-api. Uses the internal docker-network hostname during
 * SSR (inside the admin-frontend container) and the host-mapped URL on the
 * client (browser) — see `apiBaseInternal` / `public.apiBase` in
 * nuxt.config.ts.
 *
 * `key` overrides Nuxt's default useFetch cache key (which is derived from
 * the URL) — pass one whenever a page calls this twice with the *same* path
 * for two logically separate views (e.g. a filtered list vs. an
 * unfiltered calendar), otherwise both calls collapse onto the same cached
 * ref and writing to one silently overwrites the other.
 *
 * `path` can be a plain string or a getter function — pass a getter for
 * paginated/filtered lists so the URL (and therefore the fetch) reacts to
 * page/filter state changes, same as Nuxt's own `useFetch(() => url)`.
 */
export function useApiFetch<T>(path: string | (() => string), key?: string) {
  const config = useRuntimeConfig()
  const base = import.meta.server ? config.apiBaseInternal : config.public.apiBase
  const url = typeof path === 'function' ? () => `${base}${path()}` : `${base}${path}`
  return useFetch<T>(url, key ? { key } : {})
}
