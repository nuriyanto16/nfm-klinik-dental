<script setup lang="ts">
import type { CreateUserInput, PaginatedResponse, StaffUser, UpdateUserInput } from '~/types/api'

definePageMeta({ title: 'Manajemen Pegawai & User' })

export interface ExtendedStaffUser extends StaffUser {
  nik?: string
  sipNumber?: string
  strNumber?: string
  branchName?: string
  shiftWork?: string
  employmentStatus?: string
  joinDate?: string
  emergencyContact?: string
}

// ── API Fetch ───────────────────────────────────────────────────────────────
const page = ref(1)
const pageSize = 20
const { data: usersPage, status, refresh } = useApiFetch<PaginatedResponse<StaffUser>>(() => `/users?page=${page.value}&pageSize=${pageSize}`)

const apiUserList = computed<StaffUser[]>(() => {
  const d = usersPage.value
  if (!d) return []
  if (Array.isArray(d)) return d
  if (Array.isArray((d as any)?.data)) return (d as any).data
  return []
})

// ── Role Config ─────────────────────────────────────────────────────────────
type BadgeColor = 'error' | 'primary' | 'secondary' | 'success' | 'info' | 'warning' | 'neutral'

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
    desc: 'Akses ke laporan keuangan, billing, dan rekonsiliasi pembayaran.',
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
    desc: 'Melihat dan mengisi rekam medis pasien yang dirujuk ke dirinya.',
    perms: ['Dashboard', 'Rekam Medis (pasiennya)', 'Reservasi (pasiennya)', 'Pasien (Read)']
  }
}

const ROLE_OPTIONS = Object.entries(ROLE_CONFIG).map(([v, c]) => ({ value: v, label: c.label }))
const BRANCH_OPTIONS = ['Soreang', 'Baleendah', 'Pusat']
const SHIFT_OPTIONS = ['Shift Pagi (08:00 - 15:00)', 'Shift Siang (10:00 - 17:00)', 'Shift Sore (13:00 - 20:00)', 'Office Hour (08:30 - 17:00)', 'Shift Malam (18:00 - 23:00)']
const EMPLOYMENT_OPTIONS = ['Pegawai Tetap', 'Pegawai Kontrak', 'Dokter Tetap', 'Dokter Spesialis Partner', 'Perawat Kontrak', 'Magang']

// ── Dummy Data ───────────────────────────────────────────────────────────────
const DUMMY_STAFF: ExtendedStaffUser[] = [
  { id: '21-001', fullName: 'Admin Nina Dental Care', email: 'admin@ninadentalcare.com', phoneWa: '+6281113860000', role: 'superadmin', isActive: true, createdAt: '2024-01-01T00:00:00Z', nik: '3204010101900001', branchName: 'Soreang & Baleendah', shiftWork: 'Aktif Selalu', employmentStatus: 'Pegawai Tetap', joinDate: '01 Jan 2024', emergencyContact: '081200001111' },
  { id: '21-002', fullName: 'drg. Nina Marlina, Sp.KG', email: 'drg.nina@ninadentalcare.com', phoneWa: '+6281113860001', role: 'dokter', isActive: true, createdAt: '2024-01-15T00:00:00Z', nik: '3204019284710002', sipNumber: 'SIP.503/421-DINKES/2023', strNumber: 'STR.32.1.2.100.2.19.001', branchName: 'Soreang & Baleendah', shiftWork: 'Shift Pagi (08:00 - 15:00)', employmentStatus: 'Dokter Tetap', joinDate: '15 Jan 2024', emergencyContact: '0812-9388-7766' },
  { id: '21-003', fullName: 'drg. Siti Rahmawati', email: 'drg.siti@ninadentalcare.com', phoneWa: '+6281113860003', role: 'dokter', isActive: true, createdAt: '2024-01-15T00:00:00Z', nik: '3204012508920003', sipNumber: 'SIP.503/422-DINKES/2023', strNumber: 'STR.32.1.2.100.2.19.002', branchName: 'Baleendah', shiftWork: 'Shift Sore (13:00 - 20:00)', employmentStatus: 'Dokter Tetap', joinDate: '15 Jan 2024', emergencyContact: '081344556677' },
  { id: '21-004', fullName: 'drg. Yoga Pratama', email: 'drg.yoga@ninadentalcare.com', phoneWa: '+6281113860004', role: 'dokter', isActive: true, createdAt: '2024-02-01T00:00:00Z', nik: '3204011503920004', sipNumber: 'SIP.503/423-DINKES/2023', branchName: 'Soreang', shiftWork: 'Shift Pagi (08:00 - 15:00)', employmentStatus: 'Dokter Spesialis Partner', joinDate: '01 Feb 2024', emergencyContact: '081200334455' },
  { id: '21-005', fullName: 'drg. Fajar Ramadhan', email: 'drg.fajar@ninadentalcare.com', phoneWa: '+6281113860005', role: 'dokter', isActive: true, createdAt: '2024-02-01T00:00:00Z', nik: '3204011203900005', sipNumber: 'SIP.503/424-DINKES/2023', branchName: 'Soreang & Baleendah', shiftWork: 'Shift Siang (10:00 - 17:00)', employmentStatus: 'Dokter Tetap', joinDate: '01 Feb 2024', emergencyContact: '081322443355' },
  { id: '21-010', fullName: 'Sari Dewi Pratiwi', email: 'sari@ninadentalcare.com', phoneWa: '08112345010', role: 'admin_cabang', isActive: true, createdAt: '2024-01-15T00:00:00Z', nik: '3204016010950002', branchName: 'Soreang', shiftWork: 'Office Hour (08:30 - 17:00)', employmentStatus: 'Pegawai Tetap', joinDate: '15 Jan 2024', emergencyContact: '085711223344' },
  { id: '21-020', fullName: 'Rina Marlina', email: 'rina@ninadentalcare.com', phoneWa: '08112345020', role: 'perawat', isActive: true, createdAt: '2024-02-01T00:00:00Z', nik: '3204015504960004', strNumber: 'STR-P.32.04.55123', branchName: 'Baleendah', shiftWork: 'Shift Pagi (08:00 - 16:00)', employmentStatus: 'Perawat Kontrak', joinDate: '01 Feb 2024', emergencyContact: '081988776655' },
  { id: '21-030', fullName: 'Maya Putri', email: 'maya@ninadentalcare.com', phoneWa: '08112345030', role: 'finance', isActive: true, createdAt: '2024-02-15T00:00:00Z', nik: '3204014409940001', branchName: 'Pusat', shiftWork: 'Office Hour (08:30 - 17:00)', employmentStatus: 'Pegawai Tetap', joinDate: '15 Feb 2024', emergencyContact: '081233445566' }
]

const localUsers = ref<ExtendedStaffUser[]>([...DUMMY_STAFF])

watch(apiUserList, (val) => {
  if (val && val.length > 0) {
    // Merge API with dummy for demo
    const merged = [...val as ExtendedStaffUser[]]
    DUMMY_STAFF.forEach(d => {
      if (!merged.some(u => u.id === d.id)) merged.push(d)
    })
    localUsers.value = merged
  }
}, { immediate: false })

// ── Filters ──────────────────────────────────────────────────────────────────
const searchQuery = ref('')
const filterRole = ref<string>('all')
const filterStatus = ref<string>('all')

const filteredUsers = computed(() => {
  return localUsers.value.filter(u => {
    if (filterRole.value !== 'all' && u.role !== filterRole.value) return false
    if (filterStatus.value === 'active' && !u.isActive) return false
    if (filterStatus.value === 'inactive' && u.isActive) return false
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase()
      return u.fullName.toLowerCase().includes(q) || (u.email || '').toLowerCase().includes(q) || (u.phoneWa || '').includes(q)
    }
    return true
  })
})

// ── Stats ─────────────────────────────────────────────────────────────────────
const statsPerRole = computed(() => {
  return Object.entries(ROLE_CONFIG).map(([key, cfg]) => ({
    key,
    label: cfg.label,
    color: cfg.color,
    icon: cfg.icon,
    count: localUsers.value.filter(u => u.role === key && u.isActive).length
  }))
})

// ── Detail Slideover ──────────────────────────────────────────────────────────
const showDetail = ref(false)
const selectedUser = ref<ExtendedStaffUser | null>(null)

function openDetail(u: ExtendedStaffUser) {
  selectedUser.value = u
  showDetail.value = true
}

// ── Create / Edit Modal ───────────────────────────────────────────────────────
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')
const showPassword = ref(false)

const form = reactive({
  fullName: '',
  email: '',
  phoneWa: '',
  role: 'admin_cabang',
  password: '',
  confirmPassword: '',
  isActive: true,
  // Extended fields
  nik: '',
  sipNumber: '',
  strNumber: '',
  branchName: 'Soreang',
  shiftWork: 'Shift Pagi (08:00 - 15:00)',
  employmentStatus: 'Pegawai Tetap',
  joinDate: '',
  emergencyContact: ''
})

function openCreate() {
  editingId.value = null
  Object.assign(form, {
    fullName: '', email: '', phoneWa: '', role: 'admin_cabang',
    password: '', confirmPassword: '', isActive: true,
    nik: '', sipNumber: '', strNumber: '',
    branchName: 'Soreang', shiftWork: 'Shift Pagi (08:00 - 15:00)',
    employmentStatus: 'Pegawai Tetap', joinDate: '', emergencyContact: ''
  })
  formError.value = ''
  showModal.value = true
}

function openEdit(u: ExtendedStaffUser, closeDetailFirst = false) {
  if (closeDetailFirst) showDetail.value = false
  editingId.value = u.id
  Object.assign(form, {
    fullName: u.fullName,
    email: u.email ?? '',
    phoneWa: u.phoneWa ?? '',
    role: u.role,
    password: '',
    confirmPassword: '',
    isActive: u.isActive,
    nik: u.nik ?? '',
    sipNumber: u.sipNumber ?? '',
    strNumber: u.strNumber ?? '',
    branchName: u.branchName ?? 'Soreang',
    shiftWork: u.shiftWork ?? 'Shift Pagi (08:00 - 15:00)',
    employmentStatus: u.employmentStatus ?? 'Pegawai Tetap',
    joinDate: u.joinDate ?? '',
    emergencyContact: u.emergencyContact ?? ''
  })
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.fullName.trim() || !form.email.trim()) {
    formError.value = 'Nama lengkap dan email wajib diisi.'
    return
  }
  if (!editingId.value && !form.password) {
    formError.value = 'Password wajib diisi untuk user baru.'
    return
  }
  if (!editingId.value && form.password !== form.confirmPassword) {
    formError.value = 'Password dan konfirmasi password tidak cocok.'
    return
  }

  saving.value = true
  formError.value = ''
  try {
    const extData: Partial<ExtendedStaffUser> = {
      nik: form.nik || undefined,
      sipNumber: form.sipNumber || undefined,
      strNumber: form.strNumber || undefined,
      branchName: form.branchName,
      shiftWork: form.shiftWork,
      employmentStatus: form.employmentStatus,
      joinDate: form.joinDate || undefined,
      emergencyContact: form.emergencyContact || undefined
    }

    if (editingId.value) {
      const idx = localUsers.value.findIndex(u => u.id === editingId.value)
      if (idx !== -1) {
        localUsers.value[idx] = {
          ...localUsers.value[idx],
          fullName: form.fullName,
          email: form.email,
          phoneWa: form.phoneWa || null,
          role: form.role,
          isActive: form.isActive,
          ...extData
        }
        if (selectedUser.value?.id === editingId.value) {
          selectedUser.value = { ...localUsers.value[idx] }
        }
      }
      try {
        await $fetch(apiUrl(`/users/${editingId.value}`), {
          method: 'PUT',
          body: { fullName: form.fullName, role: form.role, isActive: form.isActive } as UpdateUserInput
        })
      } catch {}
    } else {
      const payload: CreateUserInput = {
        fullName: form.fullName,
        email: form.email,
        phoneWa: form.phoneWa || null,
        role: form.role,
        password: form.password
      }
      let newId = `local-${Date.now()}`
      try {
        const created = await $fetch<StaffUser>(apiUrl('/users'), { method: 'POST', body: payload })
        if (created?.id) newId = created.id
      } catch {}
      localUsers.value.unshift({
        id: newId,
        fullName: form.fullName,
        email: form.email,
        phoneWa: form.phoneWa || null,
        role: form.role,
        isActive: form.isActive,
        createdAt: new Date().toISOString(),
        ...extData
      })
    }
    showModal.value = false
  } catch (err: any) {
    formError.value = err?.data?.message ?? err?.message ?? 'Gagal menyimpan data user.'
  } finally {
    saving.value = false
  }
}

async function toggleStatus(u: ExtendedStaffUser) {
  const newStatus = !u.isActive
  const label = newStatus ? 'aktifkan' : 'nonaktifkan'
  if (!confirm(`${newStatus ? 'Aktifkan' : 'Nonaktifkan'} user "${u.fullName}"?`)) return
  const idx = localUsers.value.findIndex(x => x.id === u.id)
  if (idx !== -1) localUsers.value[idx] = { ...localUsers.value[idx], isActive: newStatus }
  if (selectedUser.value?.id === u.id) selectedUser.value = { ...localUsers.value[idx] }
  try { await $fetch(apiUrl(`/users/${u.id}`), { method: 'PUT', body: { fullName: u.fullName, role: u.role, isActive: newStatus } }) } catch {}
}

async function deleteUser(u: ExtendedStaffUser) {
  if (!confirm(`Hapus user "${u.fullName}"? Tindakan ini tidak bisa dibatalkan.`)) return
  localUsers.value = localUsers.value.filter(x => x.id !== u.id)
  if (selectedUser.value?.id === u.id) showDetail.value = false
  try { await $fetch(apiUrl(`/users/${u.id}`), { method: 'DELETE' }) } catch {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function initials(name?: string) {
  if (!name) return '?'
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

function safeDateShort(iso?: string | null): string {
  if (!iso || typeof iso !== 'string') return '—'
  try {
    const d = iso.includes('T') ? new Date(iso) : new Date(`${iso}T00:00:00`)
    return isNaN(d.getTime()) ? '—' : new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }).format(d)
  } catch { return '—' }
}

const showRoleInfoModal = ref(false)
const selectedRoleInfo = ref<string>('superadmin')
</script>

<template>
  <div class="p-4 space-y-5 w-full max-w-none">

    <!-- ── Header ── -->
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">Manajemen Pegawai & User</h1>
        <p class="text-xs text-gray-500 mt-0.5">
          Kelola dokter, perawat, admin cabang, dan staff dengan CRUD lengkap, role, dan izin akses.
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-info"
          label="Info Role"
          color="neutral"
          variant="outline"
          size="sm"
          @click="showRoleInfoModal = true"
        />
        <UButton
          icon="i-lucide-user-plus"
          label="+ Tambah User"
          color="primary"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- ── Stats Per Role ── -->
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      <div
        v-for="s in statsPerRole"
        :key="s.key"
        class="p-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 flex items-center gap-3 cursor-pointer hover:border-primary-300 transition-colors"
        :class="{ 'border-primary ring-1 ring-primary/30': filterRole === s.key }"
        @click="filterRole = filterRole === s.key ? 'all' : s.key"
      >
        <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-gray-100 dark:bg-gray-700 shrink-0">
          <UIcon :name="s.icon" class="w-4 h-4 text-gray-600 dark:text-gray-300" />
        </div>
        <div class="min-w-0">
          <div class="text-xs text-gray-500 truncate">{{ s.label }}</div>
          <div class="text-xl font-extrabold text-gray-900 dark:text-white">{{ s.count }}</div>
        </div>
      </div>
    </div>

    <!-- ── Filter Toolbar ── -->
    <div class="flex flex-col sm:flex-row items-start sm:items-center gap-2 bg-white dark:bg-gray-800 p-3 rounded-xl border border-gray-200 dark:border-gray-700">
      <!-- Status Filter -->
      <div class="flex items-center gap-1 bg-gray-100 dark:bg-gray-900 p-0.5 rounded-lg">
        <button
          v-for="opt in [{ v: 'all', l: 'Semua' }, { v: 'active', l: 'Aktif' }, { v: 'inactive', l: 'Nonaktif' }]"
          :key="opt.v"
          class="px-3 py-1 text-xs font-semibold rounded-md transition-all"
          :class="filterStatus === opt.v ? 'bg-white dark:bg-gray-700 text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
          @click="filterStatus = opt.v"
        >
          {{ opt.l }}
        </button>
      </div>

      <!-- Role Filter -->
      <select
        v-model="filterRole"
        class="px-2 py-1.5 text-xs rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-400"
      >
        <option value="all">Semua Role</option>
        <option v-for="r in ROLE_OPTIONS" :key="r.value" :value="r.value">{{ r.label }}</option>
      </select>

      <!-- Search -->
      <UInput
        v-model="searchQuery"
        icon="i-lucide-search"
        placeholder="Cari nama / email / WA..."
        size="sm"
        class="w-full sm:w-64 ml-auto"
      />

      <span class="text-xs text-gray-400 whitespace-nowrap">{{ filteredUsers.length }} user</span>
    </div>

    <!-- ── Main Table ── -->
    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <div v-if="status === 'pending'" class="flex items-center justify-center py-10 text-gray-400 gap-2 text-sm">
        <UIcon name="i-lucide-loader-circle" class="w-5 h-5 animate-spin" />
        Memuat data...
      </div>
      <div v-else-if="filteredUsers.length === 0" class="py-12 text-center text-gray-400 text-sm">
        <UIcon name="i-lucide-users" class="w-8 h-8 mx-auto mb-2" />
        <p>Tidak ada user ditemukan</p>
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
          <thead class="bg-gray-50 dark:bg-gray-800/60 text-[11px] font-bold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-4 py-3">Nama Pegawai</th>
              <th class="px-4 py-3">Email & WA</th>
              <th class="px-4 py-3">Role / Jabatan</th>
              <th class="px-4 py-3">Cabang & Shift</th>
              <th class="px-4 py-3">Status</th>
              <th class="px-4 py-3">Bergabung</th>
              <th class="px-4 py-3 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
            <tr
              v-for="u in filteredUsers"
              :key="u.id"
              class="hover:bg-primary-50/40 dark:hover:bg-primary-900/10 transition-colors cursor-pointer"
              @click="openDetail(u)"
            >
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="flex items-center gap-3">
                  <div
                    class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
                    :class="u.isActive ? 'bg-primary-100 dark:bg-primary-900/40 text-primary' : 'bg-gray-100 dark:bg-gray-700 text-gray-400'"
                  >
                    {{ initials(u.fullName) }}
                  </div>
                  <div>
                    <div class="font-bold text-gray-900 dark:text-white">{{ u.fullName }}</div>
                    <div v-if="u.sipNumber" class="text-[10px] text-emerald-600 dark:text-emerald-400 font-mono font-medium">SIP: {{ u.sipNumber }}</div>
                    <div v-if="u.nik" class="text-[10px] text-gray-400 font-mono">NIK: {{ u.nik }}</div>
                  </div>
                </div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="text-gray-800 dark:text-gray-200">{{ u.email || '—' }}</div>
                <div class="text-[11px] text-gray-400 font-mono">{{ u.phoneWa || '—' }}</div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <UBadge
                  :color="ROLE_CONFIG[u.role]?.color ?? 'neutral'"
                  variant="subtle"
                  size="xs"
                >
                  <UIcon :name="ROLE_CONFIG[u.role]?.icon ?? 'i-lucide-user'" class="w-3 h-3 mr-1" />
                  {{ ROLE_CONFIG[u.role]?.label ?? u.role }}
                </UBadge>
                <div class="text-[10px] text-gray-400 mt-0.5">{{ u.employmentStatus ?? '—' }}</div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="font-semibold text-gray-800 dark:text-gray-200 text-xs">{{ u.branchName || '—' }}</div>
                <div class="text-[10px] text-gray-400">{{ u.shiftWork || '—' }}</div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <UBadge :color="u.isActive ? 'success' : 'neutral'" variant="soft" size="xs">
                  {{ u.isActive ? 'Aktif Bekerja' : 'Non-aktif' }}
                </UBadge>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-gray-400">
                {{ u.joinDate ?? safeDateShort(u.createdAt) }}
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-right" @click.stop>
                <div class="flex items-center justify-end gap-1">
                  <UButton
                    size="xs"
                    variant="ghost"
                    color="neutral"
                    icon="i-lucide-eye"
                    title="Lihat Detail"
                    @click="openDetail(u)"
                  />
                  <UButton
                    size="xs"
                    variant="ghost"
                    color="primary"
                    icon="i-lucide-edit-2"
                    title="Edit"
                    @click="openEdit(u)"
                  />
                  <UButton
                    size="xs"
                    variant="ghost"
                    :color="u.isActive ? 'warning' : 'success'"
                    :icon="u.isActive ? 'i-lucide-user-x' : 'i-lucide-user-check'"
                    :title="u.isActive ? 'Nonaktifkan' : 'Aktifkan'"
                    @click="toggleStatus(u)"
                  />
                  <UButton
                    size="xs"
                    variant="ghost"
                    color="error"
                    icon="i-lucide-trash-2"
                    title="Hapus"
                    @click="deleteUser(u)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </UCard>

    <!-- ════════════════════════════════════════ -->
    <!-- Detail Slideover (Profil Lengkap) -->
    <!-- ════════════════════════════════════════ -->
    <USlideover v-model:open="showDetail" side="right" title="Profil Pegawai">
      <template #body>
        <div v-if="selectedUser" class="space-y-5 p-1">
          <!-- Header -->
          <div class="flex items-start gap-4">
            <div
              class="w-16 h-16 rounded-2xl flex items-center justify-center text-xl font-extrabold shrink-0"
              :class="selectedUser.isActive ? 'bg-primary-100 dark:bg-primary-900/40 text-primary' : 'bg-gray-100 dark:bg-gray-700 text-gray-400'"
            >
              {{ initials(selectedUser.fullName) }}
            </div>
            <div class="min-w-0">
              <h2 class="font-bold text-base text-gray-900 dark:text-white leading-tight">{{ selectedUser.fullName }}</h2>
              <div class="flex flex-wrap gap-1.5 mt-1.5">
                <UBadge :color="ROLE_CONFIG[selectedUser.role]?.color ?? 'neutral'" variant="subtle" size="xs">
                  <UIcon :name="ROLE_CONFIG[selectedUser.role]?.icon ?? 'i-lucide-user'" class="w-3 h-3 mr-1" />
                  {{ ROLE_CONFIG[selectedUser.role]?.label ?? selectedUser.role }}
                </UBadge>
                <UBadge :color="selectedUser.isActive ? 'success' : 'neutral'" variant="soft" size="xs">
                  {{ selectedUser.isActive ? 'Aktif' : 'Non-aktif' }}
                </UBadge>
              </div>
            </div>
          </div>

          <!-- Contact Info -->
          <div class="p-3 bg-gray-50 dark:bg-gray-800 rounded-xl space-y-2">
            <h4 class="text-[10px] font-bold uppercase tracking-wider text-gray-500">KONTAK</h4>
            <div class="grid grid-cols-1 gap-2 text-xs">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-mail" class="w-4 h-4 text-gray-400 shrink-0" />
                <span class="text-gray-800 dark:text-gray-200 break-all">{{ selectedUser.email || '—' }}</span>
              </div>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-phone" class="w-4 h-4 text-gray-400 shrink-0" />
                <span class="font-mono text-gray-800 dark:text-gray-200">{{ selectedUser.phoneWa || '—' }}</span>
              </div>
            </div>
          </div>

          <!-- Legalitas -->
          <div class="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-xl space-y-2">
            <h4 class="text-[10px] font-bold uppercase tracking-wider text-blue-600 dark:text-blue-400">LEGALITAS & IDENTITAS</h4>
            <div class="grid grid-cols-1 gap-2 text-xs">
              <div v-if="selectedUser.nik">
                <span class="text-gray-400 block">NIK:</span>
                <span class="font-mono font-bold text-gray-800 dark:text-gray-200">{{ selectedUser.nik }}</span>
              </div>
              <div v-if="selectedUser.sipNumber">
                <span class="text-gray-400 block">No. SIP (Izin Praktik):</span>
                <span class="font-mono text-emerald-600 dark:text-emerald-400 font-bold">{{ selectedUser.sipNumber }}</span>
              </div>
              <div v-if="selectedUser.strNumber">
                <span class="text-gray-400 block">No. STR:</span>
                <span class="font-mono text-blue-600 dark:text-blue-400 font-bold">{{ selectedUser.strNumber }}</span>
              </div>
              <div>
                <span class="text-gray-400 block">Status Kepegawaian:</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ selectedUser.employmentStatus || '—' }}</span>
              </div>
            </div>
          </div>

          <!-- Penugasan -->
          <div class="p-3 bg-violet-50 dark:bg-violet-900/20 rounded-xl space-y-2">
            <h4 class="text-[10px] font-bold uppercase tracking-wider text-violet-600 dark:text-violet-400">PENUGASAN & SHIFT</h4>
            <div class="grid grid-cols-2 gap-2 text-xs">
              <div>
                <span class="text-gray-400 block">Cabang:</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ selectedUser.branchName || '—' }}</span>
              </div>
              <div>
                <span class="text-gray-400 block">Shift Kerja:</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ selectedUser.shiftWork || '—' }}</span>
              </div>
              <div>
                <span class="text-gray-400 block">Bergabung:</span>
                <span class="text-gray-800 dark:text-gray-200">{{ selectedUser.joinDate || safeDateShort(selectedUser.createdAt) }}</span>
              </div>
              <div>
                <span class="text-gray-400 block">Kontak Darurat:</span>
                <span class="font-mono text-gray-800 dark:text-gray-200">{{ selectedUser.emergencyContact || '—' }}</span>
              </div>
            </div>
          </div>

          <!-- Izin Akses (Role Permissions) -->
          <div class="p-3 bg-gray-50 dark:bg-gray-800 rounded-xl space-y-2">
            <h4 class="text-[10px] font-bold uppercase tracking-wider text-gray-500">IZIN AKSES (ROLE: {{ ROLE_CONFIG[selectedUser.role]?.label ?? selectedUser.role }})</h4>
            <p class="text-[11px] text-gray-500 italic">{{ ROLE_CONFIG[selectedUser.role]?.desc }}</p>
            <div class="flex flex-wrap gap-1.5 mt-1">
              <UBadge
                v-for="perm in ROLE_CONFIG[selectedUser.role]?.perms ?? []"
                :key="perm"
                color="neutral"
                variant="outline"
                size="xs"
              >
                {{ perm }}
              </UBadge>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex gap-2 pt-2 border-t border-gray-100 dark:border-gray-800">
            <UButton
              icon="i-lucide-edit-2"
              label="Edit Data"
              color="primary"
              class="flex-1"
              @click="openEdit(selectedUser, true)"
            />
            <UButton
              :icon="selectedUser.isActive ? 'i-lucide-user-x' : 'i-lucide-user-check'"
              :label="selectedUser.isActive ? 'Nonaktifkan' : 'Aktifkan'"
              :color="selectedUser.isActive ? 'warning' : 'success'"
              variant="outline"
              @click="toggleStatus(selectedUser)"
            />
            <UButton
              icon="i-lucide-trash-2"
              color="error"
              variant="ghost"
              @click="deleteUser(selectedUser)"
            />
          </div>
        </div>
      </template>
    </USlideover>

    <!-- ════════════════════════════════════════ -->
    <!-- Create / Edit Modal -->
    <!-- ════════════════════════════════════════ -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Data Pegawai' : 'Tambah User / Pegawai Baru'"
    >
      <template #body>
        <form class="space-y-5" @submit.prevent="onSubmit">
          <!-- Error -->
          <div v-if="formError" class="p-2.5 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg text-xs text-red-600">
            {{ formError }}
          </div>

          <!-- ── Bagian 1: Data Akun ── -->
          <div class="space-y-3">
            <h3 class="text-xs font-bold uppercase tracking-wider text-primary border-b border-primary-100 dark:border-primary-900 pb-1">
              Data Akun & Login
            </h3>

            <div>
              <label class="block text-xs font-semibold mb-1">Nama Lengkap <span class="text-red-500">*</span></label>
              <UInput v-model="form.fullName" placeholder="mis. drg. Nina Marlina, Sp.KG" :disabled="saving" />
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">Email <span class="text-red-500">*</span></label>
                <UInput v-model="form.email" type="email" placeholder="nama@klinik.id" :disabled="saving" />
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">No. WhatsApp</label>
                <UInput v-model="form.phoneWa" type="tel" placeholder="08XXXXXXXXXX" :disabled="saving" />
              </div>
            </div>

            <!-- Password (only for create, or optional for edit) -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">
                  Password <span v-if="!editingId" class="text-red-500">*</span>
                  <span v-else class="text-gray-400 font-normal">(kosongkan jika tidak ubah)</span>
                </label>
                <div class="relative">
                  <UInput
                    v-model="form.password"
                    :type="showPassword ? 'text' : 'password'"
                    placeholder="Password baru"
                    :disabled="saving"
                  />
                </div>
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">Konfirmasi Password</label>
                <UInput
                  v-model="form.confirmPassword"
                  :type="showPassword ? 'text' : 'password'"
                  placeholder="Ulangi password"
                  :disabled="saving"
                />
              </div>
            </div>
            <label class="flex items-center gap-2 text-xs text-gray-500 cursor-pointer select-none">
              <input v-model="showPassword" type="checkbox" class="rounded text-primary"> Tampilkan password
            </label>
          </div>

          <!-- ── Bagian 2: Role & Status ── -->
          <div class="space-y-3">
            <h3 class="text-xs font-bold uppercase tracking-wider text-violet-600 border-b border-violet-100 dark:border-violet-900 pb-1">
              Role & Izin Akses
            </h3>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">Role <span class="text-red-500">*</span></label>
                <select
                  v-model="form.role"
                  class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                  :disabled="saving"
                >
                  <option v-for="r in ROLE_OPTIONS" :key="r.value" :value="r.value">{{ r.label }}</option>
                </select>
              </div>
              <div class="flex items-end">
                <label class="flex items-center gap-2 text-sm font-semibold cursor-pointer pb-2">
                  <input v-model="form.isActive" type="checkbox" class="w-4 h-4 rounded text-primary">
                  Status Aktif
                </label>
              </div>
            </div>

            <!-- Role description -->
            <div v-if="form.role && ROLE_CONFIG[form.role]" class="p-2.5 bg-gray-50 dark:bg-gray-900 rounded-lg text-[11px] text-gray-600 dark:text-gray-400">
              <p class="font-semibold mb-1">{{ ROLE_CONFIG[form.role].label }}:</p>
              <p class="mb-1.5">{{ ROLE_CONFIG[form.role].desc }}</p>
              <div class="flex flex-wrap gap-1">
                <span
                  v-for="perm in ROLE_CONFIG[form.role].perms"
                  :key="perm"
                  class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 px-1.5 py-0.5 rounded text-[10px]"
                >{{ perm }}</span>
              </div>
            </div>
          </div>

          <!-- ── Bagian 3: Data Kepegawaian ── -->
          <div class="space-y-3">
            <h3 class="text-xs font-bold uppercase tracking-wider text-emerald-600 border-b border-emerald-100 dark:border-emerald-900 pb-1">
              Data Kepegawaian & Legalitas
            </h3>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">NIK</label>
                <UInput v-model="form.nik" placeholder="16 digit NIK" maxlength="16" :disabled="saving" />
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">Status Kepegawaian</label>
                <select
                  v-model="form.employmentStatus"
                  class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option v-for="e in EMPLOYMENT_OPTIONS" :key="e" :value="e">{{ e }}</option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">No. SIP (Izin Praktik)</label>
                <UInput v-model="form.sipNumber" placeholder="SIP.503/XXX-DINKES/YYYY" :disabled="saving" />
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">No. STR</label>
                <UInput v-model="form.strNumber" placeholder="STR.32.X.X.XXX..." :disabled="saving" />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">Cabang Penugasan</label>
                <select
                  v-model="form.branchName"
                  class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option v-for="b in BRANCH_OPTIONS" :key="b" :value="b">{{ b }}</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">Shift Kerja</label>
                <select
                  v-model="form.shiftWork"
                  class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option v-for="s in SHIFT_OPTIONS" :key="s" :value="s">{{ s }}</option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold mb-1">Tanggal Bergabung</label>
                <UInput v-model="form.joinDate" type="date" :disabled="saving" />
              </div>
              <div>
                <label class="block text-xs font-semibold mb-1">Kontak Darurat</label>
                <UInput v-model="form.emergencyContact" placeholder="081234567 (Nama)" :disabled="saving" />
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="neutral" variant="ghost" :disabled="saving" @click="showModal = false" />
            <UButton
              type="submit"
              :label="saving ? 'Menyimpan...' : (editingId ? 'Simpan Perubahan' : 'Tambah User')"
              color="primary"
              :loading="saving"
            />
          </div>
        </form>
      </template>
    </UModal>

    <!-- ════════════════════════════════════════ -->
    <!-- Role Info Modal -->
    <!-- ════════════════════════════════════════ -->
    <UModal v-model:open="showRoleInfoModal" title="Panduan Role & Izin Akses">
      <template #body>
        <div class="space-y-3">
          <div
            v-for="(cfg, key) in ROLE_CONFIG"
            :key="key"
            class="p-3 rounded-xl border border-gray-200 dark:border-gray-700 space-y-2"
          >
            <div class="flex items-center gap-2">
              <UBadge :color="cfg.color" variant="subtle" size="sm">
                <UIcon :name="cfg.icon" class="w-3.5 h-3.5 mr-1" />
                {{ cfg.label }}
              </UBadge>
            </div>
            <p class="text-xs text-gray-500">{{ cfg.desc }}</p>
            <div class="flex flex-wrap gap-1">
              <span
                v-for="perm in cfg.perms"
                :key="perm"
                class="bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 text-[10px] px-1.5 py-0.5 rounded font-medium"
              >{{ perm }}</span>
            </div>
          </div>
        </div>
        <div class="flex justify-end mt-4 pt-4 border-t border-gray-100 dark:border-gray-800">
          <UButton label="Tutup" color="neutral" variant="outline" @click="showRoleInfoModal = false" />
        </div>
      </template>
    </UModal>
  </div>
</template>
