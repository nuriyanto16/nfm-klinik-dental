<script setup lang="ts">
defineProps<{
  icon: string
  message: string
}>()
</script>

<template>
  <div class="flex flex-col items-center justify-center gap-2 py-10 text-center">
    <UIcon
      :name="icon"
      class="size-8 text-muted"
    />
    <p class="text-sm text-muted max-w-xs">
      {{ message }}
    </p>
  </div>
</template>
