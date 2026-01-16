<template>
  <IModal
    v-model="isOpen"
    :title="isEditing ? 'Editar Custo Previsto' : 'Novo Custo Previsto'"
    size="lg"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- Categoria -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Categoria <span class="text-red-500">*</span>
        </label>
        <select
          v-model="form.categoriaId"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          required
        >
          <option value="">Selecione uma categoria</option>
          <optgroup v-for="(cats, grupo) in categoriasPorGrupo" :key="grupo" :label="grupoLabel(grupo)">
            <option v-for="cat in cats" :key="cat.id" :value="cat.id">
              {{ cat.nome }}
            </option>
          </optgroup>
        </select>
      </div>

      <!-- Valor e Moeda -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Valor <span class="text-red-500">*</span>
          </label>
          <input
            v-model="form.valor"
            type="number"
            step="0.01"
            min="0"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
            placeholder="0.00"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Moeda
          </label>
          <select
            v-model="form.moeda"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          >
            <option value="BRL">BRL - Real</option>
            <option value="USD">USD - Dolar</option>
            <option value="EUR">EUR - Euro</option>
            <option value="CNY">CNY - Yuan</option>
          </select>
        </div>
      </div>

      <!-- Taxa de Cambio (se moeda estrangeira) -->
      <div v-if="form.moeda !== 'BRL'" class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Taxa de Cambio <span class="text-red-500">*</span>
          </label>
          <input
            v-model="form.taxaCambio"
            type="number"
            step="0.0001"
            min="0"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
            placeholder="5.5000"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Valor em BRL
          </label>
          <div class="text-lg font-semibold text-gray-900 py-2">
            R$ {{ formatNumber(valorBrlCalculado) }}
          </div>
        </div>
      </div>

      <!-- Descricao -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Descricao
        </label>
        <input
          v-model="form.descricao"
          type="text"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          placeholder="Descricao opcional"
        />
      </div>

      <!-- Data Previsao -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Data de Previsao
        </label>
        <input
          v-model="form.dataPrevisao"
          type="date"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
        />
      </div>
    </form>

    <template #footer>
      <div class="flex justify-end gap-3">
        <button
          type="button"
          @click="handleClose"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
        >
          Cancelar
        </button>
        <button
          type="button"
          @click="handleSubmit"
          :disabled="submitting || !isFormValid"
          class="px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50"
        >
          {{ submitting ? 'Salvando...' : (isEditing ? 'Atualizar' : 'Adicionar') }}
        </button>
      </div>
    </template>
  </IModal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import IModal from './IModal/IModal.vue'
import type { CustoPrevisto } from '../types/importacao'

interface CategoriaOption {
  id: number
  nome: string
  codigo: string | null
  grupo: string | null
  grupoNome: string | null
  obrigatorio: boolean
}

interface Props {
  modelValue: boolean
  processoId: number
  custo?: CustoPrevisto | null
  categorias: CategoriaOption[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved', custo: CustoPrevisto): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const isEditing = computed(() => !!props.custo?.id)
const submitting = ref(false)

// Form state
const form = ref({
  categoriaId: null as number | null,
  valor: null as number | null,
  moeda: 'BRL',
  taxaCambio: null as number | null,
  descricao: '',
  dataPrevisao: ''
})

// Watch for custo changes to populate form
watch(() => props.custo, (newCusto) => {
  if (newCusto) {
    form.value = {
      categoriaId: newCusto.categoriaId || newCusto.categoria?.id || null,
      valor: newCusto.valor,
      moeda: newCusto.moeda || 'BRL',
      taxaCambio: newCusto.taxaCambio,
      descricao: newCusto.descricao || '',
      dataPrevisao: newCusto.dataPrevisao?.split('T')[0] || ''
    }
  } else {
    resetForm()
  }
}, { immediate: true })

// Watch for modal open to reset form when opening new
watch(isOpen, (open) => {
  if (open && !props.custo) {
    resetForm()
  }
})

// Categorias agrupadas
const categoriasPorGrupo = computed(() => {
  const grupos: Record<string, CategoriaOption[]> = {}
  props.categorias.forEach(cat => {
    const grupo = cat.grupo || 'outros'
    if (!grupos[grupo]) grupos[grupo] = []
    grupos[grupo].push(cat)
  })
  return grupos
})

// Labels de grupos
const grupoLabels: Record<string, string> = {
  fob: 'Valor do Produto',
  frete: 'Frete e Transporte',
  seguro: 'Seguros',
  impostos: 'Impostos e Taxas',
  armazenagem: 'Armazenagem',
  servicos: 'Servicos',
  transporte: 'Transporte Nacional',
  outros: 'Outros'
}

function grupoLabel(grupo: string): string {
  return grupoLabels[grupo] || grupo
}

// Valor BRL calculado
const valorBrlCalculado = computed(() => {
  if (form.value.moeda === 'BRL') {
    return form.value.valor || 0
  }
  if (!form.value.valor || !form.value.taxaCambio) return 0
  return form.value.valor * form.value.taxaCambio
})

// Form validation
const isFormValid = computed(() => {
  if (!form.value.categoriaId || !form.value.valor) return false
  if (form.value.moeda !== 'BRL' && !form.value.taxaCambio) return false
  return true
})

function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function resetForm() {
  form.value = {
    categoriaId: null,
    valor: null,
    moeda: 'BRL',
    taxaCambio: null,
    descricao: '',
    dataPrevisao: ''
  }
}

function handleClose() {
  isOpen.value = false
  resetForm()
}

async function handleSubmit() {
  if (!isFormValid.value) return

  submitting.value = true

  try {
    const data = {
      custo_previsto: {
        categoria_custo_id: form.value.categoriaId,
        valor: form.value.valor,
        moeda: form.value.moeda,
        taxa_cambio: form.value.moeda === 'BRL' ? 1 : form.value.taxaCambio,
        descricao: form.value.descricao || null,
        data_previsao: form.value.dataPrevisao || null
      }
    }

    const url = isEditing.value
      ? `/processos_importacao/${props.processoId}/custos_previstos/${props.custo!.id}/ajax_update`
      : `/processos_importacao/${props.processoId}/custos_previstos/ajax_create`

    const method = isEditing.value ? 'PATCH' : 'POST'

    const response = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
      },
      body: JSON.stringify(data)
    })

    const result = await response.json()

    if (result.success) {
      emit('saved', result.custo)
      handleClose()
    } else {
      alert(result.message || 'Erro ao salvar')
    }
  } catch (err) {
    console.error('Erro ao salvar custo:', err)
    alert('Erro ao salvar custo previsto')
  } finally {
    submitting.value = false
  }
}
</script>
