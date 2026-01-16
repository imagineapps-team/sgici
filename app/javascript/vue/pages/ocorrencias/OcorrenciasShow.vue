<template>
  <Head :title="`Ocorrencia - ${ocorrencia.titulo}`" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <div class="flex items-center gap-3">
            <h1 class="text-2xl font-bold text-gray-900">{{ ocorrencia.titulo }}</h1>
            <span
              :class="[
                'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                statusClass(ocorrencia.status)
              ]"
            >
              {{ ocorrencia.statusLabel }}
            </span>
            <span
              :class="[
                'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                gravidadeClass(ocorrencia.gravidade)
              ]"
            >
              {{ ocorrencia.gravidadeLabel }}
            </span>
          </div>
          <p class="mt-1 text-sm text-gray-500">
            Processo:
            <Link :href="`/processos_importacao/${ocorrencia.processo.id}`" class="text-brand-primary hover:underline">
              {{ ocorrencia.processo.numero }}
            </Link>
          </p>
        </div>
        <div class="flex items-center gap-3">
          <!-- Acoes de transicao -->
          <button
            v-if="podeIniciarAnalise"
            @click="handleIniciarAnalise"
            :disabled="loading"
            class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            Iniciar Analise
          </button>
          <button
            v-if="podeResolver"
            @click="openResolverModal = true"
            :disabled="loading"
            class="px-4 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
          >
            Resolver
          </button>
          <button
            v-if="podeCancelar"
            @click="openCancelarModal = true"
            :disabled="loading"
            class="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
          >
            Cancelar
          </button>
          <Link
            v-if="podeEditar"
            :href="`/ocorrencias/${ocorrencia.id}/edit`"
            class="px-4 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Editar
          </Link>
          <Link href="/ocorrencias" class="text-brand-primary hover:underline">
            &larr; Voltar
          </Link>
        </div>
      </div>

      <!-- Grid de informacoes -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Coluna Principal -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Descricao -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Descricao</h3>
            <p class="text-gray-700 whitespace-pre-wrap">{{ ocorrencia.descricao }}</p>
          </div>

          <!-- Resolucao (se houver) -->
          <div v-if="ocorrencia.resolucao" class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Resolucao</h3>
            <p class="text-gray-700 whitespace-pre-wrap">{{ ocorrencia.resolucao }}</p>
            <p v-if="ocorrencia.dataResolucao" class="mt-4 text-sm text-gray-500">
              Resolvida em: {{ formatDate(ocorrencia.dataResolucao) }}
              <span v-if="ocorrencia.tempoResolucao"> ({{ ocorrencia.tempoResolucao }} dias)</span>
            </p>
          </div>
        </div>

        <!-- Coluna Lateral -->
        <div class="space-y-6">
          <!-- Detalhes -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Detalhes</h3>
            <dl class="space-y-4">
              <div>
                <dt class="text-sm text-gray-500">Tipo</dt>
                <dd class="text-sm font-medium text-gray-900">{{ ocorrencia.tipoLabel }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Data da Ocorrencia</dt>
                <dd class="text-sm font-medium text-gray-900">{{ formatDate(ocorrencia.dataOcorrencia) }}</dd>
              </div>
              <div v-if="ocorrencia.diasAberto !== null">
                <dt class="text-sm text-gray-500">Dias em Aberto</dt>
                <dd :class="['text-sm font-medium', diasAbertoClass(ocorrencia.diasAberto)]">
                  {{ ocorrencia.diasAberto }} dias
                </dd>
              </div>
              <div v-if="ocorrencia.impactoFinanceiro">
                <dt class="text-sm text-gray-500">Impacto Financeiro</dt>
                <dd class="text-sm font-medium text-red-600">{{ formatMoney(ocorrencia.impactoFinanceiro) }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Criado por</dt>
                <dd class="text-sm font-medium text-gray-900">{{ ocorrencia.criadoPor.nome }}</dd>
              </div>
              <div v-if="ocorrencia.responsavel">
                <dt class="text-sm text-gray-500">Responsavel</dt>
                <dd class="text-sm font-medium text-gray-900">{{ ocorrencia.responsavel.nome }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Registrado em</dt>
                <dd class="text-sm font-medium text-gray-900">{{ formatDateTime(ocorrencia.createdAt) }}</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>

      <!-- Anexos -->
      <div class="bg-white rounded-lg shadow p-6">
        <AnexosManager
          :base-url="`/ocorrencias/${ocorrencia.id}/anexos`"
          :readonly="!podeEditar"
        />
      </div>
    </div>

    <!-- Modal Resolver -->
    <IModal v-model="openResolverModal" title="Resolver Ocorrencia" size="md">
      <div class="space-y-4">
        <p class="text-sm text-gray-500">Descreva como a ocorrencia foi resolvida:</p>
        <textarea
          v-model="resolucaoTexto"
          rows="4"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-transparent resize-none"
          placeholder="Descreva a resolucao..."
        ></textarea>
      </div>
      <template #footer>
        <button
          @click="openResolverModal = false"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
        >
          Cancelar
        </button>
        <button
          @click="handleResolver"
          :disabled="loading || !resolucaoTexto.trim()"
          class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
        >
          Resolver
        </button>
      </template>
    </IModal>

    <!-- Modal Cancelar -->
    <IModal v-model="openCancelarModal" title="Cancelar Ocorrencia" size="md">
      <div class="space-y-4">
        <p class="text-sm text-gray-500">Informe o motivo do cancelamento:</p>
        <textarea
          v-model="motivoCancelamento"
          rows="3"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-transparent resize-none"
          placeholder="Motivo do cancelamento..."
        ></textarea>
      </div>
      <template #footer>
        <button
          @click="openCancelarModal = false"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
        >
          Voltar
        </button>
        <button
          @click="handleCancelar"
          :disabled="loading"
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
        >
          Confirmar Cancelamento
        </button>
      </template>
    </IModal>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import IModal from '../../components/IModal/IModal.vue'
import { AnexosManager } from '../../components/AnexosManager'
import type { UserInfo } from '../../types/navigation'
import { formatDate, formatDateTime, formatMoney } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'

interface OcorrenciaDetail {
  id: number
  titulo: string
  tipo: string
  tipoLabel: string
  gravidade: string
  gravidadeLabel: string
  status: string
  statusLabel: string
  processo: { id: number; numero: string }
  criadoPor: { id: number; nome: string }
  responsavel: { id: number; nome: string } | null
  dataOcorrencia: string
  impactoFinanceiro: number | null
  diasAberto: number | null
  descricao: string
  resolucao: string | null
  dataResolucao: string | null
  tempoResolucao: number | null
  createdAt: string
}

interface Props {
  usuario: UserInfo
  ocorrencia: OcorrenciaDetail
  podeEditar: boolean
  podeIniciarAnalise: boolean
  podeResolver: boolean
  podeCancelar: boolean
}

const props = defineProps<Props>()
const { success, error: showError } = useNotifications()

const loading = ref(false)
const openResolverModal = ref(false)
const openCancelarModal = ref(false)
const resolucaoTexto = ref('')
const motivoCancelamento = ref('')

function statusClass(status: string): string {
  switch (status) {
    case 'aberta': return 'bg-yellow-100 text-yellow-800'
    case 'em_analise': return 'bg-blue-100 text-blue-800'
    case 'resolvida': return 'bg-green-100 text-green-800'
    case 'cancelada': return 'bg-gray-100 text-gray-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function gravidadeClass(gravidade: string): string {
  switch (gravidade) {
    case 'baixa': return 'bg-green-100 text-green-800'
    case 'media': return 'bg-yellow-100 text-yellow-800'
    case 'alta': return 'bg-orange-100 text-orange-800'
    case 'critica': return 'bg-red-100 text-red-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function diasAbertoClass(dias: number): string {
  if (dias > 14) return 'text-red-600'
  if (dias > 7) return 'text-orange-600'
  if (dias > 3) return 'text-yellow-600'
  return 'text-green-600'
}

async function handleIniciarAnalise() {
  loading.value = true
  try {
    const response = await api.post(`/ocorrencias/${props.ocorrencia.id}/iniciar_analise`)
    if (response.data.success) {
      success(response.data.message)
      router.reload()
    }
  } catch (err) {
    showError('Erro ao iniciar analise')
  } finally {
    loading.value = false
  }
}

async function handleResolver() {
  loading.value = true
  try {
    const response = await api.post(`/ocorrencias/${props.ocorrencia.id}/resolver`, {
      resolucao: resolucaoTexto.value
    })
    if (response.data.success) {
      success(response.data.message)
      openResolverModal.value = false
      router.reload()
    }
  } catch (err) {
    showError('Erro ao resolver ocorrencia')
  } finally {
    loading.value = false
  }
}

async function handleCancelar() {
  loading.value = true
  try {
    const response = await api.post(`/ocorrencias/${props.ocorrencia.id}/cancelar`, {
      motivo: motivoCancelamento.value
    })
    if (response.data.success) {
      success(response.data.message)
      openCancelarModal.value = false
      router.reload()
    }
  } catch (err) {
    showError('Erro ao cancelar ocorrencia')
  } finally {
    loading.value = false
  }
}
</script>
