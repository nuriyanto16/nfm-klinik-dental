/**
 * Gates every admin page behind a login. Only the data endpoints are still
 * unauthenticated on the backend (see docs/architecture.md §5) — this
 * middleware is what actually stops someone from opening the office panel
 * without logging in first.
 */
export default defineNuxtRouteMiddleware((to) => {
  const authed = isAuthenticated()

  if (!authed && to.path !== '/login') {
    return navigateTo('/login')
  }
  if (authed && to.path === '/login') {
    return navigateTo('/')
  }
})
