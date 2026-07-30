<template>
  <div>
    <div class="flex items-center justify-between mb-3">
      <USkeleton class="h-5 w-32" />
      <USkeleton class="h-7 w-24" />
    </div>
    <div class="grid grid-cols-7 gap-1">
      <USkeleton
        v-for="i in 35"
        :key="i"
        class="h-20 rounded-md"
      />
    </div>
  </div>
</template>
