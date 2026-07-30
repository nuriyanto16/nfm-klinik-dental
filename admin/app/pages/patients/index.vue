<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { CreatePatientInput, MedicalRecord, PaginatedResponse, Patient, PatientOdontogramTimeline, PatientStats, Payment, Promo, Reservation, UpdatePatientInput } from '~/types/api'

definePageMeta({ title: 'Pasien' })

const page = ref(1)
const pageSize = 10
const search = ref('')
const { data: patientsPage, status, refresh, error } = useApiFetch<PaginatedResponse<Patient>>(() => `/patients?page=${page.value}&pageSize=${pageSize}${search.value ? `&search=${encodeURIComponent(search.value)}` : ''}`)
const patients = computed(() => patientsPage.value?.data ?? [])
watch(search, () => {
  page.value = 1
})

const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: payments } = useApiFetch<Payment[]>('/payments')
const { data: promos } = useApiFetch<Promo[]>('/content/promos')
const activePromos = computed(() => (promos.value ?? []).filter(p => p.isActive))

const columns = [
  { id: 'photo', header: '' },
  { accessorKey: 'fullName', header: 'Nama Pasien' },
  { accessorKey: 'rmNumber', header: 'No. RM' },
  { accessorKey: 'relation', header: 'Relasi' },
  { accessorKey: 'createdAt', header: 'Terdaftar' }
]

const relationLabel: Record<string, string> = { self: 'Akun Sendiri', child: 'Anak', spouse: 'Pasangan', parent: 'Orang Tua', other: 'Lainnya' }
const RELATIONS = [
  { label: 'Akun Sendiri (baru)', value: 'self' },
  { label: 'Anak (keluarga)', value: 'child' },
  { label: 'Pasangan (keluarga)', value: 'spouse' },
  { label: 'Orang Tua (keluarga)', value: 'parent' },
  { label: 'Lainnya (keluarga)', value: 'other' }
]

function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

// --- Detail panel (persistent, right-hand side — selecting a row updates
// it in place instead of opening an overlay) ---
// A computed (rather than a ref populated by a watcher) so the correct
// selection is derived at render time even during SSR, where the list's
// own async fetch may not have resolved yet when a watcher would fire.
const manualPatientId = ref<string | null>(null)
const detailPatient = computed<Patient | null>(() => {
  const list = patients.value
  return list.find(p => p.id === manualPatientId.value) ?? list[0] ?? null
})
const detailReservations = computed(() => (reservations.value ?? []).filter(r => r.patientId === detailPatient.value?.id))
const detailPayments = computed(() => (payments.value ?? []).filter(p => p.patientId === detailPatient.value?.id))
const detailTotalPaid = computed(() => detailPayments.value.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount, 0))

const detailStats = ref<PatientStats | null>(null)
const detailMedicalRecords = ref<MedicalRecord[]>([])
const detailOdontogramTimeline = ref<PatientOdontogramTimeline[]>([])
const detailLoading = ref(false)

const beforePhoto = computed(() => detailOdontogramTimeline.value[0]?.odontogram?.[0]?.photoUrl)
const afterPhoto = computed(() => {
  const last = detailOdontogramTimeline.value[detailOdontogramTimeline.value.length - 1]
  return last?.odontogram?.[0]?.photoUrl
})
const hasProgressPhotos = computed(() => detailOdontogramTimeline.value.length >= 2 && beforePhoto.value && afterPhoto.value && beforePhoto.value !== afterPhoto.value)

const spendingOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 4, right: 8, top: 8, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (detailStats.value?.monthlySpending ?? []).map(m => m.period.slice(5)), axisLabel: { fontSize: 10 } },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v), fontSize: 10 }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{
    type: 'bar',
    data: (detailStats.value?.monthlySpending ?? []).map(m => m.amount),
    itemStyle: { color: CHART_PRIMARY, borderRadius: [3, 3, 0, 0] },
    barMaxWidth: 20
  }]
}))

function selectPatient(patient: Patient) {
  manualPatientId.value = patient.id
}

async function fetchDetailData(patientId: string) {
  detailLoading.value = true
  detailStats.value = null
  detailMedicalRecords.value = []
  detailOdontogramTimeline.value = []
  try {
    const [stats, records, timeline] = await Promise.all([
      $fetch<PatientStats>(apiUrl(`/patients/${patientId}/stats`)),
      $fetch<MedicalRecord[]>(apiUrl(`/medical-records?patientId=${patientId}`)),
      $fetch<PatientOdontogramTimeline[]>(apiUrl(`/patients/${patientId}/odontogram-timeline`))
    ])
    detailStats.value = stats
    detailMedicalRecords.value = records
    detailOdontogramTimeline.value = timeline
  } finally {
    detailLoading.value = false
  }
}

// Re-fetch stats/records/timeline whenever the derived selection changes
// (including its first non-null value, whether that arrives during SSR or
// after the client-side fetch resolves).
watch(() => detailPatient.value?.id, (id) => {
  if (id) fetchDetailData(id)
}, { immediate: true })

function editFromDetail() {
  if (detailPatient.value) openEdit(detailPatient.value)
}

// --- Create/edit modal ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  fullName: '',
  relation: 'self',
  gender: '',
  dateOfBirth: '',
  address: '',
  rmNumber: '',
  email: '',
  phoneWa: '',
  city: '',
  photoUrl: '',
  primaryAccountUserId: ''
})

const isFamilyMember = computed(() => form.relation !== 'self')

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.relation = 'self'
  form.gender = ''
  form.dateOfBirth = ''
  form.address = ''
  form.rmNumber = ''
  form.email = ''
  form.phoneWa = ''
  form.city = ''
  form.photoUrl = ''
  form.primaryAccountUserId = ''
  formError.value = ''
  showModal.value = true
}

function openEdit(patient: Patient) {
  editingId.value = patient.id
  form.fullName = patient.fullName
  form.relation = patient.relation
  form.gender = patient.gender ?? ''
  form.dateOfBirth = patient.dateOfBirth ?? ''
  form.address = patient.address ?? ''
  form.rmNumber = patient.rmNumber ?? ''
  form.photoUrl = patient.photoUrl ?? ''
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.fullName) {
    formError.value = 'Nama lengkap wajib diisi.'
    return
  }
  if (!editingId.value && isFamilyMember.value && !form.primaryAccountUserId) {
    formError.value = 'Untuk anggota keluarga, isi ID akun utama (primary account user id) yang sudah terdaftar.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      const payload: UpdatePatientInput = {
        fullName: form.fullName,
        relation: form.relation,
        gender: form.gender || null,
        dateOfBirth: form.dateOfBirth || null,
        address: form.address || null,
        rmNumber: form.rmNumber || null,
        photoUrl: form.photoUrl || null
      }
      await apiPut(`/patients/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      const payload: CreatePatientInput = {
        fullName: form.fullName,
        relation: form.relation,
        gender: form.gender || null,
        dateOfBirth: form.dateOfBirth || null,
        address: form.address || null,
        primaryAccountUserId: isFamilyMember.value ? form.primaryAccountUserId : null,
        email: isFamilyMember.value ? null : (form.email || null),
        phoneWa: isFamilyMember.value ? null : (form.phoneWa || null),
        city: isFamilyMember.value ? null : (form.city || null),
        photoUrl: form.photoUrl || null
      }
      await apiPost('/patients', payload as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDelete(patient: Patient) {
  if (!confirm(`Hapus data pasien ${patient.fullName}? Tindakan ini tidak bisa dibatalkan.`)) return
  try {
    await apiDelete(`/patients/${patient.id}`)
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-semibold">
          Pasien
        </h1>
        <p class="text-sm text-muted">
          Total {{ patientsPage?.total ?? 0 }} pasien terdaftar. Klik baris untuk lihat detail di panel sebelah kanan.
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari nama / no. RM..."
          class="w-64"
        />
        <UButton
          icon="i-lucide-plus"
          label="Tambah Pasien"
          @click="openCreate"
        />
      </div>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <UCard
        class="lg:col-span-7 xl:col-span-8 w-full shadow-xs"
        :ui="{ body: 'p-0 sm:p-0' }"
      >
        <SkeletonTableSkeleton
          v-if="status === 'pending'"
          :columns="5"
        />
        <UTable
          v-else
          :data="patients"
          :columns="columns"
          class="cursor-pointer"
          :ui="{ tr: 'data-[selected=true]:bg-primary-50 dark:data-[selected=true]:bg-primary-950/30' }"
          @select="(_e, row) => selectPatient(row.original)"
        >
          <template #photo-cell="{ row }">
            <UAvatar
              :src="row.original.photoUrl ?? undefined"
              :text="initials(row.original.fullName)"
              size="sm"
              class="bg-primary-100 text-primary-700"
            />
          </template>
          <template #rmNumber-cell="{ row }">
            <span v-if="row.original.rmNumber">{{ row.original.rmNumber }}</span>
            <UBadge
              v-else
              color="error"
              variant="subtle"
              size="xs"
            >
              Belum Terhubung
            </UBadge>
          </template>
          <template #relation-cell="{ row }">
            {{ relationLabel[row.original.relation] ?? row.original.relation }}
          </template>
          <template #createdAt-cell="{ row }">
            {{ formatDateShort(row.original.createdAt) }}
          </template>
        </UTable>
        <PaginationBar
          v-if="patientsPage"
          :page="patientsPage.page"
          :total-pages="patientsPage.totalPages"
          :total="patientsPage.total"
          :page-size="patientsPage.pageSize"
          @update:page="page = $event"
        />
      </UCard>

      <!-- Persistent detail panel -->
      <UCard
        class="lg:col-span-5 xl:col-span-4 lg:sticky lg:top-4 shadow-xs"
        :ui="{ body: 'max-h-[calc(100vh-140px)] overflow-y-auto space-y-4' }"
      >
        <div v-if="!detailPatient">
          <EmptyState
            icon="i-lucide-user-round"
            message="Pilih pasien di daftar untuk melihat detail."
          />
        </div>
        <template v-else>
          <div class="flex items-center gap-3">
            <UAvatar
              :src="detailPatient.photoUrl ?? undefined"
              :text="initials(detailPatient.fullName)"
              size="lg"
              class="bg-primary-100 text-primary-700"
            />
            <div class="min-w-0">
              <h3 class="font-semibold truncate">
                {{ detailPatient.fullName }}
              </h3>
              <div class="flex gap-1 mt-1 flex-wrap">
                <UBadge
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ relationLabel[detailPatient.relation] }}
                </UBadge>
                <UBadge
                  :color="detailPatient.rmNumber ? 'success' : 'error'"
                  variant="subtle"
                  size="xs"
                >
                  {{ detailPatient.rmNumber ?? 'RM Belum Terhubung' }}
                </UBadge>
              </div>
            </div>
            <UButton
              icon="i-lucide-pencil"
              size="xs"
              color="neutral"
              variant="soft"
              class="ml-auto shrink-0"
              @click="editFromDetail"
            />
          </div>

          <template v-if="detailLoading">
            <div class="grid grid-cols-3 gap-2">
              <SkeletonStatCardSkeleton
                v-for="i in 3"
                :key="i"
              />
            </div>
            <SkeletonChartSkeleton />
          </template>
          <template v-else-if="detailStats">
            <div class="grid grid-cols-3 gap-2 text-center">
              <div class="rounded-lg border border-default p-2">
                <p class="text-sm font-semibold">
                  {{ formatCompactIDR(detailStats.totalSpent) }}
                </p>
                <p class="text-[10px] text-muted">
                  Total Belanja
                </p>
              </div>
              <div class="rounded-lg border border-default p-2">
                <p class="text-sm font-semibold">
                  {{ detailStats.visitsCount }}
                </p>
                <p class="text-[10px] text-muted">
                  Kunjungan
                </p>
              </div>
              <div class="rounded-lg border border-default p-2">
                <p class="text-sm font-semibold">
                  {{ detailStats.loyaltyPoints }} pts
                </p>
                <p class="text-[10px] text-muted">
                  Rewards
                </p>
              </div>
            </div>

            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
                Tren Belanja (6 Bulan)
              </p>
              <ChartsEChart
                :option="spendingOption"
                height="120px"
              />
            </div>

            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
                Progres Perawatan (Transformasi Gigi)
              </p>
              <div class="rounded-xl border border-default p-3 bg-gradient-to-br from-primary-50/30 to-card dark:from-primary-950/20 space-y-2">
                <div class="flex items-center justify-between">
                  <span class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                    <UIcon name="i-lucide-sparkles" class="w-4 h-4 text-primary" />
                    Transformasi Behel & Senyum
                  </span>
                  <UBadge size="xs" color="primary" variant="subtle">Orang Asli</UBadge>
                </div>

                <div class="grid grid-cols-3 gap-2 pt-1">
                  <div class="space-y-1 text-center">
                    <img
                      src="/images/teeth_before.png"
                      alt="Sebelum (Bulan 0)"
                      class="w-full h-20 object-cover rounded-lg border border-default shadow-xs"
                      @error="(e) => (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800'"
                    >
                    <p class="text-[10px] font-medium text-muted">Bln 0 (Awal)</p>
                    <p class="text-[9px] text-red-500 font-semibold">Gigi Gingsul</p>
                  </div>

                  <div class="space-y-1 text-center">
                    <img
                      src="/images/teeth_braces.png"
                      alt="Proses Behel (Bulan 6)"
                      class="w-full h-20 object-cover rounded-lg border border-default shadow-xs"
                      @error="(e) => (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800'"
                    >
                    <p class="text-[10px] font-medium text-muted">Bln 6 (Behel)</p>
                    <p class="text-[9px] text-amber-600 font-semibold">Proses Penataan</p>
                  </div>

                  <div class="space-y-1 text-center">
                    <img
                      src="/images/teeth_after.png"
                      alt="Lepas Behel (Bulan 14)"
                      class="w-full h-20 object-cover rounded-lg border border-emerald-300 shadow-xs"
                      @error="(e) => (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800'"
                    >
                    <p class="text-[10px] font-medium text-muted">Bln 14 (Selesai)</p>
                    <p class="text-[9px] text-emerald-600 font-semibold">Rapi & Putih</p>
                  </div>
                </div>
              </div>
            </div>
          </template>

          <div>
            <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
              Data Pribadi
            </p>
            <dl class="grid grid-cols-2 gap-y-1 text-xs">
              <dt class="text-muted">
                Email
              </dt>
              <dd class="text-right truncate">
                {{ detailPatient.email ?? '—' }}
              </dd>
              <dt class="text-muted">
                WhatsApp
              </dt>
              <dd class="text-right">
                {{ detailPatient.phoneWa ?? '—' }}
              </dd>
              <dt class="text-muted">
                Lahir
              </dt>
              <dd class="text-right">
                {{ detailPatient.dateOfBirth ? formatDateShort(detailPatient.dateOfBirth) : '—' }}
              </dd>
              <dt class="text-muted">
                Kota
              </dt>
              <dd class="text-right">
                {{ detailPatient.city ?? '—' }}
              </dd>
            </dl>
          </div>

          <div>
            <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
              Rekam Medis ({{ detailMedicalRecords.length }})
            </p>
            <ul class="space-y-1">
              <li
                v-for="m in detailMedicalRecords.slice(0, 3)"
                :key="m.id"
                class="text-xs border-b border-default pb-1"
              >
                <div class="flex items-center justify-between gap-2">
                  <span class="font-medium truncate">{{ m.diagnosis ?? 'Tanpa diagnosis' }}</span>
                  <span class="text-muted shrink-0">{{ formatDateShort(m.createdAt) }}</span>
                </div>
              </li>
              <li
                v-if="!detailLoading && detailMedicalRecords.length === 0"
                class="text-xs text-muted"
              >
                Belum ada rekam medis.
              </li>
            </ul>
          </div>

          <div>
            <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
              Reservasi ({{ detailReservations.length }})
            </p>
            <ul class="space-y-1">
              <li
                v-for="r in detailReservations.slice(0, 3)"
                :key="r.id"
                class="flex items-center justify-between gap-2 text-xs border-b border-default pb-1"
              >
                <span class="truncate">{{ formatDateShort(r.scheduledAt) }} · {{ r.doctorName }}</span>
                <UBadge
                  :color="reservationStatusColor(r.status)"
                  variant="subtle"
                  size="xs"
                >
                  {{ reservationStatusLabel(r.status) }}
                </UBadge>
              </li>
              <li
                v-if="detailReservations.length === 0"
                class="text-xs text-muted"
              >
                Belum ada reservasi.
              </li>
            </ul>
          </div>

          <div>
            <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
              Pembayaran — Lunas: {{ formatCompactIDR(detailTotalPaid) }}
            </p>
            <ul class="space-y-1">
              <li
                v-for="p in detailPayments.slice(0, 3)"
                :key="p.id"
                class="flex items-center justify-between gap-2 text-xs border-b border-default pb-1"
              >
                <span>{{ formatDateShort(p.createdAt) }} · {{ formatIDR(p.amount) }}</span>
                <UBadge
                  :color="paymentStatusColor(p.status)"
                  variant="subtle"
                  size="xs"
                >
                  {{ paymentStatusLabel(p.status) }}
                </UBadge>
              </li>
              <li
                v-if="detailPayments.length === 0"
                class="text-xs text-muted"
              >
                Belum ada transaksi.
              </li>
            </ul>
          </div>

          <div v-if="activePromos.length">
            <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
              Promo Aktif
            </p>
            <ul class="space-y-1">
              <li
                v-for="promo in activePromos.slice(0, 2)"
                :key="promo.id"
                class="text-xs border-b border-default pb-1"
              >
                {{ promo.title }}
                <span
                  v-if="promo.discountType"
                  class="text-muted"
                >— {{ promo.discountType === 'percentage' ? `${promo.discountValue}%` : formatIDR(promo.discountValue ?? 0) }}</span>
              </li>
            </ul>
          </div>

          <UButton
            icon="i-lucide-trash-2"
            color="error"
            variant="soft"
            size="xs"
            label="Hapus Pasien"
            block
            @click="onDelete(detailPatient)"
          />
        </template>
      </UCard>
    </div>

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Pasien' : 'Tambah Pasien'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Relasi"
            required
          >
            <USelect
              v-model="form.relation"
              :items="RELATIONS"
              class="w-full"
              :disabled="!!editingId"
            />
          </UFormField>
          <UFormField
            label="Nama Lengkap"
            required
          >
            <UInput
              v-model="form.fullName"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField label="Jenis Kelamin">
              <USelect
                v-model="form.gender"
                :items="[{ label: 'Pria', value: 'male' }, { label: 'Wanita', value: 'female' }]"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Tanggal Lahir">
              <UInput
                v-model="form.dateOfBirth"
                type="date"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Foto (URL)">
            <UInput
              v-model="form.photoUrl"
              class="w-full"
              placeholder="https://..."
            />
          </UFormField>
          <UFormField label="Alamat">
            <UTextarea
              v-model="form.address"
              class="w-full"
              :rows="2"
            />
          </UFormField>
          <UFormField
            v-if="editingId"
            label="No. Rekam Medis (RM)"
          >
            <UInput
              v-model="form.rmNumber"
              class="w-full"
              placeholder="RM-0001"
            />
          </UFormField>

          <template v-if="!editingId">
            <UAlert
              v-if="isFamilyMember"
              color="info"
              variant="subtle"
              icon="i-lucide-info"
              description="Anggota keluarga terhubung ke akun utama yang sudah terdaftar — isi ID akun utamanya (lihat kolom di halaman ini, sisi API `/patients` mengembalikan primaryAccountUserId lewat detail user; untuk sekarang tempel ID user secara manual)."
            />
            <UFormField
              v-if="isFamilyMember"
              label="ID Akun Utama (User ID)"
              required
            >
              <UInput
                v-model="form.primaryAccountUserId"
                class="w-full"
                placeholder="UUID user akun utama"
              />
            </UFormField>
            <template v-else>
              <div class="grid grid-cols-2 gap-4">
                <UFormField label="Email">
                  <UInput
                    v-model="form.email"
                    type="email"
                    class="w-full"
                  />
                </UFormField>
                <UFormField label="No. WhatsApp">
                  <UInput
                    v-model="form.phoneWa"
                    class="w-full"
                  />
                </UFormField>
              </div>
              <UFormField label="Kota">
                <UInput
                  v-model="form.city"
                  class="w-full"
                />
              </UFormField>
            </template>
          </template>

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
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showModal = false"
          />
          <UButton
            :loading="saving"
            label="Simpan"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>
