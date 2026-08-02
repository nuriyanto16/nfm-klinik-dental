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

const page = ref(1)
const pageSize = 10
const { data: usersPage, status, refresh, error } = useApiFetch<PaginatedResponse<StaffUser>>(() => `/users?page=${page.value}&pageSize=${pageSize}`)
const users = computed(() => usersPage.value?.data ?? [])
const { data: roles } = useApiFetch<string[]>('/roles')

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

const DUMMY_STAFF: ExtendedStaffUser[] = [
  { id: '21000000-0000-0000-0000-000000000001', fullName: 'drg. Friski Raisis, Sp.Ort', email: 'friski@ninaclinic.id', phoneWa: '08112345001', role: 'dokter', isActive: true, createdAt: '2024-01-01T00:00:00Z', nik: '3204011204900001', sipNumber: 'SIP.503/421-DINKES/2023', strNumber: 'STR.32.1.2.100.2.19.123456', branchName: 'Soreang', shiftWork: 'Shift Pagi (08:00 - 15:00)', employmentStatus: 'Dokter Spesialis Partner', joinDate: '15 Jan 2024', emergencyContact: '081299887766 (Istri)' },
  { id: '21000000-0000-0000-0000-000000000002', fullName: 'drg. Siti Aminah', email: 'siti@ninaclinic.id', phoneWa: '08112345002', role: 'dokter', isActive: true, createdAt: '2024-01-01T00:00:00Z', nik: '3204012508920003', sipNumber: 'SIP.503/422-DINKES/2023', strNumber: 'STR.32.1.2.100.2.19.654321', branchName: 'Baleendah', shiftWork: 'Shift Sore (13:00 - 20:00)', employmentStatus: 'Dokter Tetap', joinDate: '01 Feb 2024', emergencyContact: '081344556677 (Suami)' },
  { id: '21000000-0000-0000-0000-000000000010', fullName: 'Sari Dewi', email: 'sari@ninaclinic.id', phoneWa: '08112345010', role: 'admin_cabang', isActive: true, createdAt: '2024-01-15T00:00:00Z', nik: '3204016010950002', branchName: 'Soreang', shiftWork: 'Shift Pagi (08:00 - 16:00)', employmentStatus: 'Pegawai Tetap', joinDate: '15 Jan 2024', emergencyContact: '085711223344 (Ibu)' },
  { id: '21000000-0000-0000-0000-000000000020', fullName: 'Rina Marlina', email: 'rina@ninaclinic.id', phoneWa: '08112345020', role: 'perawat', isActive: true, createdAt: '2024-02-01T00:00:00Z', nik: '3204015504960004', strNumber: 'STR-P.32.04.55123', branchName: 'Baleendah', shiftWork: 'Shift Pagi (08:00 - 16:00)', employmentStatus: 'Perawat Kontrak', joinDate: '01 Feb 2024', emergencyContact: '081988776655 (Ayah)' },
  { id: '21000000-0000-0000-0000-000000000030', fullName: 'Maya Putri', email: 'maya@ninaclinic.id', phoneWa: '08112345030', role: 'finance', isActive: true, createdAt: '2024-02-15T00:00:00Z', nik: '3204014409940001', branchName: 'Pusat', shiftWork: 'Office Hour (08:30 - 17:00)', employmentStatus: 'Pegawai Tetap', joinDate: '15 Feb 2024', emergencyContact: '081233445566 (Kakak)' }
]

const displayUsers = computed<ExtendedStaffUser[]>(() => {
  if (users.value && users.value.length > 0) return users.value
  return DUMMY_STAFF
})

const filterRole = ref<string | null>(null)
const filteredUsers = computed(() =>
  filterRole.value
    ? displayUsers.value.filter(u => u.role === filterRole.value)
    : displayUsers.value
)

const columns = [
  { id: 'avatar', header: '' },
  { accessorKey: 'fullName', header: 'Nama Pegawai' },
  { accessorKey: 'email', header: 'Email / NIK' },
  { accessorKey: 'phoneWa', header: 'WhatsApp' },
  { accessorKey: 'role', header: 'Jabatan / Role' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: 'Aksi' }
]

const showModal = ref(false)
const showProfileModal = ref(false)
const selectedStaff = ref<ExtendedStaffUser | null>(null)

function openProfile(staff: ExtendedStaffUser) {
  selectedStaff.value = staff
  showProfileModal.value = true
}

function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          Manajemen Pegawai & Profil Lengkap
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Kelola data dokter, perawat, admin cabang, dan staff kasir lengkap dengan nomor SIP/STR, shift kerja, dan cabang penugasan.
        </p>
      </div>

      <UButton icon="i-lucide-plus" label="Tambah Pegawai" color="primary" @click="showModal = true" />
    </div>

    <!-- Table -->
    <UCard :ui="{ body: 'p-0 sm:p-0' }" class="bg-white dark:bg-gray-800 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
          <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-4 py-3.5">Nama Pegawai</th>
              <th class="px-4 py-3.5">Kontak & NIK</th>
              <th class="px-4 py-3.5">Jabatan / Role</th>
              <th class="px-4 py-3.5">Cabang & Shift</th>
              <th class="px-4 py-3.5">Status</th>
              <th class="px-4 py-3.5 text-right">Aksi Profile</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-for="u in filteredUsers" :key="u.id" class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors">
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-full bg-primary-100 dark:bg-primary-900/40 text-primary font-bold flex items-center justify-center text-xs">
                    {{ initials(u.fullName) }}
                  </div>
                  <div>
                    <div class="font-bold text-gray-900 dark:text-white">{{ u.fullName }}</div>
                    <div v-if="u.sipNumber" class="text-[10px] text-emerald-600 font-mono font-medium">{{ u.sipNumber }}</div>
                  </div>
                </div>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div>{{ u.email || '—' }}</div>
                <div class="text-[11px] text-gray-400 font-mono">{{ u.phoneWa || '—' }}</div>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge :color="roleColor[u.role] ?? 'gray'" variant="subtle" size="xs">
                  {{ roleLabel[u.role] ?? u.role }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="font-semibold text-gray-800 dark:text-gray-200">{{ u.branchName || 'Soreang & Baleendah' }}</div>
                <div class="text-[10px] text-gray-400">{{ u.shiftWork || 'Shift Harian' }}</div>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge :color="u.isActive ? 'green' : 'gray'" variant="soft" size="xs">
                  {{ u.isActive ? 'Aktif Bekerja' : 'Non-aktif' }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap text-right">
                <UButton
                  size="xs"
                  color="gray"
                  variant="outline"
                  icon="i-lucide-user"
                  label="Profil Lengkap"
                  @click="openProfile(u)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </UCard>

    <!-- Modal Profile Detail -->
    <UModal v-model:open="showProfileModal" title="Detail Profil Pegawai & Izin Praktik" :ui="{ width: 'sm:max-w-xl' }">
      <UCard v-if="selectedStaff" class="bg-white dark:bg-gray-800">
        <template #header>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-primary text-white font-bold flex items-center justify-center text-sm">
                {{ initials(selectedStaff.fullName) }}
              </div>
              <div>
                <h3 class="font-bold text-gray-900 dark:text-white text-base">{{ selectedStaff.fullName }}</h3>
                <UBadge :color="roleColor[selectedStaff.role] ?? 'gray'" size="xs" variant="subtle">
                  {{ roleLabel[selectedStaff.role] ?? selectedStaff.role }}
                </UBadge>
              </div>
            </div>
            <UButton icon="i-lucide-x" color="gray" variant="ghost" @click="showProfileModal = false" />
          </div>
        </template>

        <div class="space-y-4 text-xs">
          <!-- Legalities & Identifiers -->
          <div class="p-3 bg-gray-50 dark:bg-gray-900 rounded-lg space-y-2">
            <h4 class="font-bold text-xs uppercase tracking-wider text-gray-700 dark:text-gray-300">LEGALITAS & IDENTITAS</h4>
            <div class="grid grid-cols-2 gap-2">
              <div><span class="text-gray-400 block">NIK:</span><span class="font-mono font-semibold">{{ selectedStaff.nik || '3204019284710002' }}</span></div>
              <div><span class="text-gray-400 block">Status Kerja:</span><span class="font-semibold">{{ selectedStaff.employmentStatus || 'Pegawai Tetap' }}</span></div>
              <div v-if="selectedStaff.sipNumber"><span class="text-gray-400 block">No. SIP (Izin Praktik):</span><span class="font-mono text-emerald-600 font-semibold">{{ selectedStaff.sipNumber }}</span></div>
              <div v-if="selectedStaff.strNumber"><span class="text-gray-400 block">No. STR:</span><span class="font-mono text-blue-600 font-semibold">{{ selectedStaff.strNumber }}</span></div>
            </div>
          </div>

          <!-- Assignment & Shift -->
          <div class="p-3 bg-gray-50 dark:bg-gray-900 rounded-lg space-y-2">
            <h4 class="font-bold text-xs uppercase tracking-wider text-gray-700 dark:text-gray-300">PENUGASAN & SHIFT</h4>
            <div class="grid grid-cols-2 gap-2">
              <div><span class="text-gray-400 block">Cabang Penugasan:</span><span class="font-semibold">{{ selectedStaff.branchName || 'Soreang' }}</span></div>
              <div><span class="text-gray-400 block">Shift Kerja:</span><span class="font-semibold">{{ selectedStaff.shiftWork || 'Shift Pagi (08:00 - 15:00)' }}</span></div>
              <div><span class="text-gray-400 block">Tanggal Bergabung:</span><span>{{ selectedStaff.joinDate || '15 Jan 2024' }}</span></div>
              <div><span class="text-gray-400 block">Kontak Darurat:</span><span class="font-mono">{{ selectedStaff.emergencyContact || '0812-9988-7766' }}</span></div>
            </div>
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end">
            <UButton label="Tutup" color="gray" variant="outline" @click="showProfileModal = false" />
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
