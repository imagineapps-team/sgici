<template>
  <div class="w-full">
    <label
      v-if="label"
      :for="inputId"
      class="block text-sm font-medium text-gray-700 mb-1"
    >
      {{ label }}
      <span v-if="required" class="text-red-500">*</span>
    </label>

    <input
      :id="inputId"
      :value="displayValue"
      :type="nativeType"
      :placeholder="placeholder"
      :disabled="disabled"
      :maxlength="maxlength"
      :min="min"
      :max="max"
      :step="step"
      class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-brand-primary transition-colors"
      :class="[
        error ? 'border-red-500' : 'border-gray-300',
        disabled ? 'bg-gray-100 cursor-not-allowed' : 'bg-white'
      ]"
      @input="handleInput"
      @blur="handleBlur"
      @focus="$emit('focus', $event)"
    />

    <p v-if="error" class="mt-1 text-sm text-red-500">
      {{ error }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { IInputProps } from './types'

const props = withDefaults(defineProps<IInputProps>(), {
  type: 'text',
  required: false,
  disabled: false,
  placeholder: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: string | number | null]
  blur: [event: FocusEvent]
  focus: [event: FocusEvent]
}>()

const inputId = computed(() => props.id || `input-${Math.random().toString(36).substr(2, 9)}`)

const nativeType = computed(() => {
  switch (props.type) {
    case 'number':
    case 'money':
      return 'text'
    case 'date':
      return 'date'
    case 'email':
      return 'email'
    case 'password':
      return 'password'
    case 'tel':
      return 'tel'
    default:
      return 'text'
  }
})

const displayValue = computed(() => {
  if (props.modelValue === null || props.modelValue === undefined) return ''

  switch (props.type) {
    case 'money':
      return formatMoney(props.modelValue)
    case 'cpf_cnpj':
      return formatCpfCnpj(String(props.modelValue))
    default:
      return String(props.modelValue)
  }
})

function formatMoney(value: string | number): string {
  const num = typeof value === 'string' ? parseFloat(value.replace(/\D/g, '')) / 100 : value
  if (isNaN(num)) return ''
  return num.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function formatCpfCnpj(value: string): string {
  const cleaned = value.replace(/\D/g, '')
  if (cleaned.length <= 11) {
    return cleaned
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d{1,2})$/, '$1-$2')
  } else {
    return cleaned
      .replace(/(\d{2})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d)/, '$1/$2')
      .replace(/(\d{4})(\d{1,2})$/, '$1-$2')
  }
}

function parseMoney(value: string): number {
  const cleaned = value.replace(/\./g, '').replace(',', '.')
  return parseFloat(cleaned) || 0
}

function parseCpfCnpj(value: string): string {
  return value.replace(/\D/g, '').slice(0, 14)
}

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  let value: string | number | null = target.value

  switch (props.type) {
    case 'number':
      value = value === '' ? null : parseFloat(value)
      break
    case 'money':
      const moneyClean = value.replace(/\D/g, '')
      value = moneyClean === '' ? null : parseInt(moneyClean) / 100
      target.value = formatMoney(value || 0)
      break
    case 'cpf_cnpj':
      value = parseCpfCnpj(value)
      target.value = formatCpfCnpj(value)
      break
  }

  emit('update:modelValue', value)
}

function handleBlur(event: FocusEvent) {
  emit('blur', event)
}
</script>
