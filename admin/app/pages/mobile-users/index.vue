<script setup lang="ts">
definePageMeta({ title: 'Pengguna Mobile App' })

export interface MobileUserAccessLog {
  id: string
  action: string
  details: string
  ipAddress: string
  deviceName: string
  osVersion: string
  location: string
  createdAt: string
}

export interface MobileUserReservationHistory {
  id: string
  ticketNo: string
  branchName: string
  doctorName: string
  treatmentName: string
  scheduledAt: string
  totalAmount: number
  status: 'completed' | 'in_progress' | 'confirmed' | 'cancelled'
}

export interface MobileUserAccount {
  id: string
  fullName: string
  email: string
  phoneWa: string
  rmNumber: string
  gender: string
  deviceId: string
  appVersion: string
  deviceOs: string
  pushToken: string
  status: 'ACTIVE' | 'BLOCKED' | 'PENDING_VERIFICATION'
  lastLoginAt: string
  createdAt: string
  accessLogs: MobileUserAccessLog[]
  reservations: MobileUserReservationHistory[]
}

const search = ref('')
const statusFilter = ref<'all' | 'ACTIVE' | 'BLOCKED'>('all')

const mobileUsers = ref<MobileUserAccount[]>([
  {
    id: 'mob-101',
    fullName: 'Nuriyanto',
    email: 'nuriyanto@example.com',
    phoneWa: '081234567890',
    rmNumber: 'RM-2026-0099',
    gender: 'Laki-laki',
    deviceId: 'Android-Pixel-7a-a19f',
    appVersion: 'v1.0.0 (Build 12)',
    deviceOs: 'Android 14 (API 34)',
    pushToken: 'fcm-token-nuriyanto-998877665544332211',
    status: 'ACTIVE',
    lastLoginAt: '2026-08-05T21:45:00Z',
    createdAt: '2026-07-01T08:00:00Z',
    accessLogs: [
      { id: 'log-1', action: 'Login Aplikasi Mobile', details: 'Berhasil login via WhatsApp OTP', ipAddress: '180.252.164.22', deviceName: 'Google Pixel 7a', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-05T21:45:00Z' },
      { id: 'log-2', action: 'Lihat Katalog Perawatan', details: 'Buka detail Pemasangan Behel Metal', ipAddress: '180.252.164.22', deviceName: 'Google Pixel 7a', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-05T21:30:12Z' },
      { id: 'log-3', action: 'Buat Reservasi Baru', details: 'Reservasi drg. Friski Raisis, Sp.Ort di Soreang', ipAddress: '180.252.164.22', deviceName: 'Google Pixel 7a', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-04T14:20:00Z' },
      { id: 'log-4', action: 'Request OTP WhatsApp', details: 'OTP terkirim ke 081234567890', ipAddress: '180.252.164.22', deviceName: 'Google Pixel 7a', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-04T14:18:45Z' },
      { id: 'log-5', action: 'Update Profil Pasien', details: 'Mengubah alamat domisili Soreang', ipAddress: '180.252.164.22', deviceName: 'Google Pixel 7a', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-07-28T09:12:00Z' }
    ],
    reservations: [
      { id: 'res-991', ticketNo: 'NDC-099', branchName: 'Soreang', doctorName: 'drg. Friski Raisis, Sp.Ort', treatmentName: 'Konsultasi & Pemasangan Behel Metal', scheduledAt: '2026-08-06T10:00:00Z', totalAmount: 4500000, status: 'confirmed' },
      { id: 'res-992', ticketNo: 'NDC-088', branchName: 'Soreang', doctorName: 'drg. Nina Marlina, Sp.KG', treatmentName: 'Scaling Karang Gigi 6-in-1', scheduledAt: '2026-07-20T14:00:00Z', totalAmount: 199000, status: 'completed' }
    ]
  },
  {
    id: 'mob-102',
    fullName: 'Budi Santoso',
    email: 'budi.santoso@example.com',
    phoneWa: '081234567890',
    rmNumber: 'RM-2026-0001',
    gender: 'Laki-laki',
    deviceId: 'Samsung-Galaxy-S23-fe44',
    appVersion: 'v1.0.0 (Build 12)',
    deviceOs: 'Android 14 (OneUI 6.0)',
    pushToken: 'fcm-token-budi-1122334455',
    status: 'ACTIVE',
    lastLoginAt: '2026-08-04T18:10:00Z',
    createdAt: '2026-07-01T09:00:00Z',
    accessLogs: [
      { id: 'log-10', action: 'Login Aplikasi Mobile', details: 'Login sukses biometrik', ipAddress: '114.124.200.89', deviceName: 'Samsung Galaxy S23', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-04T18:10:00Z' },
      { id: 'log-11', action: 'Cetak Invoice PDF', details: 'Download invoice pembayaran billing', ipAddress: '114.124.200.89', deviceName: 'Samsung Galaxy S23', osVersion: 'Android 14', location: 'Bandung, Indonesia', createdAt: '2026-08-04T17:45:00Z' }
    ],
    reservations: [
      { id: 'res-101', ticketNo: 'NDC-001', branchName: 'Baleendah', doctorName: 'drg. Siti Aminah', treatmentName: 'Penambalan Gigi Komposit', scheduledAt: '2026-08-04T10:00:00Z', totalAmount: 350000, status: 'completed' }
    ]
  },
  {
    id: 'mob-103',
    fullName: 'Siti Aminah',
    email: 'siti.aminah@example.com',
    phoneWa: '081298765432',
    rmNumber: 'RM-2026-0002',
    gender: 'Perempuan',
    deviceId: 'iPhone-15-Pro-max-88cc',
    appVersion: 'v1.0.0 (Build 12)',
    deviceOs: 'iOS 17.5.1',
    pushToken: 'apns-token-siti-990011',
    status: 'ACTIVE',
    lastLoginAt: '2026-08-03T11:20:00Z',
    createdAt: '2026-07-02T10:00:00Z',
    accessLogs: [
      { id: 'log-20', action: 'Login Aplikasi Mobile', details: 'Login FaceID iOS', ipAddress: '180.252.190.11', deviceName: 'iPhone 15 Pro Max', osVersion: 'iOS 17.5.1', location: 'Bandung, Indonesia', createdAt: '2026-08-03T11:20:00Z' }
    ],
    reservations: [
      { id: 'res-102', ticketNo: 'NDC-002', branchName: 'Soreang', doctorName: 'drg. Friski Raisis, Sp.Ort', treatmentName: 'Kontrol Behel Bulanan', scheduledAt: '2026-08-03T11:00:00Z', totalAmount: 250000, status: 'completed' }
    ]
  },
  {
    id: 'mob-104',
    fullName: 'Ahmad Fauzi',
    email: 'ahmad.fauzi@example.com',
    phoneWa: '081311223344',
    rmNumber: 'RM-2026-0004',
    gender: 'Laki-laki',
    deviceId: 'Xiaomi-Redmi-Note-12',
    appVersion: 'v0.9.8 (Lama)',
    deviceOs: 'Android 13',
    pushToken: 'fcm-token-ahmad-554433',
    status: 'BLOCKED',
    lastLoginAt: '2026-07-25T16:00:00Z',
    createdAt: '2026-07-04T11:00:00Z',
    accessLogs: [
      { id: 'log-30', action: 'Percobaan OTP Gagal', details: 'Salah memasukkan OTP 3x', ipAddress: '36.88.210.45', deviceName: 'Xiaomi Redmi Note 12', osVersion: 'Android 13', location: 'Kab. Bandung', createdAt: '2026-07-25T16:00:00Z' },
      { id: 'log-31', action: 'Akun Diblokir Sementara', details: 'Dibatasi admin karena percobaan spam', ipAddress: '36.88.210.45', deviceName: 'System Protection', osVersion: '-', location: 'System', createdAt: '2026-07-25T16:01:00Z' }
    ],
    reservations: []
  }
])

const selectedUserId = ref<string>(mobileUsers.value[0].id)
const selectedUser = computed<MobileUserAccount | null>(() => mobileUsers.value.find(u => u.id === selectedUserId.value) ?? mobileUsers.value[0] ?? null)

const filteredUsers = computed(() => {
  return mobileUsers.value.filter(u => {
    if (statusFilter.value !== 'all' && u.status !== statusFilter.value) return false
    if (!search.value.trim()) return true
    const q = search.value.toLowerCase().trim()
    return u.fullName.toLowerCase().includes(q) || u.email.toLowerCase().includes(q) || u.phoneWa.includes(q) || u.rmNumber.toLowerCase().includes(q)
  })
})

function selectUser(u: MobileUserAccount) {
  selectedUserId.value = u.id
}

function toggleBlockStatus(user: MobileUserAccount) {
  const isBlocked = user.status === 'BLOCKED'
  const actionText = isBlocked ? 'Buka Blokir' : 'Blokir'
  if (confirm(`Apakah Anda yakin ingin ${actionText} akses aplikasi mobile untuk user ${user.fullName}?`)) {
    user.status = isBlocked ? 'ACTIVE' : 'BLOCKED'
    user.accessLogs.unshift({
      id: `log-${Date.now()}`,
      action: isBlocked ? 'Akses Dibuka Admin' : 'Akun Diblokir Admin',
      details: isBlocked ? 'Akses aplikasi mobile dipulihkan oleh admin office' : 'Akses aplikasi mobile dinonaktifkan oleh admin office',
      ipAddress: '127.0.0.1 (Admin)',
      deviceName: 'Office Admin Dashboard',
      osVersion: 'Web Admin',
      location: 'Office Panel',
      createdAt: new Date().toISOString()
    })
  }
}

function resetUserSession(user: MobileUserAccount) {
  if (confirm(`Reset Sesi & Force Logout aplikasi mobile untuk ${user.fullName}?`)) {
    alert(`Sesi login dan token FCM untuk ${user.fullName} telah direset. User harus login ulang.`)
    user.accessLogs.unshift({
      id: `log-${Date.now()}`,
      action: 'Force Logout Sesi Mobile',
      details: 'Admin mereset token FCM dan mengakhiri sesi aktif di HP pasien',
      ipAddress: '127.0.0.1 (Admin)',
      deviceName: 'Office Admin Dashboard',
      osVersion: 'Web Admin',
      location: 'Office Panel',
      createdAt: new Date().toISOString()
    })
  }
}

function sendPasswordResetLink(user: MobileUserAccount) {
  alert(`Instruksi reset PIN/Password telah dikirimkan via WhatsApp ke ${user.phoneWa}.`)
  user.accessLogs.unshift({
    id: `log-${Date.now()}`,
    action: 'Reset PIN/Password Terkirim',
    details: `Link/OTP Reset dikirimkan ke WhatsApp ${user.phoneWa}`,
    ipAddress: '127.0.0.1 (Admin)',
    deviceName: 'WA Gateway Office',
    osVersion: 'Web Admin',
    location: 'Office Panel',
    createdAt: new Date().toISOString()
  })
}

function safeDateFormatted(isoStr: string) {
  if (!isoStr) return '—'
  try {
    return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(isoStr))
  } catch {
    return isoStr
  }
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white flex items-center gap-2">
          <UIcon name="i-lucide-smartphone" class="w-7 h-7 text-primary" />
          Pengguna Mobile App (Pasien)
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Manajemen akun aplikasi pasien Android/iOS, log riwayat akses, riwayat reservasi, dan kontrol sesi akun.
        </p>
      </div>

      <div class="flex items-center gap-3">
        <UBadge color="primary" variant="subtle" size="md" class="font-bold">
          Total: {{ mobileUsers.length }} Akun Mobile
        </UBadge>
        <UBadge color="success" variant="soft" size="md" class="font-bold">
          APK v1.0.0 Ready
        </UBadge>
      </div>
    </div>

    <!-- Filters & Main Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Left Table List (Cols 7) -->
      <UCard class="lg:col-span-7 space-y-4 shadow-xs" :ui="{ body: 'p-0 sm:p-0' }">
        <!-- Filter Header Bar -->
        <div class="p-4 border-b border-gray-200 dark:border-gray-700 flex flex-wrap items-center justify-between gap-3">
          <UInput
            v-model="search"
            icon="i-lucide-search"
            placeholder="Cari nama pasien, WA, RM, email..."
            class="w-full sm:w-64"
          />
          <div class="flex items-center gap-2">
            <span class="text-xs font-semibold text-gray-500">Status:</span>
            <select
              v-model="statusFilter"
              class="px-3 py-1.5 text-xs rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 font-medium cursor-pointer"
            >
              <option value="all">Semua Status</option>
              <option value="ACTIVE">Aktif (Bisa Login)</option>
              <option value="BLOCKED">Diblokir</option>
            </select>
          </div>
        </div>

        <!-- Mobile Users Table -->
        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
            <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th class="px-4 py-3.5">Nama Pasien</th>
                <th class="px-4 py-3.5">Kontak / Email</th>
                <th class="px-4 py-3.5">Perangkat & Versi</th>
                <th class="px-4 py-3.5">Status Akun</th>
                <th class="px-4 py-3.5 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr
                v-for="user in filteredUsers"
                :key="user.id"
                class="hover:bg-primary-50/60 dark:hover:bg-primary-950/30 transition-colors cursor-pointer"
                :class="selectedUserId === user.id ? 'bg-primary-50/90 dark:bg-primary-950/50 font-medium' : ''"
                @click="selectUser(user)"
              >
                <td class="px-4 py-3.5">
                  <div class="font-bold text-gray-900 dark:text-white flex items-center gap-2">
                    <UAvatar icon="i-lucide-user" size="xs" class="bg-primary-100 text-primary-700" />
                    <span>{{ user.fullName }}</span>
                  </div>
                  <div class="text-[11px] font-mono text-gray-400 mt-0.5">{{ user.rmNumber }}</div>
                </td>
                <td class="px-4 py-3.5">
                  <div class="font-mono text-gray-900 dark:text-white">{{ user.phoneWa }}</div>
                  <div class="text-[11px] text-gray-400 truncate max-w-[150px]">{{ user.email }}</div>
                </td>
                <td class="px-4 py-3.5">
                  <div class="text-xs text-gray-800 dark:text-gray-200 font-medium truncate max-w-[160px]">{{ user.deviceId }}</div>
                  <UBadge color="gray" variant="subtle" size="xs" class="mt-0.5">{{ user.appVersion }}</UBadge>
                </td>
                <td class="px-4 py-3.5">
                  <UBadge :color="user.status === 'ACTIVE' ? 'success' : 'error'" variant="soft" size="xs" class="font-bold">
                    {{ user.status === 'ACTIVE' ? 'AKTIF' : 'DIBLOKIR' }}
                  </UBadge>
                </td>
                <td class="px-4 py-3.5 text-right">
                  <UButton
                    size="xs"
                    color="neutral"
                    variant="ghost"
                    icon="i-lucide-chevron-right"
                    label="Detail & Log"
                    @click.stop="selectUser(user)"
                  />
                </td>
              </tr>
              <tr v-if="filteredUsers.length === 0">
                <td colspan="5" class="p-8 text-center text-gray-400 text-xs">
                  Tidak ada akun pengguna mobile app yang cocok dengan pencarian.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UCard>

      <!-- Right Detail & Log Monitoring Panel (Cols 5) -->
      <UCard
        class="lg:col-span-5 shadow-xs lg:sticky lg:top-4"
        :ui="{ body: 'space-y-4 p-4 sm:p-5 max-h-[calc(100vh-140px)] overflow-y-auto' }"
      >
        <div v-if="!selectedUser" class="py-12 text-center text-gray-400 space-y-2">
          <UIcon name="i-lucide-smartphone" class="w-10 h-10 mx-auto" />
          <p class="text-xs">Pilih akun pengguna mobile di daftar sebelah kiri untuk melihat log & kontrol.</p>
        </div>

        <template v-else>
          <!-- User Profile & Device Header -->
          <div class="p-4 rounded-xl border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-950/30 space-y-3">
            <div class="flex items-start justify-between gap-2">
              <div class="flex items-center gap-3">
                <UAvatar icon="i-lucide-user" size="xl" class="bg-primary-600 text-white font-bold" />
                <div>
                  <h3 class="font-bold text-base text-gray-900 dark:text-white">
                    {{ selectedUser.fullName }}
                  </h3>
                  <p class="text-xs font-mono text-primary font-semibold">{{ selectedUser.rmNumber }}</p>
                  <p class="text-[11px] text-gray-500">{{ selectedUser.phoneWa }} · {{ selectedUser.email }}</p>
                </div>
              </div>
              <UBadge :color="selectedUser.status === 'ACTIVE' ? 'success' : 'error'" variant="solid" size="xs" class="font-bold">
                {{ selectedUser.status === 'ACTIVE' ? 'AKTIF' : 'BLOCKED' }}
              </UBadge>
            </div>

            <!-- Device Specifications -->
            <div class="grid grid-cols-2 gap-2 text-[11px] bg-white dark:bg-gray-800 p-2.5 rounded-lg border border-primary-100 dark:border-primary-900">
              <div>
                <span class="text-gray-400 block text-[9px]">Tipe Perangkat</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200 block truncate">{{ selectedUser.deviceId }}</span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Sistem Operasi</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200 block">{{ selectedUser.deviceOs }}</span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Versi APK App</span>
                <span class="font-semibold text-emerald-600 dark:text-emerald-400 block">{{ selectedUser.appVersion }}</span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Login Terakhir</span>
                <span class="font-mono text-gray-700 dark:text-gray-300 block text-[10px]">{{ safeDateFormatted(selectedUser.lastLoginAt) }}</span>
              </div>
            </div>

            <!-- Quick Account Controls -->
            <div class="flex items-center gap-2 pt-1 flex-wrap">
              <UButton
                size="xs"
                :color="selectedUser.status === 'ACTIVE' ? 'error' : 'success'"
                variant="subtle"
                :icon="selectedUser.status === 'ACTIVE' ? 'i-lucide-lock' : 'i-lucide-unlock'"
                :label="selectedUser.status === 'ACTIVE' ? 'Blokir Akun' : 'Buka Blokir'"
                class="font-bold"
                @click="toggleBlockStatus(selectedUser)"
              />
              <UButton
                size="xs"
                color="warning"
                variant="subtle"
                icon="i-lucide-log-out"
                label="Force Logout Sesi"
                @click="resetUserSession(selectedUser)"
              />
              <UButton
                size="xs"
                color="neutral"
                variant="subtle"
                icon="i-lucide-key-round"
                label="Reset PIN/Password"
                @click="sendPasswordResetLink(selectedUser)"
              />
            </div>
          </div>

          <!-- Tabs Section: History Log Akses & History Reservasi -->
          <UTabs
            :items="[
              { label: `Log Akses (${selectedUser.accessLogs.length})`, icon: 'i-lucide-activity', slot: 'logs' },
              { label: `History Reservasi (${selectedUser.reservations.length})`, icon: 'i-lucide-calendar-check', slot: 'reservations' },
              { label: 'Push Notification Token', icon: 'i-lucide-bell', slot: 'push' }
            ]"
            class="w-full"
          >
            <!-- Tab 1: Access Logs Detail -->
            <template #logs>
              <div class="space-y-2 pt-3">
                <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
                  RIWAYAT AKSES & LOG PERANGKAT MOBILE
                </span>
                <div class="space-y-2 max-h-72 overflow-y-auto pr-1">
                  <div
                    v-for="log in selectedUser.accessLogs"
                    :key="log.id"
                    class="p-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/60 dark:bg-gray-900/60 space-y-1 text-xs"
                  >
                    <div class="flex items-center justify-between font-bold text-gray-900 dark:text-white">
                      <span class="flex items-center gap-1.5">
                        <UIcon name="i-lucide-shield-alert" class="w-3.5 h-3.5 text-primary" />
                        {{ log.action }}
                      </span>
                      <span class="text-[10px] text-gray-400 font-mono">{{ safeDateFormatted(log.createdAt) }}</span>
                    </div>
                    <p class="text-[11px] text-gray-600 dark:text-gray-300 font-medium">{{ log.details }}</p>
                    <div class="flex items-center justify-between text-[10px] text-gray-400 pt-1 border-t border-gray-200/50 dark:border-gray-800/50">
                      <span>IP: <strong class="font-mono text-gray-600 dark:text-gray-300">{{ log.ipAddress }}</strong></span>
                      <span>{{ log.deviceName }} · {{ log.location }}</span>
                    </div>
                  </div>
                  <div v-if="selectedUser.accessLogs.length === 0" class="p-4 text-center text-xs text-gray-400">
                    Belum ada catatan log aktivitas untuk user ini.
                  </div>
                </div>
              </div>
            </template>

            <!-- Tab 2: Reservations History -->
            <template #reservations>
              <div class="space-y-2 pt-3">
                <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
                  RIWAYAT RESERVASI VIA MOBILE APP
                </span>
                <div class="space-y-2 max-h-72 overflow-y-auto pr-1">
                  <div
                    v-for="res in selectedUser.reservations"
                    :key="res.id"
                    class="p-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/60 dark:bg-gray-900/60 space-y-1.5 text-xs"
                  >
                    <div class="flex items-center justify-between">
                      <span class="font-bold text-gray-900 dark:text-white">{{ res.treatmentName }}</span>
                      <UBadge :color="res.status === 'completed' ? 'success' : res.status === 'confirmed' ? 'primary' : 'warning'" variant="soft" size="xs">
                        {{ res.status === 'completed' ? 'Selesai' : res.status === 'confirmed' ? 'Terkonfirmasi' : 'Proses' }}
                      </UBadge>
                    </div>
                    <div class="text-[11px] text-gray-600 dark:text-gray-300 flex items-center justify-between">
                      <span>{{ res.doctorName }} · {{ res.branchName }}</span>
                      <span class="font-bold text-primary">{{ formatIDR(res.totalAmount) }}</span>
                    </div>
                    <div class="text-[10px] text-gray-400 font-mono flex justify-between pt-1 border-t border-gray-200/50">
                      <span>Tiket: {{ res.ticketNo }}</span>
                      <span>{{ safeDateFormatted(res.scheduledAt) }}</span>
                    </div>
                  </div>
                  <div v-if="selectedUser.reservations.length === 0" class="p-4 text-center text-xs text-gray-400">
                    User belum pernah membuat reservasi dari aplikasi mobile.
                  </div>
                </div>
              </div>
            </template>

            <!-- Tab 3: Push Token Info -->
            <template #push>
              <div class="space-y-3 pt-3 text-xs">
                <div class="p-3 bg-gray-50 dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 space-y-2">
                  <span class="text-gray-400 text-[10px] block uppercase font-bold">FCM / APNS Notification Token</span>
                  <p class="font-mono text-[11px] break-all bg-white dark:bg-gray-800 p-2 rounded border text-gray-800 dark:text-gray-200">
                    {{ selectedUser.pushToken }}
                  </p>
                  <div class="flex items-center justify-between pt-1 text-[11px]">
                    <span class="text-gray-500">Izin Push Notification:</span>
                    <UBadge color="success" variant="subtle" size="xs">Diizinkan (Active)</UBadge>
                  </div>
                </div>
              </div>
            </template>
          </UTabs>
        </template>
      </UCard>
    </div>
  </div>
</template>
