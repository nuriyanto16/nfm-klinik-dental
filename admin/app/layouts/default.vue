<script setup lang="ts">
const { items } = useAdminNav()

const navItems = items.map(item =>
  item.type === 'label'
    ? { type: 'label' as const, label: item.label }
    : { label: item.label, icon: item.icon, to: item.to }
)

const route = useRoute()
const pageTitle = computed(() => (route.meta.title as string) || 'Office Panel')

const authUser = useAuthUser()

const roleLabels: Record<string, string> = {
  superadmin: 'Superadmin',
  admin_cabang: 'Admin Cabang',
  finance: 'Finance',
  perawat: 'Perawat',
  dokter: 'Dokter'
}

async function onLogout() {
  logout()
  await navigateTo('/login')
}

const userMenuItems = [[
  { label: 'Profil', icon: 'i-lucide-user', to: '/profile' },
  { label: 'Keluar', icon: 'i-lucide-log-out', onSelect: onLogout }
]]

// Navbar bell: a lightweight, real-data notification center — low-stock
// inventory and reservations still pending confirmation today — rather
// than a fake WA/push feed (that's the dedicated Notifikasi & Broadcast
// page's job once a 3rd-party gateway is wired up).
const { data: inventory } = useApiFetch<{ name: string, stockQuantity: number, reorderThreshold: number }[]>('/inventory')
const lowStockItems = computed(() => (inventory.value ?? []).filter(i => i.stockQuantity <= i.reorderThreshold))
const { data: reservationsToday } = useApiFetch<{ status: string }[]>(() => {
  const today = new Date().toISOString().slice(0, 10)
  return `/reservations?from=${today}&to=${today}&status=pending`
})
const notificationCount = computed(() => lowStockItems.value.length + (reservationsToday.value?.length ?? 0))
</script>

<template>
  <UDashboardGroup>
    <UDashboardSidebar
      collapsible
      resizable
      :min-size="15"
      :default-size="18"
      class="border-r border-default"
    >
      <template #header="{ collapsed }">
        <AppLogo
          v-if="!collapsed"
          class="px-1"
        />
        <span
          v-else
          class="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-primary-700 text-white text-xs font-semibold"
        >NDC</span>
      </template>

      <UNavigationMenu
        :items="navItems"
        orientation="vertical"
      />

      <template #footer="{ collapsed }">
        <UDropdownMenu
          :items="userMenuItems"
          :content="{ align: 'start' }"
        >
          <UButton
            color="neutral"
            variant="ghost"
            :block="!collapsed"
            :square="collapsed"
            trailing-icon="i-lucide-chevrons-up-down"
          >
            <UAvatar
              icon="i-lucide-user-round"
              size="xs"
              class="bg-primary-100 text-primary-700"
            />
            <span
              v-if="!collapsed"
              class="flex flex-col items-start text-left"
            >
              <span class="text-xs font-medium">{{ authUser?.fullName ?? 'Staf' }}</span>
              <span class="text-[10px] text-muted">{{ roleLabels[authUser?.role ?? ''] ?? authUser?.role }}</span>
            </span>
          </UButton>
        </UDropdownMenu>
      </template>
    </UDashboardSidebar>

    <UDashboardPanel>
      <template #header>
        <UDashboardNavbar :title="pageTitle">
          <template #leading>
            <UDashboardSidebarToggle />
          </template>
          <template #right>
            <UPopover>
              <UChip
                :text="notificationCount"
                :show="notificationCount > 0"
                size="lg"
                color="error"
              >
                <UButton
                  icon="i-lucide-bell"
                  color="neutral"
                  variant="ghost"
                  aria-label="Notifikasi"
                />
              </UChip>
              <template #content>
                <div class="w-72 p-3 space-y-3">
                  <h3 class="text-sm font-semibold">
                    Notifikasi
                  </h3>
                  <div v-if="notificationCount === 0">
                    <p class="text-sm text-muted">
                      Tidak ada notifikasi baru.
                    </p>
                  </div>
                  <div
                    v-if="lowStockItems.length"
                    class="space-y-1"
                  >
                    <NuxtLink
                      to="/inventory"
                      class="flex items-start gap-2 text-sm hover:text-primary"
                    >
                      <UIcon
                        name="i-lucide-alert-triangle"
                        class="mt-0.5 text-warning"
                      />
                      <span>{{ lowStockItems.length }} item stok menipis</span>
                    </NuxtLink>
                  </div>
                  <div v-if="reservationsToday?.length">
                    <NuxtLink
                      to="/reservations"
                      class="flex items-start gap-2 text-sm hover:text-primary"
                    >
                      <UIcon
                        name="i-lucide-calendar-clock"
                        class="mt-0.5 text-info"
                      />
                      <span>{{ reservationsToday.length }} reservasi hari ini menunggu konfirmasi</span>
                    </NuxtLink>
                  </div>
                </div>
              </template>
            </UPopover>
            <UColorModeButton />
          </template>
        </UDashboardNavbar>
      </template>

      <template #body>
        <NuxtPage />
      </template>
    </UDashboardPanel>
  </UDashboardGroup>
</template>
