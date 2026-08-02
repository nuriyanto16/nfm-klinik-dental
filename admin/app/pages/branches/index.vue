<script setup lang="ts">
import type { Branch } from '~/types/api'

definePageMeta({ title: 'Cabang' })

// ── API ─────────────────────────────────────────────────────────────────────
const { data: apiBranches, status, refresh } = useApiFetch<Branch[]>('/branches')

const DUMMY_BRANCHES: Branch[] = [
  { id: 'br-001', name: 'Nina Dental Care Soreang', slug: 'soreang', address: 'Jl. Raya Soreang No. 23, Soreang', city: 'Bandung', phone: '022-85978821', opensAt: '08:00', closesAt: '20:00', isActive: true },
  { id: 'br-002', name: 'Nina Dental Care Baleendah', slug: 'baleendah', address: 'Jl. Baleendah Raya No. 14, Baleendah', city: 'Bandung', phone: '022-87834523', opensAt: '08:00', closesAt: '20:00', isActive: true },
  { id: 'br-003', name: 'Nina Dental Care Katapang', slug: 'katapang', address: 'Jl. Katapang Soreang No. 5, Katapang', city: 'Bandung', phone: null, opensAt: '09:00', closesAt: '18:00', isActive: false }
]

const localBranches = ref<Branch[]>([...DUMMY_BRANCHES])

watch(apiBranches, (val) => {
  if (val && Array.isArray(val) && val.length > 0) {
    localBranches.value = [...val]
  } else if (Array.isArray((val as any)?.data) && (val as any).data.length > 0) {
    localBranches.value = [...(val as any).data]
  }
}, { immediate: false })

// ── Selected Branch ──────────────────────────────────────────────────────────
const selectedBranchId = ref<string | null>(null)

onMounted(() => {
  if (!selectedBranchId.value && localBranches.value.length > 0) {
    selectedBranchId.value = localBranches.value[0].id
  }
})

watch(localBranches, (list) => {
  if (list.length > 0 && !selectedBranchId.value) {
    selectedBranchId.value = list[0].id
  }
})

const selectedBranch = computed<Branch | null>(() => {
  if (!selectedBranchId.value) return null
  return localBranches.value.find(b => b.id === selectedBranchId.value) ?? null
})

const activeBranches = computed(() => localBranches.value.filter(b => b.isActive))
const inactiveBranches = computed(() => localBranches.value.filter(b => !b.isActive))

function selectBranch(b: Branch) {
  selectedBranchId.value = b.id
}

// ── Tabs ──────────────────────────────────────────────────────────────────────
const tabs = [
  { label: 'Profil Cabang', value: 'profil', icon: 'i-lucide-building-2' },
  { label: 'Jam Operasional', value: 'jam', icon: 'i-lucide-clock' },
  { label: 'Statistik', value: 'statistik', icon: 'i-lucide-bar-chart-3' }
]
const activeTab = ref('profil')

// ── Create / Edit Modal ───────────────────────────────────────────────────────
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  name: '',
  slug: '',
  address: '',
  city: 'Bandung',
  phone: '',
  opensAt: '08:00',
  closesAt: '20:00',
  isActive: true
})

function slugify(str: string): string {
  return str.toLowerCase().trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
}

watch(() => form.name, (val) => {
  if (!editingId.value) {
    form.slug = slugify(val)
  }
})

function openCreate() {
  editingId.value = null
  Object.assign(form, { name: '', slug: '', address: '', city: 'Bandung', phone: '', opensAt: '08:00', closesAt: '20:00', isActive: true })
  formError.value = ''
  showModal.value = true
  activeTab.value = 'profil'
}

function openEdit(b: Branch) {
  editingId.value = b.id
  Object.assign(form, {
    name: b.name,
    slug: b.slug,
    address: b.address,
    city: b.city,
    phone: b.phone ?? '',
    opensAt: b.opensAt?.slice(0, 5) ?? '08:00',
    closesAt: b.closesAt?.slice(0, 5) ?? '20:00',
    isActive: b.isActive
  })
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.name.trim() || !form.address.trim()) {
    formError.value = 'Nama dan alamat cabang wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload = {
      name: form.name,
      slug: form.slug || slugify(form.name),
      address: form.address,
      city: form.city,
      phone: form.phone || null,
      opensAt: form.opensAt,
      closesAt: form.closesAt,
      isActive: form.isActive
    }

    if (editingId.value) {
      const idx = localBranches.value.findIndex(b => b.id === editingId.value)
      if (idx !== -1) {
        localBranches.value[idx] = { ...localBranches.value[idx], ...payload }
      }
      try { await $fetch(apiUrl(`/branches/${editingId.value}`), { method: 'PUT', body: payload }) } catch {}
    } else {
      const newId = `br-${Date.now()}`
      const newBranch: Branch = { id: newId, ...payload }
      localBranches.value.unshift(newBranch)
      selectedBranchId.value = newId
      try { await $fetch(apiUrl('/branches'), { method: 'POST', body: payload }) } catch {}
    }
    showModal.value = false
  } catch (err: any) {
    formError.value = err?.data?.message ?? err?.message ?? 'Gagal menyimpan data cabang.'
  } finally {
    saving.value = false
  }
}

async function toggleStatus(b: Branch) {
  const newStatus = !b.isActive
  const action = newStatus ? 'aktifkan' : 'nonaktifkan'
  if (!confirm(`${newStatus ? 'Aktifkan' : 'Nonaktifkan'} cabang "${b.name}"?`)) return
  const idx = localBranches.value.findIndex(x => x.id === b.id)
  if (idx !== -1) localBranches.value[idx] = { ...localBranches.value[idx], isActive: newStatus }
  try { await $fetch(apiUrl(`/branches/${b.id}`), { method: 'PUT', body: { ...b, isActive: newStatus } }) } catch {}
}

async function deleteBranch(b: Branch) {
  if (!confirm(`Hapus cabang "${b.name}"? Tindakan ini tidak dapat dibatalkan.`)) return
  localBranches.value = localBranches.value.filter(x => x.id !== b.id)
  if (selectedBranchId.value === b.id) {
    selectedBranchId.value = localBranches.value[0]?.id ?? null
  }
  try { await $fetch(apiUrl(`/branches/${b.id}`), { method: 'DELETE' }) } catch {}
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <!-- Header -->
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">Manajemen Cabang</h1>
        <p class="text-xs text-gray-500 mt-0.5">
          Kelola profil, jam operasional, dan status cabang Nina Dental Care.
        </p>
      </div>
      <UButton icon="i-lucide-plus" label="+ Tambah Cabang" color="primary" @click="openCreate" />
    </div>

    <!-- Stats Row -->
    <ClientOnly>
      <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
        <div class="p-3 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center gap-3">
          <div class="w-9 h-9 bg-emerald-100 dark:bg-emerald-900/40 rounded-lg flex items-center justify-center">
            <UIcon name="i-lucide-building-2" class="w-4 h-4 text-emerald-600" />
          </div>
          <div>
            <div class="text-xs text-gray-500">Cabang Aktif</div>
            <div class="text-2xl font-extrabold text-emerald-600">{{ activeBranches.length }}</div>
          </div>
        </div>
        <div class="p-3 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center gap-3">
          <div class="w-9 h-9 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center">
            <UIcon name="i-lucide-building" class="w-4 h-4 text-gray-500" />
          </div>
          <div>
            <div class="text-xs text-gray-500">Cabang Nonaktif</div>
            <div class="text-2xl font-extrabold text-gray-500">{{ inactiveBranches.length }}</div>
          </div>
        </div>
        <div class="p-3 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 flex items-center gap-3">
          <div class="w-9 h-9 bg-primary-100 dark:bg-primary-900/40 rounded-lg flex items-center justify-center">
            <UIcon name="i-lucide-map-pin" class="w-4 h-4 text-primary" />
          </div>
          <div>
            <div class="text-xs text-gray-500">Total Cabang</div>
            <div class="text-2xl font-extrabold text-primary">{{ localBranches.length }}</div>
          </div>
        </div>
      </div>
    </ClientOnly>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 items-start">

      <!-- Left: Branch List -->
      <UCard class="lg:col-span-1" :ui="{ body: 'p-2 space-y-1' }">
        <div v-if="status === 'pending'" class="flex items-center gap-2 p-3 text-gray-400 text-xs">
          <UIcon name="i-lucide-loader-circle" class="w-4 h-4 animate-spin" />
          Memuat...
        </div>
        <template v-else>
          <!-- Active group -->
          <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider px-2 pt-1 pb-0.5">
            Aktif ({{ activeBranches.length }})
          </p>
          <button
            v-for="b in activeBranches"
            :key="b.id"
            type="button"
            class="w-full text-left px-2.5 py-2.5 rounded-xl flex items-center gap-2.5 transition-all"
            :class="selectedBranchId === b.id ? 'bg-primary/10 text-primary border border-primary/20' : 'hover:bg-gray-50 dark:hover:bg-gray-800 border border-transparent'"
            @click="selectBranch(b)"
          >
            <div
              class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-sm font-extrabold"
              :class="selectedBranchId === b.id ? 'bg-primary text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-500'"
            >
              {{ b.name[0] }}
            </div>
            <span class="min-w-0">
              <span class="block text-xs font-bold truncate">{{ b.name }}</span>
              <span class="block text-[10px] text-gray-400 truncate">{{ b.city }}</span>
            </span>
          </button>

          <!-- Inactive group -->
          <template v-if="inactiveBranches.length > 0">
            <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider px-2 pt-3 pb-0.5">
              Nonaktif ({{ inactiveBranches.length }})
            </p>
            <button
              v-for="b in inactiveBranches"
              :key="b.id"
              type="button"
              class="w-full text-left px-2.5 py-2.5 rounded-xl flex items-center gap-2.5 opacity-60 transition-all"
              :class="selectedBranchId === b.id ? 'bg-primary/10 text-primary border border-primary/20' : 'hover:bg-gray-50 dark:hover:bg-gray-800 border border-transparent'"
              @click="selectBranch(b)"
            >
              <div class="w-8 h-8 rounded-lg flex items-center justify-center bg-gray-100 dark:bg-gray-700 text-gray-400 shrink-0 text-sm font-extrabold">
                {{ b.name[0] }}
              </div>
              <span class="min-w-0">
                <span class="block text-xs font-bold truncate">{{ b.name }}</span>
                <span class="block text-[10px] text-gray-400 truncate">{{ b.city }}</span>
              </span>
            </button>
          </template>
        </template>
      </UCard>

      <!-- Right: Detail Panel -->
      <ClientOnly>
        <UCard class="lg:col-span-3" :ui="{ body: 'p-0 sm:p-0' }">
          <div v-if="!selectedBranch" class="flex flex-col items-center justify-center py-16 gap-3 text-gray-400">
            <UIcon name="i-lucide-building-2" class="w-10 h-10" />
            <p class="text-sm">Pilih cabang di daftar untuk melihat detail.</p>
          </div>
          <template v-else>
            <!-- Branch Header -->
            <div class="px-5 pt-5 pb-4 flex items-start justify-between gap-3 border-b border-gray-100 dark:border-gray-800">
              <div class="flex items-center gap-3">
                <div class="w-12 h-12 rounded-xl bg-primary-100 dark:bg-primary-900/40 text-primary flex items-center justify-center text-2xl font-extrabold shrink-0">
                  {{ selectedBranch.name[0] }}
                </div>
                <div>
                  <h2 class="font-bold text-lg text-gray-900 dark:text-white">{{ selectedBranch.name }}</h2>
                  <p class="text-xs text-gray-500">{{ selectedBranch.address }}, {{ selectedBranch.city }}</p>
                </div>
              </div>
              <div class="flex items-center gap-2 shrink-0">
                <UBadge :color="selectedBranch.isActive ? 'success' : 'neutral'" variant="soft" size="sm">
                  {{ selectedBranch.isActive ? 'Aktif' : 'Nonaktif' }}
                </UBadge>
                <UButton icon="i-lucide-edit-2" size="xs" color="primary" variant="outline" label="Edit" @click="openEdit(selectedBranch)" />
                <UButton
                  :icon="selectedBranch.isActive ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                  size="xs"
                  :color="selectedBranch.isActive ? 'warning' : 'success'"
                  variant="outline"
                  :label="selectedBranch.isActive ? 'Nonaktifkan' : 'Aktifkan'"
                  @click="toggleStatus(selectedBranch)"
                />
                <UButton icon="i-lucide-trash-2" size="xs" color="error" variant="ghost" @click="deleteBranch(selectedBranch)" />
              </div>
            </div>

            <!-- Tabs -->
            <div class="px-5 pt-4">
              <div class="flex items-center gap-1 bg-gray-100 dark:bg-gray-900 p-0.5 rounded-lg w-fit">
                <button
                  v-for="tab in tabs"
                  :key="tab.value"
                  class="px-3 py-1.5 text-xs font-semibold rounded-md transition-all flex items-center gap-1.5"
                  :class="activeTab === tab.value ? 'bg-white dark:bg-gray-700 text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                  @click="activeTab = tab.value"
                >
                  <UIcon :name="tab.icon" class="w-3.5 h-3.5" />
                  {{ tab.label }}
                </button>
              </div>
            </div>

            <!-- Tab Content -->
            <div class="p-5 space-y-5">

              <!-- ── Profil Cabang ── -->
              <div v-if="activeTab === 'profil'" class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl space-y-3">
                    <h4 class="text-[10px] font-bold uppercase tracking-wider text-gray-500">Informasi Utama</h4>
                    <div class="space-y-2 text-sm">
                      <div class="flex items-start gap-2">
                        <UIcon name="i-lucide-map-pin" class="w-4 h-4 text-primary shrink-0 mt-0.5" />
                        <span class="text-gray-700 dark:text-gray-200">{{ selectedBranch.address }}</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <UIcon name="i-lucide-building" class="w-4 h-4 text-gray-400 shrink-0" />
                        <span class="text-gray-700 dark:text-gray-200">{{ selectedBranch.city }}</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <UIcon name="i-lucide-phone" class="w-4 h-4 text-gray-400 shrink-0" />
                        <span class="font-mono text-gray-700 dark:text-gray-200">{{ selectedBranch.phone || '—' }}</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <UIcon name="i-lucide-link" class="w-4 h-4 text-gray-400 shrink-0" />
                        <span class="font-mono text-xs text-blue-600">/{{ selectedBranch.slug }}</span>
                      </div>
                    </div>
                  </div>

                  <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl space-y-3">
                    <h4 class="text-[10px] font-bold uppercase tracking-wider text-gray-500">Jam Operasional</h4>
                    <div class="flex items-center gap-3">
                      <div class="text-center flex-1 p-3 bg-white dark:bg-gray-700 rounded-lg">
                        <span class="text-[10px] text-gray-400 block">Buka</span>
                        <span class="text-2xl font-extrabold text-emerald-600">{{ selectedBranch.opensAt?.slice(0, 5) ?? '08:00' }}</span>
                      </div>
                      <UIcon name="i-lucide-arrow-right" class="w-5 h-5 text-gray-400" />
                      <div class="text-center flex-1 p-3 bg-white dark:bg-gray-700 rounded-lg">
                        <span class="text-[10px] text-gray-400 block">Tutup</span>
                        <span class="text-2xl font-extrabold text-red-500">{{ selectedBranch.closesAt?.slice(0, 5) ?? '20:00' }}</span>
                      </div>
                    </div>
                    <div class="text-xs text-gray-500 text-center">
                      Durasi operasional: <b class="text-primary">
                        {{ (() => {
                          try {
                            const [oh, om] = (selectedBranch.opensAt ?? '08:00').split(':').map(Number)
                            const [ch, cm] = (selectedBranch.closesAt ?? '20:00').split(':').map(Number)
                            const diff = (ch * 60 + cm) - (oh * 60 + om)
                            return `${Math.floor(diff / 60)} jam ${diff % 60 > 0 ? diff % 60 + ' menit' : ''}`
                          } catch { return '—' }
                        })() }}
                      </b>
                    </div>
                  </div>
                </div>

                <!-- Status & Quick Actions -->
                <div class="flex flex-wrap gap-2 pt-2 border-t border-gray-100 dark:border-gray-800">
                  <UButton icon="i-lucide-edit-2" label="Edit Cabang" color="primary" @click="openEdit(selectedBranch)" />
                  <UButton
                    :icon="selectedBranch.isActive ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                    :label="selectedBranch.isActive ? 'Nonaktifkan Cabang' : 'Aktifkan Cabang'"
                    :color="selectedBranch.isActive ? 'warning' : 'success'"
                    variant="outline"
                    @click="toggleStatus(selectedBranch)"
                  />
                  <UButton icon="i-lucide-trash-2" label="Hapus" color="error" variant="ghost" @click="deleteBranch(selectedBranch)" />
                </div>
              </div>

              <!-- ── Jam Operasional Detail ── -->
              <div v-else-if="activeTab === 'jam'" class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                  <div class="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl text-center">
                    <UIcon name="i-lucide-sun" class="w-6 h-6 text-emerald-500 mx-auto mb-2" />
                    <span class="text-[10px] font-bold uppercase tracking-wide text-gray-500 block">Jam Buka</span>
                    <span class="text-3xl font-extrabold text-emerald-600 mt-1 block">{{ selectedBranch.opensAt?.slice(0, 5) ?? '08:00' }}</span>
                    <span class="text-xs text-gray-400 mt-1 block">WIB</span>
                  </div>
                  <div class="p-4 bg-red-50 dark:bg-red-900/20 rounded-xl text-center">
                    <UIcon name="i-lucide-moon" class="w-6 h-6 text-red-400 mx-auto mb-2" />
                    <span class="text-[10px] font-bold uppercase tracking-wide text-gray-500 block">Jam Tutup</span>
                    <span class="text-3xl font-extrabold text-red-500 mt-1 block">{{ selectedBranch.closesAt?.slice(0, 5) ?? '20:00' }}</span>
                    <span class="text-xs text-gray-400 mt-1 block">WIB</span>
                  </div>
                </div>
                <div class="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl text-center">
                  <UIcon name="i-lucide-clock" class="w-5 h-5 text-blue-500 mx-auto mb-1" />
                  <span class="text-sm text-gray-500">Total jam operasional per hari</span>
                  <div class="text-2xl font-extrabold text-blue-600 mt-1">
                    {{ (() => {
                      try {
                        const [oh, om] = (selectedBranch.opensAt ?? '08:00').split(':').map(Number)
                        const [ch, cm] = (selectedBranch.closesAt ?? '20:00').split(':').map(Number)
                        const diff = (ch * 60 + cm) - (oh * 60 + om)
                        return `${Math.floor(diff / 60)} Jam`
                      } catch { return '—' }
                    })() }}
                  </div>
                </div>
                <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <h4 class="text-xs font-bold text-gray-500 mb-2">Hari Operasional</h4>
                  <div class="flex flex-wrap gap-2">
                    <span
                      v-for="day in ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']"
                      :key="day"
                      class="px-3 py-1.5 bg-white dark:bg-gray-700 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-400 text-xs font-semibold rounded-lg"
                    >
                      {{ day }}
                    </span>
                    <span class="px-3 py-1.5 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 text-gray-400 text-xs font-semibold rounded-lg line-through">
                      Minggu
                    </span>
                  </div>
                </div>
                <UButton icon="i-lucide-edit-2" label="Ubah Jam Operasional" color="primary" variant="outline" @click="openEdit(selectedBranch)" />
              </div>

              <!-- ── Statistik ── -->
              <div v-else class="space-y-4">
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl text-center">
                    <UIcon name="i-lucide-users" class="w-5 h-5 text-blue-500 mx-auto mb-1" />
                    <span class="text-xs text-gray-400 block">Total Pasien</span>
                    <span class="text-2xl font-extrabold text-gray-800 dark:text-white">~{{ localBranches.indexOf(selectedBranch) === 0 ? 124 : 89 }}</span>
                  </div>
                  <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl text-center">
                    <UIcon name="i-lucide-calendar-check" class="w-5 h-5 text-emerald-500 mx-auto mb-1" />
                    <span class="text-xs text-gray-400 block">Reservasi Bulan Ini</span>
                    <span class="text-2xl font-extrabold text-emerald-600">~{{ localBranches.indexOf(selectedBranch) === 0 ? 48 : 31 }}</span>
                  </div>
                  <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl text-center col-span-2 sm:col-span-1">
                    <UIcon name="i-lucide-trending-up" class="w-5 h-5 text-primary mx-auto mb-1" />
                    <span class="text-xs text-gray-400 block">Estimasi Revenue</span>
                    <span class="text-xl font-extrabold text-primary">{{ localBranches.indexOf(selectedBranch) === 0 ? 'Rp 48,5 jt' : 'Rp 31,2 jt' }}</span>
                  </div>
                </div>
                <div class="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <h4 class="text-xs font-bold text-gray-500 uppercase tracking-wide mb-3">Status Cabang</h4>
                  <div class="flex items-center gap-3">
                    <div class="w-3 h-3 rounded-full" :class="selectedBranch.isActive ? 'bg-emerald-500 animate-pulse' : 'bg-gray-400'" />
                    <span class="text-sm font-semibold" :class="selectedBranch.isActive ? 'text-emerald-600' : 'text-gray-500'">
                      {{ selectedBranch.isActive ? 'Cabang Aktif & Beroperasi' : 'Cabang Nonaktif / Tutup' }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </template>
        </UCard>
      </ClientOnly>
    </div>

    <!-- ════════ Create / Edit Modal ════════ -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Data Cabang' : 'Tambah Cabang Baru'"
    >
      <template #body>
        <form class="space-y-4" @submit.prevent="onSubmit">
          <div v-if="formError" class="p-2.5 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg text-xs text-red-600">
            {{ formError }}
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Nama Cabang <span class="text-red-500">*</span></label>
            <UInput v-model="form.name" placeholder="mis. Nina Dental Care Soreang" :disabled="saving" />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Slug URL</label>
            <UInput v-model="form.slug" placeholder="soreang" :disabled="saving">
              <template #leading>
                <span class="text-xs text-gray-400">/</span>
              </template>
            </UInput>
            <p class="text-[10px] text-gray-400 mt-0.5">Diisi otomatis dari nama cabang, bisa diubah manual.</p>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Alamat Lengkap <span class="text-red-500">*</span></label>
            <UTextarea v-model="form.address" placeholder="Jl. Raya Soreang No. 23, Soreang" rows="2" :disabled="saving" />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold mb-1">Kota</label>
              <UInput v-model="form.city" placeholder="Bandung" :disabled="saving" />
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1">Telepon</label>
              <UInput v-model="form.phone" placeholder="022-XXXXXXXX" :disabled="saving" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold mb-1">Jam Buka</label>
              <UInput v-model="form.opensAt" type="time" :disabled="saving" />
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1">Jam Tutup</label>
              <UInput v-model="form.closesAt" type="time" :disabled="saving" />
            </div>
          </div>

          <div class="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
            <input id="branchActive" v-model="form.isActive" type="checkbox" class="w-4 h-4 rounded text-primary focus:ring-primary">
            <label for="branchActive" class="text-sm font-semibold cursor-pointer">
              Status Aktif
              <span class="text-xs font-normal text-gray-400 ml-1">(cabang buka & menerima reservasi)</span>
            </label>
          </div>

          <div class="flex justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="neutral" variant="ghost" :disabled="saving" @click="showModal = false" />
            <UButton
              type="submit"
              :label="saving ? 'Menyimpan...' : (editingId ? 'Simpan Perubahan' : 'Tambah Cabang')"
              color="primary"
              :loading="saving"
            />
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>
