<template>
  <IModal
    v-model="isOpen"
    :title="isEditing ? 'Editar Custo Real' : 'Novo Custo Real'"
    size="xl"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- Vincular a Custo Previsto -->
      <div v-if="custosPrevistos.length > 0">
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Vincular a Custo Previsto
        </label>
        <select
          v-model="form.custoPrevistoId"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          @change="handleCustoPrevistoChange"
        >
          <option :value="null">Sem vinculacao</option>
          <option v-for="cp in custosPrevistos" :key="cp.id" :value="cp.id">
            {{ cp.label }}
          </option>
        </select>
        <p class="text-xs text-gray-500 mt-1">Ao vincular, o desvio sera calculado automaticamente</p>
      </div>

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

      <!-- Prestador -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Prestador de Servico
        </label>
        <select
          v-model="form.prestadorId"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
        >
          <option :value="null">Nenhum</option>
          <option v-for="p in prestadores" :key="p.id" :value="p.id">
            {{ p.nome }} ({{ p.tipo }})
          </option>
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

      <!-- Documento -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Numero do Documento
          </label>
          <input
            v-model="form.numeroDocumento"
            type="text"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
            placeholder="NF, Fatura, etc."
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Tipo do Documento
          </label>
          <select
            v-model="form.tipoDocumento"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          >
            <option value="">Selecione...</option>
            <option value="nf">Nota Fiscal</option>
            <option value="fatura">Fatura</option>
            <option value="boleto">Boleto</option>
            <option value="recibo">Recibo</option>
            <option value="outros">Outros</option>
          </select>
        </div>
      </div>

      <!-- Datas -->
      <div class="grid grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Data Lancamento
          </label>
          <input
            v-model="form.dataLancamento"
            type="date"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Data Vencimento
          </label>
          <input
            v-model="form.dataVencimento"
            type="date"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Data Pagamento
          </label>
          <input
            v-model="form.dataPagamento"
            type="date"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          />
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

      <!-- Desvio (se vinculado a previsto) -->
      <div v-if="custoPrevistoSelecionado" class="bg-blue-50 rounded-lg p-4">
        <h4 class="text-sm font-medium text-blue-900 mb-2">Comparativo com Previsto</h4>
        <div class="grid grid-cols-3 gap-4 text-sm">
          <div>
            <span class="text-blue-600">Previsto:</span>
            <span class="font-medium ml-1">R$ {{ formatNumber(custoPrevistoSelecionado.valorBrl) }}</span>
          </div>
          <div>
            <span class="text-blue-600">Real:</span>
            <span class="font-medium ml-1">R$ {{ formatNumber(valorBrlCalculado) }}</span>
          </div>
          <div>
            <span class="text-blue-600">Desvio:</span>
            <span :class="['font-medium ml-1', desvioClass]">
              {{ desvioValor > 0 ? '+' : '' }}{{ formatNumber(desvioValor) }} ({{ desvioPercentual > 0 ? '+' : '' }}{{ desvioPercentual.toFixed(1) }}%)
            </span>
          </div>
        </div>
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
import type { CustoReal } from '../types/importacao'

interface CategoriaOption {
  id: number
  nome: string
  codigo: string | null
  grupo: string | null
  grupoNome: string | null
  obrigatorio: boolean
}

interface PrestadorOption {
  id: number
  nome: string
  tipo: string
}

interface CustoPrevistoOption {
  id: number
  categoriaId: number
  categoria: string
  valorBrl: number
  label: string
}

interface Props {
  modelValue: boolean
  processoId: number
  custo?: CustoReal | null
  categorias: CategoriaOption[]
  prestadores: PrestadorOption[]
  custosPrevistos: CustoPrevistoOption[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved', custo: CustoReal): void
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
  prestadorId: null as number | null,
  custoPrevistoId: null as number | null,
  valor: null as number | null,
  moeda: 'BRL',
  taxaCambio: null as number | null,
  descricao: '',
  dataLancamento: new Date().toISOString().split('T')[0],
  dataVencimento: '',
  dataPagamento: '',
  numeroDocumento: '',
  tipoDocumento: ''
})

// Watch for custo changes to populate form
watch(() => props.custo, (newCusto) => {
  if (newCusto) {
    form.value = {
      categoriaId: newCusto.categoriaId || newCusto.categoria?.id || null,
      prestadorId: newCusto.prestadorId || newCusto.prestador?.id || null,
      custoPrevistoId: newCusto.custoPrevistoId || null,
      valor: newCusto.valor,
      moeda: newCusto.moeda || 'BRL',
      taxaCambio: newCusto.taxaCambio,
      descricao: newCusto.descricao || '',
      dataLancamento: newCusto.dataLancamento?.split('T')[0] || new Date().toISOString().split('T')[0],
      dataVencimento: newCusto.dataVencimento?.split('T')[0] || '',
      dataPagamento: newCusto.dataPagamento?.split('T')[0] || '',
      numeroDocumento: newCusto.numeroDocumento || '',
      tipoDocumento: newCusto.tipoDocumento || ''
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

// Custo previsto selecionado
const custoPrevistoSelecionado = computed(() => {
  if (!form.value.custoPrevistoId) return null
  return props.custosPrevistos.find(cp => cp.id === form.value.custoPrevistoId) || null
})

// Valor BRL calculado
const valorBrlCalculado = computed(() => {
  if (form.value.moeda === 'BRL') {
    return form.value.valor || 0
  }
  if (!form.value.valor || !form.value.taxaCambio) return 0
  return form.value.valor * form.value.taxaCambio
})

// Desvio calculado
const desvioValor = computed(() => {
  if (!custoPrevistoSelecionado.value) return 0
  return valorBrlCalculado.value - custoPrevistoSelecionado.value.valorBrl
})

const desvioPercentual = computed(() => {
  if (!custoPrevistoSelecionado.value || !custoPrevistoSelecionado.value.valorBrl) return 0
  return (desvioValor.value / custoPrevistoSelecionado.value.valorBrl) * 100
})

const desvioClass = computed(() => {
  if (desvioPercentual.value > 10) return 'text-red-600'
  if (desvioPercentual.value > 5) return 'text-yellow-600'
  if (desvioPercentual.value < -5) return 'text-green-600'
  return 'text-gray-600'
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
    prestadorId: null,
    custoPrevistoId: null,
    valor: null,
    moeda: 'BRL',
    taxaCambio: null,
    descricao: '',
    dataLancamento: new Date().toISOString().split('T')[0],
    dataVencimento: '',
    dataPagamento: '',
    numeroDocumento: '',
    tipoDocumento: ''
  }
}

function handleClose() {
  isOpen.value = false
  resetForm()
}

function handleCustoPrevistoChange() {
  if (custoPrevistoSelecionado.value) {
    form.value.categoriaId = custoPrevistoSelecionado.value.categoriaId
  }
}

async function handleSubmit() {
  if (!isFormValid.value) return

  submitting.value = true

  try {
    const data = {
      custo_real: {
        categoria_custo_id: form.value.categoriaId,
        prestador_servico_id: form.value.prestadorId,
        custo_previsto_id: form.value.custoPrevistoId,
        valor: form.value.valor,
        moeda: form.value.moeda,
        taxa_cambio: form.value.moeda === 'BRL' ? 1 : form.value.taxaCambio,
        descricao: form.value.descricao || null,
        data_lancamento: form.value.dataLancamento || null,
        data_vencimento: form.value.dataVencimento || null,
        data_pagamento: form.value.dataPagamento || null,
        numero_documento: form.value.numeroDocumento || null,
        tipo_documento: form.value.tipoDocumento || null
      }
    }

    const url = isEditing.value
      ? `/processos_importacao/${props.processoId}/custos_reais/${props.custo!.id}/ajax_update`
      : `/processos_importacao/${props.processoId}/custos_reais/ajax_create`

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
    alert('Erro ao salvar custo real')
  } finally {
    submitting.value = false
  }
}
</script>
