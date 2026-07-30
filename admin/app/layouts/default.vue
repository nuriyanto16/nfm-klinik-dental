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
  { label: 'Profil', icon: 'i-lucide-user' },
  { label: 'Keluar', icon: 'i-lucide-log-out', onSelect: onLogout }
]]
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
            <UButton
              icon="i-lucide-bell"
              color="neutral"
              variant="ghost"
              aria-label="Notifikasi"
            />
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
