<template>
  <Head :title="`Fornecedor - ${fornecedor.nome}`" />

  <AppLayout :usuario="$page.props.usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <div class="flex items-center gap-3">
            <h1 class="text-2xl font-bold text-gray-900">{{ fornecedor.nome }}</h1>
            <span
              :class="[
                'px-2.5 py-0.5 rounded-full text-xs font-medium',
                fornecedor.ativo ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
              ]"
            >
              {{ fornecedor.ativoLabel }}
            </span>
          </div>
          <p v-if="fornecedor.nomeFantasia" class="mt-1 text-sm text-gray-500">
            {{ fornecedor.nomeFantasia }}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <Link
            :href="`/fornecedores/${fornecedor.id}/edit`"
            class="inline-flex items-center gap-2 px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
          >
            <PencilIcon class="h-4 w-4" />
            Editar
          </Link>
          <Link href="/fornecedores" class="text-brand-primary hover:underline">
            &larr; Voltar
          </Link>
        </div>
      </div>

      <!-- KPIs -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Total Processos</p>
          <p class="text-2xl font-bold text-gray-900">{{ estatisticas.totalProcessos }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Processos Ativos</p>
          <p class="text-2xl font-bold text-blue-600">{{ estatisticas.processosAtivos }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Valor Total FOB</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(estatisticas.valorTotalFob) }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Score</p>
          <p class="text-2xl font-bold" :class="scoreClass(Number(fornecedor.score || 0))">
            {{ fornecedor.score ? Number(fornecedor.score).toFixed(1) : '-' }}
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Informacoes do Fornecedor -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Dados Gerais -->
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Dados Gerais</h2>
            </div>
            <div class="px-6 py-4">
              <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <dt class="text-sm font-medium text-gray-500">CNPJ</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ fornecedor.cnpj || '-' }}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Pais</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ fornecedor.pais || '-' }}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Cidade/Estado</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {{ [fornecedor.cidade, fornecedor.estado].filter(Boolean).join(' / ') || '-' }}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Endereco</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ fornecedor.endereco || '-' }}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Email</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    <a v-if="fornecedor.email" :href="`mailto:${fornecedor.email}`" class="text-brand-primary hover:underline">
                      {{ fornecedor.email }}
                    </a>
                    <span v-else>-</span>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Telefone</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ fornecedor.telefone || '-' }}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Website</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    <a v-if="fornecedor.website" :href="fornecedor.website" target="_blank" class="text-brand-primary hover:underline">
                      {{ fornecedor.website }}
                    </a>
                    <span v-else>-</span>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Moeda Padrao</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ fornecedor.moedaPadrao || 'USD' }}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Contatos -->
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Contatos</h2>
            </div>
            <div class="px-6 py-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Comercial -->
                <div>
                  <h3 class="text-sm font-medium text-gray-700 mb-2">Comercial</h3>
                  <dl class="space-y-2">
                    <div>
                      <dt class="text-xs text-gray-500">Nome</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoComercialNome || '-' }}</dd>
                    </div>
                    <div>
                      <dt class="text-xs text-gray-500">Email</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoComercialEmail || '-' }}</dd>
                    </div>
                    <div>
                      <dt class="text-xs text-gray-500">Telefone</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoComercialTelefone || '-' }}</dd>
                    </div>
                  </dl>
                </div>

                <!-- Operacional -->
                <div>
                  <h3 class="text-sm font-medium text-gray-700 mb-2">Operacional</h3>
                  <dl class="space-y-2">
                    <div>
                      <dt class="text-xs text-gray-500">Nome</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoOperacionalNome || '-' }}</dd>
                    </div>
                    <div>
                      <dt class="text-xs text-gray-500">Email</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoOperacionalEmail || '-' }}</dd>
                    </div>
                    <div>
                      <dt class="text-xs text-gray-500">Telefone</dt>
                      <dd class="text-sm text-gray-900">{{ fornecedor.contatoOperacionalTelefone || '-' }}</dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <!-- Processos Recentes -->
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h2 class="text-lg font-medium text-gray-900">Processos Recentes</h2>
              <Link
                :href="`/processos_importacao?fornecedor_id=${fornecedor.id}`"
                class="text-sm text-brand-primary hover:underline"
              >
                Ver todos
              </Link>
            </div>
            <div v-if="processosRecentes.length > 0" class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Numero</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor FOB</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Chegada Prev.</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="processo in processosRecentes" :key="processo.id" class="hover:bg-gray-50">
                    <td class="px-4 py-3 whitespace-nowrap">
                      <Link :href="`/processos_importacao/${processo.id}`" class="text-brand-primary hover:underline font-medium">
                        {{ processo.numero }}
                      </Link>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                      <span :class="['px-2 py-1 text-xs rounded-full font-medium', statusClass(processo.status)]">
                        {{ processo.statusLabel }}
                      </span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-right">
                      {{ processo.moeda }} {{ formatNumber(processo.valorFob) }}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                      {{ processo.dataChegadaPrevista ? formatDate(processo.dataChegadaPrevista) : '-' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div v-else class="px-6 py-8 text-center text-gray-500">
              Nenhum processo encontrado para este fornecedor.
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Processos por Status -->
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Por Status</h2>
            </div>
            <div class="px-6 py-4">
              <div v-if="estatisticas.processosPorStatus.length > 0" class="space-y-3">
                <div
                  v-for="item in estatisticas.processosPorStatus"
                  :key="item.status"
                  class="flex items-center justify-between"
                >
                  <span :class="['px-2 py-1 text-xs rounded-full font-medium', statusClass(item.status)]">
                    {{ item.label }}
                  </span>
                  <span class="text-sm font-medium text-gray-900">{{ item.total }}</span>
                </div>
              </div>
              <p v-else class="text-sm text-gray-500">Sem processos</p>
            </div>
          </div>

          <!-- Indicadores -->
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Indicadores</h2>
            </div>
            <div class="px-6 py-4 space-y-4">
              <div>
                <p class="text-sm text-gray-500">Lead Time Medio</p>
                <p class="text-lg font-medium text-gray-900">
                  {{ fornecedor.leadTimeMedio ? `${Number(fornecedor.leadTimeMedio).toFixed(1)} dias` : '-' }}
                </p>
              </div>
              <div>
                <p class="text-sm text-gray-500">Desvio Medio</p>
                <p class="text-lg font-medium" :class="desvioClass(Number(fornecedor.desvioMedio || 0))">
                  {{ fornecedor.desvioMedio ? `${Number(fornecedor.desvioMedio) > 0 ? '+' : ''}${Number(fornecedor.desvioMedio).toFixed(1)}%` : '-' }}
                </p>
              </div>
              <div>
                <p class="text-sm text-gray-500">Custo Previsto Total</p>
                <p class="text-lg font-medium text-gray-900">
                  {{ formatMoney(estatisticas.custoPrevistoTotal) }}
                </p>
              </div>
              <div>
                <p class="text-sm text-gray-500">Custo Real Total</p>
                <p class="text-lg font-medium text-gray-900">
                  {{ formatMoney(estatisticas.custoRealTotal) }}
                </p>
              </div>
            </div>
          </div>

          <!-- Observacoes -->
          <div v-if="fornecedor.observacoes" class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Observacoes</h2>
            </div>
            <div class="px-6 py-4">
              <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ fornecedor.observacoes }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import { PencilIcon } from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { formatMoney, formatDate } from '../../utils'

interface Fornecedor {
  id: number
  nome: string
  nomeFantasia: string | null
  cnpj: string | null
  email: string | null
  telefone: string | null
  website: string | null
  pais: string | null
  estado: string | null
  cidade: string | null
  endereco: string | null
  cep: string | null
  contatoComercialNome: string | null
  contatoComercialEmail: string | null
  contatoComercialTelefone: string | null
  contatoOperacionalNome: string | null
  contatoOperacionalEmail: string | null
  contatoOperacionalTelefone: string | null
  observacoes: string | null
  moedaPadrao: string | null
  prazoPagamentoDias: number | null
  ativo: boolean
  ativoLabel: string
  totalProcessos: number
  processosAtivos: number
  valorTotalFob: number
  score: number | null
  leadTimeMedio: number | null
  desvioMedio: number | null
}

interface ProcessoResumo {
  id: number
  numero: string
  status: string
  statusLabel: string
  modal: string
  valorFob: number
  moeda: string
  dataChegadaPrevista: string | null
}

interface StatusItem {
  status: string
  label: string
  total: number
}

interface Estatisticas {
  totalProcessos: number
  processosAtivos: number
  processosPorStatus: StatusItem[]
  valorTotalFob: number
  custoPrevistoTotal: number
  custoRealTotal: number
}

interface Props {
  fornecedor: Fornecedor
  processosRecentes: ProcessoResumo[]
  estatisticas: Estatisticas
}

defineProps<Props>()

function formatNumber(value: number | null): string {
  if (value == null) return '-'
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function statusClass(status: string): string {
  switch (status) {
    case 'planejado':
      return 'bg-gray-100 text-gray-800'
    case 'aprovado':
      return 'bg-blue-100 text-blue-800'
    case 'em_transito':
      return 'bg-yellow-100 text-yellow-800'
    case 'desembaracado':
      return 'bg-purple-100 text-purple-800'
    case 'finalizado':
      return 'bg-green-100 text-green-800'
    case 'cancelado':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

function scoreClass(score: number): string {
  if (score >= 8) return 'text-green-600'
  if (score >= 6) return 'text-blue-600'
  if (score >= 4) return 'text-yellow-600'
  return 'text-red-600'
}

function desvioClass(desvio: number): string {
  if (desvio > 10) return 'text-red-600'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}
</script>
