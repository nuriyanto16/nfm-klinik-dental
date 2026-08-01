<script setup lang="ts">
import type { CreateUserInput, PaginatedResponse, StaffUser, UpdateUserInput } from '~/types/api'

definePageMeta({ title: 'User & Role' })

const page = ref(1)
const pageSize = 10
const { data: usersPage, status, refresh, error } = useApiFetch<PaginatedResponse<StaffUser>>(() => `/users?page=${page.value}&pageSize=${pageSize}`)
const users = computed(() => usersPage.value?.data ?? [])
const { data: roles } = useApiFetch<string[]>('/roles')

// ─── Role Config ─────────────────────────────────────────────────────────────
const ROLE_CONFIG: Record<string, {
  label: string
  color: BadgeColor
  icon: string
  desc: string
  perms: string[]
}> = {
  superadmin: {
    label: 'Superadmin',
    color: 'error',
    icon: 'i-lucide-shield',
    desc: 'Akses penuh ke seluruh sistem, termasuk pengaturan pengguna, laporan keuangan, dan konfigurasi klinik.',
    perms: ['Dashboard', 'Reservasi', 'Pasien', 'Dokter', 'Rekam Medis', 'Billing', 'Laporan', 'CMS', 'Inventaris', 'User & Role', 'Notifikasi']
  },
  admin_cabang: {
    label: 'Admin Cabang',
    color: 'warning',
    icon: 'i-lucide-building-2',
    desc: 'Mengelola operasional harian satu cabang: reservasi, pasien, antrian, dan pembayaran.',
    perms: ['Dashboard', 'Reservasi', 'Pasien', 'Antrian', 'Billing', 'Notifikasi']
  },
  finance: {
    label: 'Finance',
    color: 'info',
    icon: 'i-lucide-wallet',
    desc: 'Akses ke laporan keuangan, billing, dan rekonsiliasi pembayaran. Tidak bisa ubah data klinis.',
    perms: ['Dashboard', 'Billing', 'Laporan Keuangan', 'Inventaris (Read Only)']
  },
  perawat: {
    label: 'Perawat',
    color: 'success',
    icon: 'i-lucide-heart-pulse',
    desc: 'Mencatat rekam medis pasien, membantu dokter selama tindakan, dan mengelola inventaris alat.',
    perms: ['Dashboard', 'Pasien (Read)', 'Rekam Medis', 'Inventaris', 'Reservasi (Read)']
  },
  dokter: {
    label: 'Dokter',
    color: 'primary',
    icon: 'i-lucide-stethoscope',
    desc: 'Melihat dan mengisi rekam medis pasien yang dirujuk ke dirinya. Jadwal dikelola oleh Admin Cabang.',
    perms: ['Dashboard', 'Rekam Medis (pasiennya)', 'Reservasi (pasiennya)', 'Pasien (Read)']
  }
}

const roleLabel = Object.fromEntries(Object.entries(ROLE_CONFIG).map(([k, v]) => [k, v.label]))
const roleColor = Object.fromEntries(Object.entries(ROLE_CONFIG).map(([k, v]) => [k, v.color]))

// ─── Dummy fallback data (shown when API has no data yet) ─────────────────────
const DUMMY_USERS: StaffUser[] = [
  { id: '21000000-0000-0000-0000-000000000001', fullName: 'dr. Nina Friski Raisis', email: 'nina@ninaclinic.id', phoneWa: '08112345001', role: 'dokter', isActive: true, createdAt: '2024-01-01T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000002', fullName: 'drg. Friski Raisis', email: 'friski@ninaclinic.id', phoneWa: '08112345002', role: 'dokter', isActive: true, createdAt: '2024-01-01T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000003', fullName: 'drg. Dewi Cantika, Sp.Ort', email: 'dewi@ninaclinic.id', phoneWa: '08112345003', role: 'dokter', isActive: true, createdAt: '2024-01-01T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000010', fullName: 'Sari Dewi', email: 'sari@ninaclinic.id', phoneWa: '08112345010', role: 'admin_cabang', isActive: true, createdAt: '2024-01-15T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000011', fullName: 'Budi Santoso', email: 'budi@ninaclinic.id', phoneWa: '08112345011', role: 'admin_cabang', isActive: true, createdAt: '2024-01-15T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000020', fullName: 'Rina Marlina', email: 'rina@ninaclinic.id', phoneWa: '08112345020', role: 'perawat', isActive: true, createdAt: '2024-02-01T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000021', fullName: 'Ahmad Husaini', email: 'ahmad@ninaclinic.id', phoneWa: '08112345021', role: 'perawat', isActive: true, createdAt: '2024-02-01T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000030', fullName: 'Maya Putri', email: 'maya@ninaclinic.id', phoneWa: '08112345030', role: 'finance', isActive: true, createdAt: '2024-02-15T00:00:00Z' },
  { id: '21000000-0000-0000-0000-000000000040', fullName: 'Admin NDC', email: 'admin@ninaclinic.id', phoneWa: '08112345040', role: 'superadmin', isActive: true, createdAt: '2024-01-01T00:00:00Z' }
]

const displayUsers = computed(() => users.value.length > 0 ? users.value : DUMMY_USERS)

// ─── Stats per role ───────────────────────────────────────────────────────────
const roleStats = computed(() => {
  const list = displayUsers.value
  return Object.fromEntries(
    Object.keys(ROLE_CONFIG).map(role => [role, list.filter(u => u.role === role && u.isActive).length])
  )
})

// ─── Selected role filter ─────────────────────────────────────────────────────
const filterRole = ref<string | null>(null)
const filteredUsers = computed(() =>
  filterRole.value
    ? displayUsers.value.filter(u => u.role === filterRole.value)
    : displayUsers.value
)

const columns = [
  { id: 'avatar', header: '' },
  { accessorKey: 'fullName', header: 'Nama' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'phoneWa', header: 'WhatsApp' },
  { accessorKey: 'role', header: 'Role' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

// ─── Modal create/edit ────────────────────────────────────────────────────────
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  fullName: '',
  email: '',
  phoneWa: '',
  role: 'perawat',
  password: '',
  isActive: true
})

function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.email = ''
  form.phoneWa = ''
  form.role = roles.value?.[0] ?? 'perawat'
  form.password = ''
  form.isActive = true
  formError.value = ''
  showModal.value = true
}

function openEdit(user: StaffUser) {
  editingId.value = user.id
  form.fullName = user.fullName
  form.role = user.role
  form.isActive = user.isActive
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      const payload: UpdateUserInput = { fullName: form.fullName, role: form.role, isActive: form.isActive }
      await apiPut(`/users/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      if (form.password.length < 8) {
        formError.value = 'Password minimal 8 karakter.'
        saving.value = false
        return
      }
      const payload: CreateUserInput = {
        fullName: form.fullName,
        email: form.email,
        phoneWa: form.phoneWa || null,
        role: form.role,
        password: form.password
      }
      await apiPost('/users', payload as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDeactivate(user: StaffUser) {
  if (!confirm(`Nonaktifkan akun ${user.fullName}?`)) return
  try {
    await apiDelete(`/users/${user.id}`)
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}

// ─── Role detail panel ────────────────────────────────────────────────────────
const selectedRoleDetail = ref<string | null>(null)
const roleDetailConfig = computed(() => selectedRoleDetail.value ? ROLE_CONFIG[selectedRoleDetail.value] : null)
</script>

<template>
  <div class="p-4 space-y-5 w-full max-w-none">

    <!-- Page Header -->
    <div class="flex items-start justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-semibold flex items-center gap-2">
          <UIcon name="i-lucide-shield-check" class="w-5 h-5 text-primary" />
          User & Manajemen Role
        </h1>
        <p class="text-sm text-muted mt-1">
          Kelola akun staf klinik beserta hak akses berdasarkan peran (role) masing-masing.
        </p>
      </div>
      <UButton
        icon="i-lucide-user-plus"
        label="Tambah User Baru"
        @click="openCreate"
      />
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <!-- Role Summary Cards -->
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      <button
        v-for="(cfg, roleKey) in ROLE_CONFIG"
        :key="roleKey"
        class="text-left rounded-xl border p-3 transition-all hover:shadow-md"
        :class="filterRole === roleKey ? 'border-primary-400 bg-primary-50 dark:bg-primary-950/30 shadow-sm' : 'border-default bg-card'"
        @click="filterRole = filterRole === roleKey ? null : roleKey"
      >
        <div class="flex items-center gap-2 mb-2">
          <div class="w-8 h-8 rounded-lg flex items-center justify-center" :class="`bg-${cfg.color}-100 dark:bg-${cfg.color}-950/40`">
            <UIcon :name="cfg.icon" class="w-4 h-4" :class="`text-${cfg.color}-600`" />
          </div>
          <UBadge :color="cfg.color" variant="subtle" size="xs">
            {{ roleStats[roleKey] ?? 0 }} aktif
          </UBadge>
        </div>
        <p class="text-sm font-semibold">{{ cfg.label }}</p>
        <p class="text-[11px] text-muted leading-tight mt-0.5 line-clamp-2">{{ cfg.desc }}</p>
      </button>
    </div>

    <!-- Main Content: Table + Role Info Panel -->
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-5 items-start">

      <!-- User Table -->
      <div class="xl:col-span-2 space-y-3">
        <div class="flex items-center justify-between">
          <p class="text-sm text-muted">
            Menampilkan
            <strong>{{ filteredUsers.length }}</strong>
            pengguna
            <span v-if="filterRole">
              dengan role <strong>{{ ROLE_CONFIG[filterRole]?.label }}</strong>
            </span>
          </p>
          <UButton
            v-if="filterRole"
            variant="ghost"
            size="xs"
            icon="i-lucide-x"
            label="Reset Filter"
            @click="filterRole = null"
          />
        </div>

        <UCard :ui="{ body: 'p-0 sm:p-0' }">
          <SkeletonTableSkeleton
            v-if="status === 'pending'"
            :columns="7"
          />
          <UTable
            v-else
            :data="filteredUsers"
            :columns="columns"
            class="cursor-pointer"
            @select="(_e, row) => { selectedRoleDetail = row.original.role }"
          >
            <template #avatar-cell="{ row }">
              <UAvatar
                :text="initials(row.original.fullName)"
                size="sm"
                :class="`bg-${roleColor[row.original.role] ?? 'neutral'}-100 text-${roleColor[row.original.role] ?? 'neutral'}-700`"
              />
            </template>
            <template #fullName-cell="{ row }">
              <div>
                <p class="font-semibold text-sm">{{ row.original.fullName }}</p>
              </div>
            </template>
            <template #role-cell="{ row }">
              <UBadge
                :color="roleColor[row.original.role] ?? 'neutral'"
                variant="subtle"
                class="gap-1"
              >
                <UIcon :name="ROLE_CONFIG[row.original.role]?.icon ?? 'i-lucide-user'" class="w-3 h-3" />
                {{ roleLabel[row.original.role] ?? row.original.role }}
              </UBadge>
            </template>
            <template #isActive-cell="{ row }">
              <UBadge
                :color="row.original.isActive ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
              </UBadge>
            </template>
            <template #actions-cell="{ row }">
              <div class="flex justify-end gap-1">
                <UButton
                  icon="i-lucide-pencil"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  title="Edit User"
                  @click.stop="openEdit(row.original)"
                />
                <UButton
                  v-if="row.original.isActive"
                  icon="i-lucide-user-x"
                  size="xs"
                  color="error"
                  variant="ghost"
                  title="Nonaktifkan"
                  @click.stop="onDeactivate(row.original)"
                />
              </div>
            </template>
          </UTable>
          <PaginationBar
            v-if="usersPage && usersPage.total > 0"
            :page="usersPage.page"
            :total-pages="usersPage.totalPages"
            :total="usersPage.total"
            :page-size="usersPage.pageSize"
            @update:page="page = $event"
          />
        </UCard>
      </div>

      <!-- Role Detail Info Panel -->
      <div class="space-y-3 xl:sticky xl:top-4">
        <UCard v-if="!selectedRoleDetail" class="text-center py-8">
          <UIcon name="i-lucide-info" class="w-8 h-8 text-muted mx-auto mb-2" />
          <p class="text-sm text-muted">Klik baris pengguna atau kartu role<br>untuk melihat detail hak akses.</p>
        </UCard>

        <UCard v-else>
          <template #header>
            <div class="flex items-center gap-3">
              <div
                class="w-10 h-10 rounded-xl flex items-center justify-center"
                :class="`bg-${roleDetailConfig?.color}-100 dark:bg-${roleDetailConfig?.color}-950/40`"
              >
                <UIcon
                  :name="roleDetailConfig?.icon ?? 'i-lucide-user'"
                  class="w-5 h-5"
                  :class="`text-${roleDetailConfig?.color}-600`"
                />
              </div>
              <div>
                <p class="font-bold text-base">{{ roleDetailConfig?.label }}</p>
                <p class="text-xs text-muted">{{ roleStats[selectedRoleDetail] ?? 0 }} pengguna aktif</p>
              </div>
              <UBadge :color="roleDetailConfig?.color" variant="subtle" class="ml-auto">
                {{ selectedRoleDetail }}
              </UBadge>
            </div>
          </template>

          <div class="space-y-4">
            <p class="text-sm text-muted">{{ roleDetailConfig?.desc }}</p>

            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">Hak Akses Menu</p>
              <div class="flex flex-wrap gap-1.5">
                <UBadge
                  v-for="perm in roleDetailConfig?.perms"
                  :key="perm"
                  color="neutral"
                  variant="outline"
                  size="sm"
                  class="gap-1"
                >
                  <UIcon name="i-lucide-check" class="w-3 h-3 text-success-500" />
                  {{ perm }}
                </UBadge>
              </div>
            </div>

            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                Pengguna dengan Role Ini
              </p>
              <ul class="space-y-1.5">
                <li
                  v-for="u in displayUsers.filter(u => u.role === selectedRoleDetail).slice(0, 5)"
                  :key="u.id"
                  class="flex items-center gap-2 text-sm"
                >
                  <UAvatar
                    :text="initials(u.fullName)"
                    size="xs"
                    :class="`bg-${roleDetailConfig?.color}-100 text-${roleDetailConfig?.color}-700`"
                  />
                  <span class="truncate">{{ u.fullName }}</span>
                  <UBadge :color="u.isActive ? 'success' : 'neutral'" variant="subtle" size="xs" class="ml-auto shrink-0">
                    {{ u.isActive ? 'Aktif' : 'Off' }}
                  </UBadge>
                </li>
                <li v-if="displayUsers.filter(u => u.role === selectedRoleDetail).length === 0" class="text-xs text-muted">
                  Belum ada pengguna dengan role ini.
                </li>
              </ul>
            </div>
          </div>
        </UCard>

        <!-- Role Legend -->
        <UCard>
          <template #header>
            <p class="text-sm font-semibold flex items-center gap-2">
              <UIcon name="i-lucide-key-round" class="w-4 h-4 text-primary" />
              Panduan Role
            </p>
          </template>
          <div class="space-y-2 text-xs text-muted">
            <div v-for="(cfg, roleKey) in ROLE_CONFIG" :key="roleKey" class="flex items-start gap-2">
              <UBadge :color="cfg.color" variant="subtle" size="xs" class="shrink-0 mt-0.5">{{ cfg.label }}</UBadge>
              <span>{{ cfg.desc }}</span>
            </div>
          </div>
        </UCard>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Pengguna' : 'Tambah Pengguna Baru'"
    >
      <template #body>
        <form class="space-y-4" @submit.prevent="onSubmit">
          <UFormField label="Nama Lengkap" required>
            <UInput v-model="form.fullName" class="w-full" placeholder="Nama lengkap pengguna" />
          </UFormField>
          <UFormField v-if="!editingId" label="Email" required>
            <UInput v-model="form.email" type="email" class="w-full" placeholder="email@klinik.com" />
          </UFormField>
          <UFormField v-if="!editingId" label="No. WhatsApp">
            <UInput v-model="form.phoneWa" class="w-full" placeholder="08xxxxxxxxxx" />
          </UFormField>
          <UFormField label="Role" required>
            <USelect
              v-model="form.role"
              :items="(roles ?? Object.keys(ROLE_CONFIG)).map(r => ({ label: (ROLE_CONFIG[r]?.label ?? r), value: r }))"
              class="w-full"
            />
            <p v-if="form.role && ROLE_CONFIG[form.role]" class="text-xs text-muted mt-1">
              {{ ROLE_CONFIG[form.role].desc }}
            </p>
          </UFormField>
          <UFormField v-if="!editingId" label="Password" required>
            <UInput
              v-model="form.password"
              type="password"
              class="w-full"
              placeholder="Minimal 8 karakter"
            />
          </UFormField>
          <UFormField v-if="editingId" label="Status Akun">
            <USwitch v-model="form.isActive" :label="form.isActive ? 'Aktif' : 'Nonaktif'" />
          </UFormField>

          <UAlert
            v-if="formError"
            color="error"
            variant="subtle"
            :description="formError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton color="neutral" variant="ghost" label="Batal" @click="showModal = false" />
          <UButton :loading="saving" icon="i-lucide-save" label="Simpan" @click="onSubmit" />
        </div>
      </template>
    </UModal>

  </div>
</template>
