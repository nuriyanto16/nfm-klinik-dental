<script setup lang="ts">
withDefaults(defineProps<{ bars?: number }>(), { bars: 7 })
</script>

<template>
  <div class="flex items-end gap-2 h-48 px-2">
    <USkeleton
      v-for="b in bars"
      :key="b"
      class="flex-1 rounded-t-md"
      :style="{ height: `${30 + ((b * 37) % 65)}%` }"
    />
  </div>
</template>
