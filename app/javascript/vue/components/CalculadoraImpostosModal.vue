<template>
  <IModal
    v-model="isOpen"
    title="Calcular Impostos Automaticamente"
    size="xl"
  >
    <div class="space-y-6">
      <!-- Inputs -->
      <div class="bg-gray-50 rounded-lg p-4 space-y-4">
        <h4 class="font-medium text-gray-900">Base de Calculo</h4>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">FOB (USD) *</label>
            <input
              v-model.number="form.fob"
              type="number"
              step="0.01"
              min="0"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              placeholder="0.00"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">Frete (USD)</label>
            <input
              v-model.number="form.frete"
              type="number"
              step="0.01"
              min="0"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              placeholder="0.00"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">Seguro (USD)</label>
            <input
              v-model.number="form.seguro"
              type="number"
              step="0.01"
              min="0"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              placeholder="0.00"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">Taxa Cambio *</label>
            <input
              v-model.number="form.taxaCambio"
              type="number"
              step="0.0001"
              min="0"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              placeholder="5.5000"
              @input="handleInputChange"
            />
          </div>
        </div>
      </div>

      <!-- Aliquotas -->
      <div class="bg-blue-50 rounded-lg p-4 space-y-4">
        <div class="flex items-center justify-between">
          <h4 class="font-medium text-gray-900">Aliquotas</h4>
          <button
            type="button"
            @click="showAliquotas = !showAliquotas"
            class="text-sm text-blue-600 hover:text-blue-800"
          >
            {{ showAliquotas ? 'Ocultar' : 'Personalizar' }}
          </button>
        </div>

        <div v-if="showAliquotas" class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">II (%)</label>
            <input
              v-model.number="aliquotas.ii"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">IPI (%)</label>
            <input
              v-model.number="aliquotas.ipi"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">PIS/COFINS (%)</label>
            <input
              v-model.number="aliquotas.pisCofins"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              @input="handleInputChange"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">ICMS (%)</label>
            <input
              v-model.number="aliquotas.icms"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
              @input="handleInputChange"
            />
          </div>
        </div>

        <div v-else class="text-sm text-gray-600">
          II: {{ (aliquotas.ii * 100).toFixed(1) }}% |
          IPI: {{ (aliquotas.ipi * 100).toFixed(1) }}% |
          PIS/COFINS: {{ (aliquotas.pisCofins * 100).toFixed(1) }}% |
          ICMS: {{ (aliquotas.icms * 100).toFixed(1) }}%
        </div>
      </div>

      <!-- Resultado do Calculo -->
      <div v-if="calculo" class="bg-white border border-gray-200 rounded-lg overflow-hidden">
        <div class="bg-gray-50 px-4 py-3 border-b border-gray-200">
          <h4 class="font-medium text-gray-900">Resultado do Calculo</h4>
        </div>

        <div class="p-4 space-y-3">
          <!-- Valores Base -->
          <div class="grid grid-cols-3 gap-4 pb-3 border-b border-gray-100">
            <div>
              <span class="text-sm text-gray-500">FOB (BRL)</span>
              <p class="font-medium">R$ {{ formatNumber(calculo.fob_brl) }}</p>
            </div>
            <div>
              <span class="text-sm text-gray-500">Frete (BRL)</span>
              <p class="font-medium">R$ {{ formatNumber(calculo.frete_brl) }}</p>
            </div>
            <div>
              <span class="text-sm text-gray-500">Seguro (BRL)</span>
              <p class="font-medium">R$ {{ formatNumber(calculo.seguro_brl) }}</p>
            </div>
          </div>

          <!-- Base de Calculo -->
          <div class="flex justify-between items-center py-2 border-b border-gray-100">
            <span class="text-gray-700">Base de Calculo (CIF)</span>
            <span class="font-semibold text-gray-900">R$ {{ formatNumber(calculo.base_calculo) }}</span>
          </div>

          <!-- Impostos -->
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-gray-600">II ({{ (aliquotas.ii * 100).toFixed(1) }}%)</span>
              <span class="font-medium">R$ {{ formatNumber(calculo.ii) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">IPI ({{ (aliquotas.ipi * 100).toFixed(1) }}%)</span>
              <span class="font-medium">R$ {{ formatNumber(calculo.ipi) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">PIS/COFINS ({{ (aliquotas.pisCofins * 100).toFixed(1) }}%)</span>
              <span class="font-medium">R$ {{ formatNumber(calculo.pis_cofins) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">ICMS ({{ (aliquotas.icms * 100).toFixed(1) }}%)</span>
              <span class="font-medium">R$ {{ formatNumber(calculo.icms) }}</span>
            </div>
          </div>

          <!-- Totais -->
          <div class="pt-3 border-t border-gray-200 space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-gray-700 font-medium">Total Impostos</span>
              <span class="font-semibold text-red-600">R$ {{ formatNumber(calculo.total_impostos) }}</span>
            </div>
            <div class="flex justify-between items-center text-lg">
              <span class="text-gray-900 font-semibold">Custo Total</span>
              <span class="font-bold text-brand-primary">R$ {{ formatNumber(calculo.custo_total) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Aviso -->
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div class="flex items-start gap-3">
          <ExclamationTriangleIcon class="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
          <div class="text-sm text-yellow-800">
            <p class="font-medium">Atenção</p>
            <p>Ao gerar os impostos, os custos previstos de II, IPI, PIS/COFINS e ICMS serao recalculados e substituidos.</p>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <button
          type="button"
          @click="handleCalcular"
          :disabled="!canCalculate || calculating"
          class="px-4 py-2 text-blue-700 bg-blue-50 rounded-lg hover:bg-blue-100 disabled:opacity-50"
        >
          {{ calculating ? 'Calculando...' : 'Calcular Preview' }}
        </button>

        <div class="flex gap-3">
          <button
            type="button"
            @click="handleClose"
            class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
          >
            Cancelar
          </button>
          <button
            type="button"
            @click="handleGerar"
            :disabled="!calculo || generating"
            class="px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50"
          >
            {{ generating ? 'Gerando...' : 'Gerar Custos' }}
          </button>
        </div>
      </div>
    </template>
  </IModal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ExclamationTriangleIcon } from '@heroicons/vue/24/outline'
import IModal from './IModal/IModal.vue'

interface CalculoResultado {
  fob_brl: number
  frete_brl: number
  seguro_brl: number
  base_calculo: number
  ii: number
  ipi: number
  pis_cofins: number
  icms: number
  total_impostos: number
  custo_total: number
}

interface Props {
  modelValue: boolean
  processoId: number
  valorFobInicial?: number | null
  taxaCambioInicial?: number | null
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'generated'): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const calculating = ref(false)
const generating = ref(false)
const showAliquotas = ref(false)
const calculo = ref<CalculoResultado | null>(null)

// Form
const form = ref({
  fob: props.valorFobInicial || 0,
  frete: 0,
  seguro: 0,
  taxaCambio: props.taxaCambioInicial || 5.5
})

// Aliquotas (valores decimais)
const aliquotas = ref({
  ii: 0.14,
  ipi: 0.10,
  pisCofins: 0.0965,
  icms: 0.18
})

// Watch para atualizar valores iniciais
watch(() => [props.valorFobInicial, props.taxaCambioInicial], ([fob, taxa]) => {
  if (fob) form.value.fob = fob
  if (taxa) form.value.taxaCambio = taxa
}, { immediate: true })

const canCalculate = computed(() => {
  return form.value.fob > 0 && form.value.taxaCambio > 0
})

function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function handleInputChange() {
  // Limpa calculo ao mudar inputs
  calculo.value = null
}

function handleClose() {
  isOpen.value = false
  calculo.value = null
}

async function handleCalcular() {
  if (!canCalculate.value) return

  calculating.value = true
  calculo.value = null

  try {
    const response = await fetch(`/processos_importacao/${props.processoId}/custos_previstos/calcular_impostos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
      },
      body: JSON.stringify({
        fob: form.value.fob,
        frete: form.value.frete,
        seguro: form.value.seguro,
        taxa_cambio: form.value.taxaCambio,
        aliquotas: {
          ii: aliquotas.value.ii,
          ipi: aliquotas.value.ipi,
          pis_cofins: aliquotas.value.pisCofins,
          icms: aliquotas.value.icms
        }
      })
    })

    const result = await response.json()

    if (result.success) {
      calculo.value = result.calculo
    } else {
      alert(result.message || 'Erro ao calcular')
    }
  } catch (err) {
    console.error('Erro ao calcular impostos:', err)
    alert('Erro ao calcular impostos')
  } finally {
    calculating.value = false
  }
}

async function handleGerar() {
  if (!calculo.value) return

  generating.value = true

  try {
    const response = await fetch(`/processos_importacao/${props.processoId}/custos_previstos/gerar_impostos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
      },
      body: JSON.stringify({
        fob: form.value.fob,
        frete: form.value.frete,
        seguro: form.value.seguro,
        taxa_cambio: form.value.taxaCambio,
        aliquotas: {
          ii: aliquotas.value.ii,
          ipi: aliquotas.value.ipi,
          pis_cofins: aliquotas.value.pisCofins,
          icms: aliquotas.value.icms
        }
      })
    })

    const result = await response.json()

    if (result.success) {
      emit('generated')
      handleClose()
    } else {
      alert(result.message || 'Erro ao gerar impostos')
    }
  } catch (err) {
    console.error('Erro ao gerar impostos:', err)
    alert('Erro ao gerar impostos')
  } finally {
    generating.value = false
  }
}
</script>
