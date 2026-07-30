<script setup lang="ts">
import type { CreateUserInput, StaffUser, UpdateUserInput } from '~/types/api'

definePageMeta({ title: 'User & Role' })

const { data: users, status, refresh, error } = useApiFetch<StaffUser[]>('/users')
const { data: roles } = useApiFetch<string[]>('/roles')

const roleLabel: Record<string, string> = {
  perawat: 'Perawat',
  admin_cabang: 'Admin Cabang',
  finance: 'Finance',
  superadmin: 'Superadmin',
  dokter: 'Dokter'
}
const roleColor: Record<string, BadgeColor> = {
  superadmin: 'error',
  admin_cabang: 'warning',
  finance: 'info',
  perawat: 'success',
  dokter: 'primary'
}

const columns = [
  { accessorKey: 'fullName', header: 'Nama' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'phoneWa', header: 'No. WhatsApp' },
  { accessorKey: 'role', header: 'Role' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

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
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          User & Role
        </h1>
        <p class="text-sm text-muted">
          Kelola akun staf non-dokter (perawat, admin cabang, finance, superadmin). Akun dokter dikelola di halaman Dokter & Jadwal.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah User"
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
      :columns="6"
    />
    <UTable
      v-else
      :data="users ?? []"
      :columns="columns"
    >
      <template #role-cell="{ row }">
        <UBadge
          :color="roleColor[row.original.role] ?? 'neutral'"
          variant="subtle"
        >
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
            @click="openEdit(row.original)"
          />
          <UButton
            v-if="row.original.isActive"
            icon="i-lucide-user-x"
            size="xs"
            color="error"
            variant="ghost"
            @click="onDeactivate(row.original)"
          />
        </div>
      </template>
    </UTable>

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit User' : 'Tambah User'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Nama Lengkap"
            required
          >
            <UInput
              v-model="form.fullName"
              class="w-full"
            />
          </UFormField>
          <UFormField
            v-if="!editingId"
            label="Email"
            required
          >
            <UInput
              v-model="form.email"
              type="email"
              class="w-full"
            />
          </UFormField>
          <UFormField
            v-if="!editingId"
            label="No. WhatsApp"
          >
            <UInput
              v-model="form.phoneWa"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Role"
            required
          >
            <USelect
              v-model="form.role"
              :items="(roles ?? []).map(r => ({ label: roleLabel[r] ?? r, value: r }))"
              class="w-full"
            />
          </UFormField>
          <UFormField
            v-if="!editingId"
            label="Password"
            required
          >
            <UInput
              v-model="form.password"
              type="password"
              class="w-full"
              placeholder="Minimal 8 karakter"
            />
          </UFormField>
          <UFormField
            v-if="editingId"
            label="Status Akun"
          >
            <USwitch
              v-model="form.isActive"
              :label="form.isActive ? 'Aktif' : 'Nonaktif'"
            />
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
