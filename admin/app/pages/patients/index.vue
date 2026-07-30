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
  { accessorKey: 'phoneWa', header: 'No. WhatsApp' },
  { accessorKey: 'city', header: 'Kota' },
  { accessorKey: 'createdAt', header: 'Terdaftar' },
  { id: 'actions', header: '' }
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

// --- Detail panel ---
const showDetail = ref(false)
const detailPatient = ref<Patient | null>(null)
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
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (detailStats.value?.monthlySpending ?? []).map(m => m.period.slice(5)) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{
    type: 'bar',
    data: (detailStats.value?.monthlySpending ?? []).map(m => m.amount),
    itemStyle: { color: CHART_PRIMARY, borderRadius: [4, 4, 0, 0] },
    barMaxWidth: 28
  }]
}))

async function openDetail(patient: Patient) {
  detailPatient.value = patient
  showDetail.value = true
  detailLoading.value = true
  detailStats.value = null
  detailMedicalRecords.value = []
  detailOdontogramTimeline.value = []
  try {
    const [stats, records, timeline] = await Promise.all([
      $fetch<PatientStats>(apiUrl(`/patients/${patient.id}/stats`)),
      $fetch<MedicalRecord[]>(apiUrl(`/medical-records?patientId=${patient.id}`)),
      $fetch<PatientOdontogramTimeline[]>(apiUrl(`/patients/${patient.id}/odontogram-timeline`))
    ])
    detailStats.value = stats
    detailMedicalRecords.value = records
    detailOdontogramTimeline.value = timeline
  } finally {
    detailLoading.value = false
  }
}
function editFromDetail() {
  if (detailPatient.value) openEdit(detailPatient.value)
  showDetail.value = false
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
    showDetail.value = false
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-semibold">
          Pasien
        </h1>
        <p class="text-sm text-muted">
          Termasuk anggota keluarga yang terhubung ke akun utama (relasi "Anak", dst). Klik baris untuk lihat detail lengkap.
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari nama / no. RM..."
          class="w-56"
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

    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <SkeletonTableSkeleton
        v-if="status === 'pending'"
        :columns="8"
      />
      <UTable
        v-else
        :data="patients"
        :columns="columns"
        class="cursor-pointer"
        @select="(_e, row) => openDetail(row.original)"
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
          >
            Belum Terhubung
          </UBadge>
        </template>
        <template #relation-cell="{ row }">
          {{ relationLabel[row.original.relation] ?? row.original.relation }}
        </template>
        <template #createdAt-cell="{ row }">
          {{ formatDateTime(row.original.createdAt) }}
        </template>
        <template #actions-cell="{ row }">
          <div
            class="flex justify-end gap-1"
            @click.stop
          >
            <UButton
              icon="i-lucide-eye"
              size="xs"
              color="neutral"
              variant="ghost"
              @click="openDetail(row.original)"
            />
            <UButton
              icon="i-lucide-pencil"
              size="xs"
              color="neutral"
              variant="ghost"
              @click="openEdit(row.original)"
            />
            <UButton
              icon="i-lucide-trash-2"
              size="xs"
              color="error"
              variant="ghost"
              @click="onDelete(row.original)"
            />
          </div>
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

    <!-- Detail panel -->
    <USlideover
      v-model:open="showDetail"
      :ui="{ content: 'max-w-lg' }"
    >
      <template #body>
        <div
          v-if="detailPatient"
          class="space-y-6"
        >
          <div class="flex items-center gap-3">
            <UAvatar
              :src="detailPatient.photoUrl ?? undefined"
              :text="initials(detailPatient.fullName)"
              size="xl"
              class="bg-primary-100 text-primary-700"
            />
            <div>
              <h3 class="font-semibold">
                {{ detailPatient.fullName }}
              </h3>
              <div class="flex gap-1 mt-1">
                <UBadge
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ relationLabel[detailPatient.relation] }}
                </UBadge>
                <UBadge
                  v-if="detailPatient.rmNumber"
                  color="success"
                  variant="subtle"
                  size="xs"
                >
                  {{ detailPatient.rmNumber }}
                </UBadge>
                <UBadge
                  v-else
                  color="error"
                  variant="subtle"
                  size="xs"
                >
                  RM Belum Terhubung
                </UBadge>
              </div>
            </div>
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
            <div class="grid grid-cols-3 gap-2">
              <UPageCard
                :title="formatCompactIDR(detailStats.totalSpent)"
                description="Total Belanja"
              />
              <UPageCard
                :title="String(detailStats.visitsCount)"
                description="Kunjungan Lunas"
              />
              <UPageCard
                :title="`${detailStats.loyaltyPoints} pts`"
                description="Poin Rewards"
              />
            </div>

            <div>
              <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                Tren Belanja (6 Bulan)
              </h4>
              <ChartsEChart
                :option="spendingOption"
                height="180px"
              />
            </div>

            <div v-if="hasProgressPhotos">
              <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                Progres Perawatan (Sebelum vs. Sesudah)
              </h4>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <img
                    :src="beforePhoto!"
                    alt="Sebelum"
                    class="w-full h-32 object-cover rounded-lg border border-default"
                  >
                  <p class="text-xs text-muted text-center mt-1">
                    Sebelum
                  </p>
                </div>
                <div>
                  <img
                    :src="afterPhoto!"
                    alt="Sesudah"
                    class="w-full h-32 object-cover rounded-lg border border-default"
                  >
                  <p class="text-xs text-muted text-center mt-1">
                    Sesudah
                  </p>
                </div>
              </div>
            </div>
          </template>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Data Pribadi
            </h4>
            <dl class="grid grid-cols-2 gap-y-2 text-sm">
              <dt class="text-muted">
                Email
              </dt>
              <dd class="text-right">
                {{ detailPatient.email ?? '—' }}
              </dd>
              <dt class="text-muted">
                No. WhatsApp
              </dt>
              <dd class="text-right">
                {{ detailPatient.phoneWa ?? '—' }}
              </dd>
              <dt class="text-muted">
                Tanggal Lahir
              </dt>
              <dd class="text-right">
                {{ detailPatient.dateOfBirth ? formatDateShort(detailPatient.dateOfBirth) : '—' }}
              </dd>
              <dt class="text-muted">
                Jenis Kelamin
              </dt>
              <dd class="text-right">
                {{ detailPatient.gender === 'male' ? 'Pria' : detailPatient.gender === 'female' ? 'Wanita' : '—' }}
              </dd>
              <dt class="text-muted">
                Kota
              </dt>
              <dd class="text-right">
                {{ detailPatient.city ?? '—' }}
              </dd>
              <dt class="text-muted">
                Alamat
              </dt>
              <dd class="text-right">
                {{ detailPatient.address ?? '—' }}
              </dd>
              <dt class="text-muted">
                Terdaftar Sejak
              </dt>
              <dd class="text-right">
                {{ formatDateTime(detailPatient.createdAt) }}
              </dd>
            </dl>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Riwayat Rekam Medis ({{ detailMedicalRecords.length }})
            </h4>
            <div
              v-if="!detailLoading && detailMedicalRecords.length === 0"
              class="text-sm text-muted"
            >
              Belum ada rekam medis.
            </div>
            <ul
              v-else
              class="space-y-2"
            >
              <li
                v-for="m in detailMedicalRecords.slice(0, 5)"
                :key="m.id"
                class="text-sm border-b border-default pb-2"
              >
                <div class="flex items-center justify-between">
                  <p class="font-medium">
                    {{ m.diagnosis ?? 'Tanpa diagnosis' }}
                  </p>
                  <p class="text-xs text-muted">
                    {{ formatDateShort(m.createdAt) }}
                  </p>
                </div>
                <p class="text-xs text-muted">
                  {{ m.doctorName }}
                </p>
              </li>
            </ul>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Riwayat Reservasi ({{ detailReservations.length }})
            </h4>
            <div
              v-if="detailReservations.length === 0"
              class="text-sm text-muted"
            >
              Belum ada reservasi.
            </div>
            <ul
              v-else
              class="space-y-2"
            >
              <li
                v-for="r in detailReservations.slice(0, 6)"
                :key="r.id"
                class="flex items-center justify-between text-sm border-b border-default pb-2"
              >
                <div>
                  <p>{{ formatDateTime(r.scheduledAt) }}</p>
                  <p class="text-xs text-muted">
                    {{ r.doctorName }} · {{ r.branchName }}
                  </p>
                </div>
                <UBadge
                  :color="reservationStatusColor(r.status)"
                  variant="subtle"
                  size="xs"
                >
                  {{ reservationStatusLabel(r.status) }}
                </UBadge>
              </li>
            </ul>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Riwayat Pembayaran ({{ detailPayments.length }}) — Total Lunas: {{ formatIDR(detailTotalPaid) }}
            </h4>
            <div
              v-if="detailPayments.length === 0"
              class="text-sm text-muted"
            >
              Belum ada transaksi.
            </div>
            <ul
              v-else
              class="space-y-2"
            >
              <li
                v-for="p in detailPayments.slice(0, 6)"
                :key="p.id"
                class="flex items-center justify-between text-sm border-b border-default pb-2"
              >
                <div>
                  <p>{{ formatDateTime(p.createdAt) }}</p>
                  <p class="text-xs text-muted">
                    {{ formatIDR(p.amount) }}
                  </p>
                </div>
                <UBadge
                  :color="paymentStatusColor(p.status)"
                  variant="subtle"
                  size="xs"
                >
                  {{ paymentStatusLabel(p.status) }}
                </UBadge>
              </li>
            </ul>
          </div>

          <div v-if="activePromos.length">
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Promo Aktif untuk Pasien
            </h4>
            <ul class="space-y-2">
              <li
                v-for="promo in activePromos.slice(0, 3)"
                :key="promo.id"
                class="text-sm border-b border-default pb-2"
              >
                <p class="font-medium">
                  {{ promo.title }}
                </p>
                <p
                  v-if="promo.discountType"
                  class="text-xs text-muted"
                >
                  Diskon {{ promo.discountType === 'percentage' ? `${promo.discountValue}%` : formatIDR(promo.discountValue ?? 0) }}
                </p>
              </li>
            </ul>
          </div>

          <div class="flex gap-2 pt-2">
            <UButton
              icon="i-lucide-pencil"
              variant="soft"
              label="Edit"
              class="flex-1"
              @click="editFromDetail"
            />
            <UButton
              icon="i-lucide-trash-2"
              color="error"
              variant="soft"
              label="Hapus"
              class="flex-1"
              @click="onDelete(detailPatient)"
            />
          </div>
        </div>
      </template>
    </USlideover>

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
  </UContainer>
</template>
