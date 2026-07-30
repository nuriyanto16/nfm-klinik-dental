<script setup lang="ts">
import type { Treatment } from '~/types/api'

definePageMeta({ title: 'Perawatan & Harga' })

const { data: treatments, status, error } = useApiFetch<Treatment[]>('/treatments')

const columns = [
  { accessorKey: 'categoryName', header: 'Kategori' },
  { accessorKey: 'name', header: 'Nama Perawatan' },
  { accessorKey: 'price', header: 'Harga' },
  { accessorKey: 'durationMinutes', header: 'Durasi' },
  { accessorKey: 'isActive', header: 'Status' }
]
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div>
      <h1 class="text-xl font-semibold">
        Perawatan & Harga
      </h1>
      <p class="text-sm text-muted">
        Katalog treatment Nina Dental Care.
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
      :data="treatments ?? []"
      :columns="columns"
    >
      <template #price-cell="{ row }">
        {{ formatIDR(row.original.price) }}
      </template>
      <template #durationMinutes-cell="{ row }">
        {{ row.original.durationMinutes }} menit
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
