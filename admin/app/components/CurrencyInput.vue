<template>
  <UInput
    v-bind="$attrs"
    :model-value="displayValue"
    @update:model-value="val => onInput(val.toString())"
    @blur="onBlur"
    @focus="onFocus"
    type="text"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

const props = defineProps<{
  modelValue: number | null | undefined
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: number | null): void
}>()

const isFocused = ref(false)
const localInputValue = ref('')

// Initialize local input value
watch(() => props.modelValue, (newVal) => {
  if (isFocused.value) return // Don't update local string if user is typing
  
  if (newVal === null || newVal === undefined) {
    localInputValue.value = ''
  } else {
    localInputValue.value = formatCurrency(newVal)
  }
}, { immediate: true })

const displayValue = computed(() => {
  if (isFocused.value) {
    return localInputValue.value
  }
  
  if (props.modelValue === null || props.modelValue === undefined || isNaN(props.modelValue)) {
    return ''
  }
  return formatCurrency(props.modelValue)
})

function formatCurrency(val: number) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(val)
}

function parseNumber(str: string) {
  const numericStr = str.replace(/\D/g, '')
  if (!numericStr) return null
  return parseInt(numericStr, 10)
}

function onInput(val: string) {
  localInputValue.value = val
  const num = parseNumber(val)
  emit('update:modelValue', num)
}

function onFocus() {
  isFocused.value = true
  if (props.modelValue !== null && props.modelValue !== undefined) {
    localInputValue.value = props.modelValue.toString()
  } else {
    localInputValue.value = ''
  }
}

function onBlur() {
  isFocused.value = false
  if (props.modelValue !== null && props.modelValue !== undefined) {
    localInputValue.value = formatCurrency(props.modelValue)
  } else {
    localInputValue.value = ''
  }
}
</script>
