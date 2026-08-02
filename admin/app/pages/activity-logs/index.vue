<script setup lang="ts">
import type { ActivityLog, ActivityScope, ActivityCategory, ActivitySeverity } from '~/types/api'

definePageMeta({
  title: 'Log Aktivitas Sistem'
})

const {
  logs,
  allLogs,
  stats,
  scopeFilter,
  categoryFilter,
  severityFilter,
  searchQuery,
  currentPage,
  pageSize,
  totalPages
} = useActivityLog()

// Detail Modal
const selectedLog = ref<ActivityLog | null>(null)
const showDetailModal = ref(false)

function openDetail(log: ActivityLog) {
  selectedLog.value = log
  showDetailModal.value = true
}

function formatDate(dateStr: string) {
  try {
    const d = new Date(dateStr)
    return d.toLocaleString('id-ID', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  } catch (_) {
    return dateStr
  }
}

function getScopeColor(scope: ActivityScope) {
  switch (scope) {
    case 'admin':
      return 'indigo'
    case 'mobile':
      return 'emerald'
    default:
      return 'gray'
  }
}

function getScopeLabel(scope: ActivityScope) {
  switch (scope) {
    case 'admin':
      return 'Panel Admin'
    case 'mobile':
      return 'Aplikasi Mobile'
    default:
      return scope
  }
}

function getSeverityColor(severity: ActivitySeverity) {
  switch (severity) {
    case 'INFO':
      return 'sky'
    case 'WARNING':
      return 'amber'
    case 'ERROR':
      return 'red'
    case 'SECURITY':
      return 'rose'
    default:
      return 'gray'
  }
}

function getCategoryLabel(category: ActivityCategory) {
  switch (category) {
    case 'auth':
      return 'Autentikasi'
    case 'booking':
      return 'Reservasi'
    case 'medical':
      return 'Rekam Medis'
    case 'payment':
      return 'Pembayaran'
    case 'profile':
      return 'Profil Pasien'
    case 'system':
      return 'Sistem'
    default:
      return category
  }
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          Log Aktivitas Sistem
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Memantau riwayat aktivitas pengguna, akses Panel Admin, serta transaksi & reservasi pada Aplikasi Mobile secara realtime.
        </p>
      </div>

      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-rotate-cw"
          variant="outline"
          color="gray"
          label="Refresh"
          @click="currentPage = 1"
        />
      </div>
    </div>

    <!-- Stats Summary Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Total Log Aktivitas
            </p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {{ stats.total }}
            </p>
          </div>
          <div class="p-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-xl">
            <UIcon name="i-lucide-activity" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Akses Panel Admin
            </p>
            <p class="text-2xl font-bold text-indigo-600 dark:text-indigo-400 mt-1">
              {{ stats.adminCount }}
            </p>
          </div>
          <div class="p-3 bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 rounded-xl">
            <UIcon name="i-lucide-layout-dashboard" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Aktivitas Mobile App
            </p>
            <p class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">
              {{ stats.mobileCount }}
            </p>
          </div>
          <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 rounded-xl">
            <UIcon name="i-lucide-smartphone" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Warning & Keamanan
            </p>
            <p class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">
              {{ stats.securityCount }}
            </p>
          </div>
          <div class="p-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400 rounded-xl">
            <UIcon name="i-lucide-shield-alert" class="w-6 h-6" />
          </div>
        </div>
      </UCard>
    </div>

    <!-- Filters Bar -->
    <UCard class="bg-white dark:bg-gray-800">
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <!-- Scope Pills -->
        <div class="flex items-center gap-2 overflow-x-auto pb-1 lg:pb-0">
          <UButton
            :variant="scopeFilter === 'all' ? 'solid' : 'ghost'"
            :color="scopeFilter === 'all' ? 'primary' : 'gray'"
            size="sm"
            label="Semua Sumber"
            @click="scopeFilter = 'all'; currentPage = 1"
          />
          <UButton
            :variant="scopeFilter === 'admin' ? 'solid' : 'ghost'"
            :color="scopeFilter === 'admin' ? 'indigo' : 'gray'"
            size="sm"
            icon="i-lucide-layout-dashboard"
            label="Akses Panel Admin"
            @click="scopeFilter = 'admin'; currentPage = 1"
          />
          <UButton
            :variant="scopeFilter === 'mobile' ? 'solid' : 'ghost'"
            :color="scopeFilter === 'mobile' ? 'emerald' : 'gray'"
            size="sm"
            icon="i-lucide-smartphone"
            label="Aplikasi Mobile"
            @click="scopeFilter = 'mobile'; currentPage = 1"
          />
        </div>

        <!-- Filter Dropdowns & Search -->
        <div class="flex flex-wrap items-center gap-3">
          <UInput
            v-model="searchQuery"
            icon="i-lucide-search"
            placeholder="Cari user, IP, atau aksi..."
            class="w-full sm:w-64"
          />

          <select
            v-model="categoryFilter"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-primary-500"
            @change="currentPage = 1"
          >
            <option value="all">Semua Kategori</option>
            <option value="auth">Autentikasi</option>
            <option value="booking">Reservasi</option>
            <option value="medical">Rekam Medis</option>
            <option value="payment">Pembayaran</option>
            <option value="profile">Profil</option>
            <option value="system">Sistem</option>
          </select>

          <select
            v-model="severityFilter"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-primary-500"
            @change="currentPage = 1"
          >
            <option value="all">Semua Level</option>
            <option value="INFO">INFO</option>
            <option value="WARNING">WARNING</option>
            <option value="ERROR">ERROR</option>
            <option value="SECURITY">SECURITY</option>
          </select>
        </div>
      </div>
    </UCard>

    <!-- Table -->
    <UCard :ui="{ body: 'p-0 sm:p-0' }" class="overflow-hidden bg-white dark:bg-gray-800">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm text-gray-600 dark:text-gray-300">
          <thead class="bg-gray-50 dark:bg-gray-800/80 text-xs text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-4 py-3.5 font-semibold">Waktu</th>
              <th class="px-4 py-3.5 font-semibold">Sumber</th>
              <th class="px-4 py-3.5 font-semibold">Pengguna / User</th>
              <th class="px-4 py-3.5 font-semibold">Aktivitas & Kategori</th>
              <th class="px-4 py-3.5 font-semibold">IP Address & Perangkat</th>
              <th class="px-4 py-3.5 font-semibold">Status / Level</th>
              <th class="px-4 py-3.5 font-semibold text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr
              v-for="log in logs"
              :key="log.id"
              class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors"
            >
              <!-- Waktu -->
              <td class="px-4 py-3.5 whitespace-nowrap text-xs font-medium text-gray-500 dark:text-gray-400">
                {{ formatDate(log.createdAt) }}
              </td>

              <!-- Sumber -->
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge
                  :color="getScopeColor(log.scope)"
                  variant="subtle"
                  size="sm"
                  class="font-medium"
                >
                  <UIcon
                    :name="log.scope === 'admin' ? 'i-lucide-layout-dashboard' : 'i-lucide-smartphone'"
                    class="w-3.5 h-3.5 mr-1 inline"
                  />
                  {{ getScopeLabel(log.scope) }}
                </UBadge>
              </td>

              <!-- Pengguna -->
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="flex items-center gap-2.5">
                  <div class="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center font-bold text-xs text-gray-600 dark:text-gray-300">
                    {{ log.userName.substring(0, 2).toUpperCase() }}
                  </div>
                  <div>
                    <div class="font-semibold text-gray-900 dark:text-white text-xs">
                      {{ log.userName }}
                    </div>
                    <div class="text-[11px] text-gray-500">
                      {{ log.userRole }} <span v-if="log.userEmail">({{ log.userEmail }})</span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- Aktivitas & Kategori -->
              <td class="px-4 py-3.5">
                <div class="space-y-1 max-w-md">
                  <div class="flex items-center gap-2">
                    <span class="font-mono text-xs font-bold text-gray-800 dark:text-gray-200">
                      {{ log.action }}
                    </span>
                    <UBadge color="gray" variant="outline" size="xs">
                      {{ getCategoryLabel(log.category) }}
                    </UBadge>
                  </div>
                  <p class="text-xs text-gray-600 dark:text-gray-400 truncate">
                    {{ log.description }}
                  </p>
                </div>
              </td>

              <!-- IP Address & Perangkat -->
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="text-xs font-mono text-gray-800 dark:text-gray-200">
                  {{ log.ipAddress }}
                </div>
                <div class="text-[11px] text-gray-500 max-w-[180px] truncate" :title="log.userAgent">
                  {{ log.userAgent }}
                </div>
              </td>

              <!-- Status / Level -->
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="flex items-center gap-1.5">
                  <UBadge
                    :color="log.status === 'SUCCESS' ? 'green' : 'red'"
                    variant="soft"
                    size="xs"
                  >
                    {{ log.status }}
                  </UBadge>
                  <UBadge
                    :color="getSeverityColor(log.severity)"
                    variant="solid"
                    size="xs"
                  >
                    {{ log.severity }}
                  </UBadge>
                </div>
              </td>

              <!-- Aksi -->
              <td class="px-4 py-3.5 whitespace-nowrap text-right">
                <UButton
                  size="xs"
                  variant="ghost"
                  color="gray"
                  icon="i-lucide-eye"
                  label="Detail"
                  @click="openDetail(log)"
                />
              </td>
            </tr>

            <tr v-if="logs.length === 0">
              <td colspan="7" class="px-4 py-12 text-center text-gray-500 dark:text-gray-400">
                <UIcon name="i-lucide-inbox" class="w-8 h-8 mx-auto text-gray-400 mb-2" />
                Tidak ada log aktivitas yang cocok dengan filter pencarian.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Footer -->
      <div v-if="allLogs.length > 0" class="flex items-center justify-between p-4 border-t border-gray-200 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-800/50 text-xs">
        <div class="text-gray-500">
          Menampilkan {{ logs.length }} dari {{ allLogs.length }} data log
        </div>
        <div class="flex items-center gap-2">
          <UButton
            size="xs"
            variant="outline"
            color="gray"
            :disabled="currentPage === 1"
            icon="i-lucide-chevron-left"
            @click="currentPage--"
          />
          <span class="font-medium text-gray-700 dark:text-gray-300">
            Halaman {{ currentPage }} dari {{ totalPages }}
          </span>
          <UButton
            size="xs"
            variant="outline"
            color="gray"
            :disabled="currentPage >= totalPages"
            icon="i-lucide-chevron-right"
            @click="currentPage++"
          />
        </div>
      </div>
    </UCard>

    <!-- Detail Modal -->
    <UModal v-model="showDetailModal" :ui="{ width: 'sm:max-w-xl' }">
      <UCard v-if="selectedLog" class="bg-white dark:bg-gray-800">
        <template #header>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-file-text" class="w-5 h-5 text-primary-600" />
              <h3 class="font-bold text-gray-900 dark:text-white">
                Detail Log Aktivitas
              </h3>
            </div>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-lucide-x"
              class="-my-1"
              @click="showDetailModal = false"
            />
          </div>
        </template>

        <div class="space-y-4 text-xs">
          <!-- Overview Badges -->
          <div class="flex flex-wrap items-center gap-2 pb-3 border-b border-gray-200 dark:border-gray-700">
            <UBadge :color="getScopeColor(selectedLog.scope)" variant="subtle">
              {{ getScopeLabel(selectedLog.scope) }}
            </UBadge>
            <UBadge color="gray" variant="outline">
              {{ getCategoryLabel(selectedLog.category) }}
            </UBadge>
            <UBadge :color="selectedLog.status === 'SUCCESS' ? 'green' : 'red'" variant="soft">
              {{ selectedLog.status }}
            </UBadge>
            <UBadge :color="getSeverityColor(selectedLog.severity)" variant="solid">
              {{ selectedLog.severity }}
            </UBadge>
          </div>

          <!-- Basic Info Table -->
          <div class="grid grid-cols-2 gap-3 bg-gray-50 dark:bg-gray-900/50 p-3 rounded-lg">
            <div>
              <span class="text-gray-500 block">ID Log:</span>
              <span class="font-mono font-semibold text-gray-800 dark:text-gray-200">{{ selectedLog.id }}</span>
            </div>
            <div>
              <span class="text-gray-500 block">Waktu Kejadian:</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">{{ formatDate(selectedLog.createdAt) }}</span>
            </div>
            <div>
              <span class="text-gray-500 block">Pengguna:</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">{{ selectedLog.userName }} ({{ selectedLog.userRole }})</span>
            </div>
            <div>
              <span class="text-gray-500 block">IP Address:</span>
              <span class="font-mono text-gray-800 dark:text-gray-200">{{ selectedLog.ipAddress }}</span>
            </div>
          </div>

          <!-- Action & Description -->
          <div class="space-y-1">
            <span class="text-gray-500 font-medium">Aksi / Event:</span>
            <div class="font-mono font-bold text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-2.5 py-1.5 rounded text-xs">
              {{ selectedLog.action }}
            </div>
          </div>

          <div class="space-y-1">
            <span class="text-gray-500 font-medium">Keterangan:</span>
            <p class="text-gray-800 dark:text-gray-200 bg-gray-50 dark:bg-gray-900/50 p-2.5 rounded border border-gray-200 dark:border-gray-700">
              {{ selectedLog.description }}
            </p>
          </div>

          <!-- User Agent -->
          <div class="space-y-1">
            <span class="text-gray-500 font-medium">User Agent / Perangkat:</span>
            <p class="font-mono text-[11px] text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-900/50 p-2 rounded break-all">
              {{ selectedLog.userAgent }}
            </p>
          </div>

          <!-- Metadata Details JSON -->
          <div v-if="selectedLog.details" class="space-y-1">
            <span class="text-gray-500 font-medium">Payload Metadata (JSON):</span>
            <pre class="font-mono text-[11px] bg-slate-900 text-emerald-400 p-3 rounded-lg overflow-x-auto max-h-48">{{ JSON.stringify(selectedLog.details, null, 2) }}</pre>
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end">
            <UButton
              color="gray"
              variant="outline"
              label="Tutup"
              @click="showDetailModal = false"
            />
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
