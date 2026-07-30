<script setup lang="ts">
import type { CreatePatientInput, Patient, Payment, Reservation, UpdatePatientInput } from '~/types/api'

definePageMeta({ title: 'Pasien' })

const { data: patients, status, refresh, error } = useApiFetch<Patient[]>('/patients')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: payments } = useApiFetch<Payment[]>('/payments')

const columns = [
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

function openDetail(patient: Patient) {
  detailPatient.value = patient
  showDetail.value = true
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
        rmNumber: form.rmNumber || null
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
        city: isFamilyMember.value ? null : (form.city || null)
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
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          Pasien
        </h1>
        <p class="text-sm text-muted">
          Termasuk anggota keluarga yang terhubung ke akun utama (relasi "Anak", dst). Klik baris untuk lihat detail lengkap.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Pasien"
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

    <SkeletonTableSkeleton
      v-if="status === 'pending'"
      :columns="7"
    />
    <UTable
      v-else
      :data="patients ?? []"
      :columns="columns"
      class="cursor-pointer"
      @select="(_e, row) => openDetail(row.original)"
    >
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

    <!-- Detail panel -->
    <USlideover
      v-model:open="showDetail"
      :ui="{ content: 'max-w-md' }"
    >
      <template #body>
        <div
          v-if="detailPatient"
          class="space-y-6"
        >
          <div class="flex items-center gap-3">
            <UAvatar
              :text="initials(detailPatient.fullName)"
              size="lg"
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
