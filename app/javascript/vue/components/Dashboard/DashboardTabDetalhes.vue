<script setup lang="ts">
import { ref, computed } from 'vue'
import type {
  EventoAtivo,
  ResumoParticipacao,
  TotalGeradoPorAcao,
  CalculoEconomiaEnergetica,
  ResumoPorAcao,
  ResumoDoacao,
  EconomiaGrupo,
  TotaisTotalGerado
} from '../../types/dashboard'
import type { MapMarker } from '../IMap/IMap.vue'
import type { DataTableColumn } from '../../types/datatable'
import type { TreeListItem } from '../ITreeList/ITreeList.vue'
import { IMap } from '../IMap'
import { ITreeList } from '../ITreeList'
import { DataTable } from '../DataTable'
import { formatNumber } from '../../utils'

interface Props {
  isLoading: boolean
  eventosAtivos: EventoAtivo[]
  eventosAtivosMarkers: MapMarker[]
  colunasEventosAtivos: DataTableColumn<EventoAtivo>[]
  resumoParticipacao: ResumoParticipacao | null
  totalGeradoPorAcao: TotalGeradoPorAcao[]
  economiaAgrupadaPorAcao: EconomiaGrupo[]
  totaisTotalGerado: TotaisTotalGerado | null
  resumoPorAcao: ResumoPorAcao[]
  resumoDoacoes: ResumoDoacao[]
  totalDoacoes: number
  colunasTotalGerado: DataTableColumn<TotalGeradoPorAcao>[]
  colunasResumoPorAcao: DataTableColumn<ResumoPorAcao>[]
  colunasDoacoes: DataTableColumn<ResumoDoacao>[]
}

const props = defineProps<Props>()

// Saudação baseada na hora
const saudacao = computed(() => {
  const hora = new Date().getHours()
  if (hora >= 0 && hora < 12) return 'Bom dia,'
  if (hora >= 12 && hora < 18) return 'Boa tarde,'
  return 'Boa noite,'
})

// Data de hoje formatada
const dataHojeFormatada = computed(() => {
  const hoje = new Date()
  const diasSemana = ['domingo', 'segunda-feira', 'terca-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sabado']
  const meses = ['janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']

  const diaSemana = diasSemana[hoje.getDay()]
  const dia = hoje.getDate().toString().padStart(2, '0')
  const mes = meses[hoje.getMonth()]
  const ano = hoje.getFullYear()

  return `${diaSemana}, ${dia} de ${mes} de ${ano}`
})

// Modal de detalhes
const modalDetalhesAberto = ref(false)
const detalhesAtual = ref<{ titulo: string; dados: any[] }>({ titulo: '', dados: [] })

const abrirModalDetalhes = (titulo: string, dados: any[]) => {
  detalhesAtual.value = { titulo, dados }
  modalDetalhesAberto.value = true
}

// Colunas para modal de detalhes
const colunasDetalhes: DataTableColumn<any>[] = [
  { key: 'local', label: 'Local' },
  { key: 'total', label: 'Quantidade', align: 'right', format: (v) => formatNumber(v) }
]

// Tree List - Resumo de Cadastros
const resumoCadastrosItems = computed<TreeListItem[]>(() => {
  const res = props.resumoParticipacao
  if (!res) return []

  const porTipoAcao = res.por_tipo_acao || []
  const detalhesEcopontos = res.detalhes_ecopontos || []

  // Montar children para itens expandíveis
  const childrenParticipantes = porTipoAcao.map(item => {
    const child: any = {
      key: `part_${item.tipo_acao}`,
      label: `de ${item.tipo_acao}`,
      value: item.total
    }
    // Se for ECOPONTOS e tiver detalhes, adicionar botão
    if (item.tipo_acao === 'ECOPONTOS' && detalhesEcopontos.length > 0) {
      child.actionButton = {
        label: 'Detalhes',
        onClick: () => abrirModalDetalhes('Detalhes ECOPONTOS', detalhesEcopontos)
      }
    }
    return child
  })

  const items: TreeListItem[] = [
    {
      key: 'totalContratos',
      label: 'Total Geral de Clientes Cadastrados',
      value: res.total_contratos || 0,
      expandable: false
    },
    {
      key: 'novosCadastros',
      label: 'Novos Cadastrados',
      value: res.novos_cadastros || 0,
      tooltip: 'Clientes que realizaram a primeira reciclagem no período selecionado',
      expandable: porTipoAcao.length > 0,
      children: porTipoAcao.map(item => ({
        key: `novo_${item.tipo_acao}`,
        label: `de ${item.tipo_acao}`,
        value: item.total
      }))
    },
    {
      key: 'participantes',
      label: 'Clientes Participantes',
      value: res.participantes_unicos || 0,
      tooltip: 'Clientes que realizaram pelo menos uma reciclagem no período selecionado',
      expandable: porTipoAcao.length > 0,
      children: childrenParticipantes
    },
    {
      key: 'assiduos',
      label: 'Clientes Assiduos',
      value: res.participantes_assiduos || 0,
      tooltip: 'Clientes que realizaram pelo menos 3 (três) reciclagens no período selecionado',
      expandable: false
    },
    {
      key: 'totalAtendimentos',
      label: 'Total Atendimentos (Reciclagens)',
      value: res.total_reciclagens || 0,
      expandable: porTipoAcao.length > 0,
      children: porTipoAcao.map(item => ({
        key: `atend_${item.tipo_acao}`,
        label: `de ${item.tipo_acao}`,
        value: item.total
      }))
    }
  ]

  return items
})
</script>

<template>
  <div class="space-y-6">
    <!-- Eventos Ativos (Mapa + Tabela) -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <!-- Header com saudação -->
      <div class="bg-brand-primary text-white text-center py-3 px-4">
        <span>{{ saudacao }} acoes abertas hoje: </span>
        <strong>{{ dataHojeFormatada }}</strong>
      </div>

      <!-- Conteúdo: Mapa + Tabela -->
      <div class="p-4">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <!-- Mapa -->
          <div>
            <IMap
              :markers="eventosAtivosMarkers"
              height="280px"
            />
          </div>

          <!-- Tabela -->
          <div>
            <DataTable
              :data="eventosAtivos || []"
              :columns="colunasEventosAtivos"
              row-key="local"
              :loading="isLoading"
              empty-message="Nenhum evento ativo no momento"
              :page-size="5"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Resumo de Cadastros (Tree List) -->
    <div>
      <h2 class="text-lg font-semibold text-gray-800 mb-4">Resumo de Cadastros</h2>
      <div v-if="isLoading" class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="animate-pulse space-y-3">
          <div class="h-10 bg-gray-200 rounded"></div>
          <div class="h-10 bg-gray-200 rounded"></div>
          <div class="h-10 bg-gray-200 rounded"></div>
          <div class="h-10 bg-gray-200 rounded"></div>
          <div class="h-10 bg-gray-200 rounded"></div>
        </div>
      </div>
      <ITreeList
        v-else
        :items="resumoCadastrosItems"
        :format-value="formatNumber"
      />
    </div>

    <!-- Modal de Detalhes (ECOPONTOS) -->
    <Teleport to="body">
      <div
        v-if="modalDetalhesAberto"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
        @click.self="modalDetalhesAberto = false"
      >
        <div class="bg-white rounded-lg shadow-xl max-w-lg w-full mx-4 max-h-[80vh] flex flex-col">
          <div class="flex items-center justify-between px-4 py-3 border-b">
            <h3 class="text-lg font-semibold text-gray-800">{{ detalhesAtual.titulo }}</h3>
            <button
              @click="modalDetalhesAberto = false"
              class="text-gray-400 hover:text-gray-600"
            >
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div class="p-4 overflow-auto">
            <DataTable
              :data="detalhesAtual.dados"
              :columns="colunasDetalhes"
              row-key="local"
              empty-message="Sem detalhes disponíveis"
            />
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Total Gerado por Ação + Cálculo de Economia Energética (lado a lado) -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Total Gerado por Ação -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="bg-gray-100 px-4 py-3 border-b">
          <h2 class="text-base font-semibold text-gray-800">Total Gerado por Acao</h2>
        </div>
        <div class="p-4">
          <DataTable
            :data="totalGeradoPorAcao || []"
            :columns="colunasTotalGerado"
            row-key="acao"
            :loading="isLoading"
            empty-message="Sem dados para o período"
            :page-size="10"
          />
          <!-- Linha de total -->
          <div v-if="totaisTotalGerado" class="mt-2 pt-2 border-t border-gray-300 bg-gray-50 px-3 py-2 rounded">
            <div class="flex justify-between text-sm font-semibold text-gray-800">
              <span>AVSI</span>
              <div class="flex gap-8">
                <span>{{ formatNumber(totaisTotalGerado.quantidade, 2) }}</span>
                <span>{{ formatNumber(totaisTotalGerado.valor, 2) }}</span>
                <span>{{ formatNumber(totaisTotalGerado.kwheco, 2) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Cálculo de Economia Energética -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="bg-gray-100 px-4 py-3 border-b">
          <h2 class="text-base font-semibold text-gray-800">Calculo de Economia Energetica</h2>
        </div>
        <div class="p-4 max-h-[400px] overflow-auto">
          <div v-if="isLoading" class="animate-pulse space-y-3">
            <div class="h-10 bg-gray-200 rounded"></div>
            <div class="h-10 bg-gray-200 rounded"></div>
            <div class="h-10 bg-gray-200 rounded"></div>
          </div>
          <div v-else-if="!economiaAgrupadaPorAcao.length" class="text-gray-400 text-center py-8">
            Sem dados para o período
          </div>
          <div v-else class="space-y-4">
            <!-- Agrupado por Ação -->
            <div v-for="grupo in economiaAgrupadaPorAcao" :key="grupo.acao">
              <!-- Header do grupo (Ação) -->
              <div class="bg-gray-200 px-3 py-2 font-semibold text-sm text-gray-700 rounded-t">
                {{ grupo.acao }}
              </div>
              <!-- Tabela de itens do grupo -->
              <table class="w-full text-sm">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">Residuo</th>
                    <th class="px-3 py-2 text-right text-xs font-medium text-gray-500">Coletado (Kg)</th>
                    <th class="px-3 py-2 text-right text-xs font-medium text-gray-500">Bonus (R$)</th>
                    <th class="px-3 py-2 text-right text-xs font-medium text-gray-500">Economia (kW/h)</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="item in grupo.items" :key="item.categoria" class="hover:bg-gray-50">
                    <td class="px-3 py-2">{{ item.categoria }}</td>
                    <td class="px-3 py-2 text-right">{{ formatNumber(item.reciclagens_total, 2) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatNumber(item.reciclagens_bonus_total, 2) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatNumber(item.kwh_economizado, 2) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Resumo por Ação (largura total) -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div class="bg-gray-100 px-4 py-3 border-b">
        <h2 class="text-base font-semibold text-gray-800">Resumo por Acao</h2>
      </div>
      <div class="p-4">
        <DataTable
          :data="resumoPorAcao || []"
          :columns="colunasResumoPorAcao"
          row-key="local_id"
          :loading="isLoading"
          empty-message="Sem dados para o período"
          :page-size="15"
        />
      </div>
    </div>

    <!-- Resumo de Doações (largura total) -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div class="bg-gray-100 px-4 py-3 border-b">
        <h2 class="text-base font-semibold text-gray-800">Resumo de Doacoes</h2>
      </div>
      <div class="p-4">
        <DataTable
          :data="resumoDoacoes || []"
          :columns="colunasDoacoes"
          row-key="recebedor"
          :loading="isLoading"
          empty-message="Sem doacoes no período"
          :page-size="10"
        />
        <!-- Linha de total -->
        <div v-if="resumoDoacoes?.length" class="mt-2 pt-2 border-t border-gray-300 bg-gray-50 px-3 py-2 rounded">
          <div class="flex justify-between text-sm font-semibold text-gray-800">
            <span>Total Doado</span>
            <span>{{ formatNumber(totalDoacoes, 2) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
