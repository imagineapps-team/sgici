// Types do Dashboard - Interfaces centralizadas

export interface KpiData {
  valor: number
  unidade: string
  label: string
}

export interface IndicadorAmbiental {
  valor: number
  unidade: string
  formula: string
  fonte: string
}

export interface EventoAtivo {
  acao_id: number
  acao: string
  local_id: number
  local: string
  latitude: number | null
  longitude: number | null
  bairro: string | null
  uf: string | null
  total_coletado: number
}

export interface TipoAcaoData {
  tipo_acao: string
  total: number
  percentual: number
}

export interface EcopontoLocalData {
  local: string
  total: number
  percentual: number
}

export interface ResumoParticipacao {
  participantes_unicos: number
  participantes_assiduos: number
  novos_cadastros: number
  total_reciclagens: number
  total_contratos: number
  por_tipo_acao: TipoAcaoData[]
  detalhes_ecopontos: EcopontoLocalData[]
}

export interface TotalGeradoPorAcao {
  acao: string
  quantidade: number
  valor: number
  kwheco: number
}

export interface CalculoEconomiaEnergetica {
  acao: string
  categoria: string
  reciclagens_total: number
  reciclagens_bonus_total: number
  kwh_economizado: number
}

export interface ResumoPorAcao {
  acao_id: number
  local_id: number
  acao: string
  local: string
  quantidade: number
  valor: number
  kwheco: number
}

export interface ResumoDoacao {
  recebedor: string
  bonus_total: number
}

export interface EvolucaoData {
  periodos: string[]
  locais: string[]
  series: { name: string; data: number[] }[]
}

export interface CategoriaData {
  categoria: string
  quantidade: number
  bonus: number
  kwh_eco: number
  co2_evitado: number
}

export interface DashboardMetrics {
  periodo: { inicio: string; fim: string }
  resumo_participacao: ResumoParticipacao
  kpis: {
    co2_evitado: KpiData
    peso_total: KpiData
    bonus_total: KpiData
    kwh_economizado: KpiData
  }
  indicadores_ambientais: Record<string, IndicadorAmbiental>
  evolucao: EvolucaoData
  eventos_ativos: EventoAtivo[]
  total_gerado_por_acao: TotalGeradoPorAcao[]
  calculo_economia_energetica: CalculoEconomiaEnergetica[]
  resumo_por_acao: ResumoPorAcao[]
  resumo_doacoes: ResumoDoacao[]
}

export interface FiltrosDashboard {
  dataInicial: string
  dataFinal: string
}

export type PeriodoKey = 'hoje' | 'semana' | 'mes' | 'anterior' | 'ano'

// KPI formatado para exibição
export interface KpiFormatado extends KpiData {
  key: string
  valorFormatado: string
  icone: string
  cor: string
}

// Grupo de economia por ação (para tabela agrupada)
export interface EconomiaGrupo {
  acao: string
  items: CalculoEconomiaEnergetica[]
}

// Totais calculados
export interface TotaisTotalGerado {
  quantidade: number
  valor: number
  kwheco: number
}
