<script setup lang="ts">
defineProps<{
  title: string
  description: string
  icon: string
  phase: 1 | 2 | 3
}>()

const phaseLabel: Record<1 | 2 | 3, string> = {
  1: 'Fase 1 — MVP Core Journey',
  2: 'Fase 2 — Klinis & Operasional',
  3: 'Fase 3 — Growth & Hardening'
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div>
      <h1 class="text-xl font-semibold">
        {{ title }}
      </h1>
      <p class="text-sm text-muted">
        {{ description }}
      </p>
    </div>

    <UPageCard
      :icon="icon"
      :title="`Modul ${title} belum diimplementasikan`"
      :description="`Dijadwalkan pada ${phaseLabel[phase]}. Lihat docs/architecture.md untuk detail scope.`"
    />
  </UContainer>
</template>
