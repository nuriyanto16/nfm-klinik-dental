<script setup lang="ts">
import type { Branch } from '~/types/api'

definePageMeta({ title: 'Cabang' })

const { data: branches, status, error } = useApiFetch<Branch[]>('/branches')

const columns = [
  { accessorKey: 'name', header: 'Nama Cabang' },
  { accessorKey: 'address', header: 'Alamat' },
  { accessorKey: 'phone', header: 'Telepon' },
  { id: 'hours', header: 'Jam Operasional' },
  { accessorKey: 'isActive', header: 'Status' }
]
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div>
      <h1 class="text-xl font-semibold">
        Cabang
      </h1>
      <p class="text-sm text-muted">
        Profil cabang Nina Dental Care.
      </p>
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
      :columns="5"
    />
    <UTable
      v-else
      :data="branches ?? []"
      :columns="columns"
    >
      <template #hours-cell="{ row }">
        {{ row.original.opensAt.slice(0, 5) }} – {{ row.original.closesAt.slice(0, 5) }}
      </template>
      <template #isActive-cell="{ row }">
        <UBadge
          :color="row.original.isActive ? 'success' : 'neutral'"
          variant="subtle"
        >
          {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
        </UBadge>
      </template>
    </UTable>
  </UContainer>
</template>
