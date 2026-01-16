<template>
  <Head :title="isEditing ? `Editar ${processo?.numero}` : 'Novo Processo'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-4xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">
            {{ isEditing ? `Editar Processo ${processo?.numero}` : 'Novo Processo de Importacao' }}
          </h1>
          <p class="mt-1 text-sm text-gray-500">
            {{ isEditing ? 'Atualize os dados do processo de importacao.' : 'Preencha os dados para criar um novo processo.' }}
          </p>
        </div>
        <Link
          href="/processos_importacao"
          class="inline-flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
        >
          <ArrowLeftIcon class="h-5 w-5" />
          Voltar
        </Link>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <!-- Dados Basicos -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Dados Basicos</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <ISelect
              v-model="form.fornecedorId"
              label="Fornecedor"
              :options="fornecedoresOptions"
              placeholder="Selecione o fornecedor"
              searchable
              required
              :error="errors.fornecedorId"
            />

            <ISelect
              v-model="form.responsavelId"
              label="Responsavel"
              :options="responsaveisOptions"
              placeholder="Selecione o responsavel"
              searchable
              :error="errors.responsavelId"
            />

            <ISelect
              v-model="form.paisOrigem"
              label="Pais de Origem"
              :options="paisesOptions"
              placeholder="Selecione o pais"
              searchable
              required
              :error="errors.paisOrigem"
            />

            <ISelect
              v-model="form.modal"
              label="Modal de Transporte"
              :options="modalOptions"
              placeholder="Selecione o modal"
              required
              :error="errors.modal"
            />

            <ISelect
              v-model="form.incoterm"
              label="Incoterm"
              :options="incotermOptions"
              placeholder="Selecione o incoterm"
              :error="errors.incoterm"
            />

            <ISelect
              v-model="form.moeda"
              label="Moeda"
              :options="moedaOptions"
              placeholder="Selecione a moeda"
              required
              :error="errors.moeda"
            />
          </div>
        </div>

        <!-- Valores -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Valores</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IInput
              v-model="form.valorFob"
              type="money"
              label="Valor FOB"
              placeholder="0,00"
              :error="errors.valorFob"
            />

            <IInput
              v-model="form.taxaCambio"
              type="number"
              label="Taxa de Cambio"
              placeholder="1.0000"
              :error="errors.taxaCambio"
            />
          </div>
        </div>

        <!-- Origem/Destino -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Origem e Destino</h2>

          <!-- Maritimo/Rodoviario -->
          <div v-if="form.modal !== 'aereo'" class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <IInput
              v-model="form.portoOrigem"
              label="Porto de Origem"
              placeholder="Ex: Shanghai"
              :error="errors.portoOrigem"
            />

            <IInput
              v-model="form.portoDestino"
              label="Porto de Destino"
              placeholder="Ex: Santos"
              :error="errors.portoDestino"
            />
          </div>

          <!-- Aereo -->
          <div v-if="form.modal === 'aereo' || form.modal === 'multimodal'" class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <IInput
              v-model="form.aeroportoOrigem"
              label="Aeroporto de Origem"
              placeholder="Ex: PVG"
              :error="errors.aeroportoOrigem"
            />

            <IInput
              v-model="form.aeroportoDestino"
              label="Aeroporto de Destino"
              placeholder="Ex: GRU"
              :error="errors.aeroportoDestino"
            />
          </div>

        </div>

        <!-- Documentos -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Documentos</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IInput
              v-model="form.numeroBl"
              label="Numero B/L"
              placeholder="Numero do conhecimento"
              :error="errors.numeroBl"
            />

            <IInput
              v-model="form.numeroContainer"
              label="Numero Container"
              placeholder="Ex: MSKU1234567"
              :error="errors.numeroContainer"
            />
          </div>
        </div>

        <!-- Datas -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Datas Previstas</h2>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <IInput
              v-model="form.dataEmbarquePrevista"
              type="date"
              label="Data Embarque Prevista"
              :error="errors.dataEmbarquePrevista"
            />

            <IInput
              v-model="form.dataChegadaPrevista"
              type="date"
              label="Data Chegada Prevista"
              :error="errors.dataChegadaPrevista"
            />

            <IInput
              v-model="form.dataEntregaPrevista"
              type="date"
              label="Data Entrega Prevista"
              :error="errors.dataEntregaPrevista"
            />
          </div>
        </div>

        <!-- Observacoes -->
        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Observacoes</h2>

          <textarea
            v-model="form.observacoes"
            rows="4"
            class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
            placeholder="Observacoes gerais sobre o processo..."
          ></textarea>
        </div>

        <!-- Actions -->
        <div class="flex items-center justify-end gap-4">
          <Link
            href="/processos_importacao"
            class="px-6 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancelar
          </Link>
          <button
            type="submit"
            :disabled="submitting"
            class="px-6 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ submitting ? 'Salvando...' : (isEditing ? 'Atualizar' : 'Criar Processo') }}
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import { ArrowLeftIcon } from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../types/importacao'
import { useNotifications } from '../../composables/useNotification'
import { parseMoney } from '../../utils'

interface Props {
  usuario: UserInfo
  processo: ProcessoFormType | null
  fornecedoresOptions: SelectOption[]
  responsaveisOptions: SelectOption[]
  prestadoresOptions: SelectOption[]
  categoriasOptions: SelectOption[]
  statusOptions: SelectOption[]
  modalOptions: SelectOption[]
  incotermOptions: SelectOption[]
  moedaOptions: SelectOption[]
  paisesOptions: SelectOption[]
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const isEditing = computed(() => !!props.processo?.id)
const submitting = ref(false)

// Form state
const form = reactive({
  id: props.processo?.id,
  fornecedorId: props.processo?.fornecedorId ?? null,
  responsavelId: props.processo?.responsavelId ?? null,
  paisOrigem: props.processo?.paisOrigem ?? '',
  modal: props.processo?.modal ?? 'maritimo',
  incoterm: props.processo?.incoterm ?? null,
  moeda: props.processo?.moeda ?? 'USD',
  valorFob: props.processo?.valorFob ?? null,
  taxaCambio: props.processo?.taxaCambio ?? null,
  portoOrigem: props.processo?.portoOrigem ?? null,
  portoDestino: props.processo?.portoDestino ?? null,
  aeroportoOrigem: props.processo?.aeroportoOrigem ?? null,
  aeroportoDestino: props.processo?.aeroportoDestino ?? null,
  numeroBl: props.processo?.numeroBl ?? null,
  numeroContainer: props.processo?.numeroContainer ?? null,
  dataEmbarquePrevista: props.processo?.dataEmbarquePrevista ?? null,
  dataChegadaPrevista: props.processo?.dataChegadaPrevista ?? null,
  dataEntregaPrevista: props.processo?.dataEntregaPrevista ?? null,
  observacoes: props.processo?.observacoes ?? null
})

// Validation errors
const errors = reactive<Record<string, string>>({})

function validate(): boolean {
  // Clear previous errors
  Object.keys(errors).forEach(key => delete errors[key])

  if (!form.fornecedorId) {
    errors.fornecedorId = 'Fornecedor e obrigatorio'
  }

  if (!form.paisOrigem) {
    errors.paisOrigem = 'Pais de origem e obrigatorio'
  }

  if (!form.modal) {
    errors.modal = 'Modal de transporte e obrigatorio'
  }

  if (!form.moeda) {
    errors.moeda = 'Moeda e obrigatoria'
  }

  return Object.keys(errors).length === 0
}

function handleSubmit() {
  if (!validate()) {
    showError('Preencha os campos obrigatorios')
    return
  }

  submitting.value = true

  // Prepare data - convert camelCase to snake_case for Rails
  const data = {
    processo_importacao: {
      fornecedor_id: form.fornecedorId,
      responsavel_id: form.responsavelId,
      pais_origem: form.paisOrigem,
      modal: form.modal,
      incoterm: form.incoterm,
      moeda: form.moeda,
      valor_fob: typeof form.valorFob === 'string' ? parseMoney(form.valorFob) : form.valorFob,
      taxa_cambio: form.taxaCambio,
      porto_origem: form.portoOrigem,
      porto_destino: form.portoDestino,
      aeroporto_origem: form.aeroportoOrigem,
      aeroporto_destino: form.aeroportoDestino,
      numero_bl: form.numeroBl,
      numero_container: form.numeroContainer,
      data_embarque_prevista: form.dataEmbarquePrevista,
      data_chegada_prevista: form.dataChegadaPrevista,
      data_entrega_prevista: form.dataEntregaPrevista,
      observacoes: form.observacoes
    }
  }

  if (isEditing.value) {
    router.put(`/processos_importacao/${form.id}`, data, {
      onFinish: () => { submitting.value = false }
    })
  } else {
    router.post('/processos_importacao', data, {
      onFinish: () => { submitting.value = false }
    })
  }
}
</script>
