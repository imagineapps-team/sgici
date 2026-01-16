// Types do SGICI - Interfaces de Importação
// Baseado nos models Rails: ProcessoImportacao, CustoPrevisto, CustoReal, etc.

// Status do processo de importação
export type ProcessoStatus = 'planejado' | 'aprovado' | 'em_transito' | 'desembaracado' | 'finalizado' | 'cancelado'

// Modais de transporte
export type ModalTransporte = 'maritimo' | 'aereo' | 'rodoviario' | 'multimodal'

// Incoterms
export type Incoterm = 'EXW' | 'FCA' | 'FAS' | 'FOB' | 'CFR' | 'CIF' | 'CPT' | 'CIP' | 'DAP' | 'DPU' | 'DDP'

// Moedas suportadas
export type Moeda = 'USD' | 'EUR' | 'CNY' | 'BRL' | 'GBP' | 'JPY'

// Referência simplificada para relacionamentos
export interface RefSimples {
  id: number
  nome: string
}

// Fornecedor resumido
export interface FornecedorRef extends RefSimples {
  pais?: string
  score?: number
}

// Responsável/Usuário resumido
export interface ResponsavelRef {
  id: number
  nome: string
  login?: string
}

// Processo de Importação - Listagem
export interface ProcessoImportacaoList {
  id: number
  numero: string
  status: ProcessoStatus
  statusLabel: string
  modal: ModalTransporte
  modalLabel: string
  fornecedor: FornecedorRef
  responsavel: ResponsavelRef | null
  valorFob: number | null
  moeda: Moeda
  paisOrigem: string
  dataEmbarquePrevista: string | null
  dataChegadaPrevista: string | null
  custoPrevistoTotal: number | null
  custoRealTotal: number | null
  desvioPercentual: number | null
  atrasado: boolean
  diasAtraso: number | null
  situacaoDias: number | null  // Dias faltantes (positivo) ou atrasado (negativo)
  editavel: boolean
  createdAt: string
  updatedAt: string
}

// Processo de Importação - Detalhes completos
export interface ProcessoImportacao extends ProcessoImportacaoList {
  incoterm: Incoterm | null
  taxaCambio: number | null
  portoOrigem: string | null
  portoDestino: string | null
  aeroportoOrigem: string | null
  aeroportoDestino: string | null
  numeroBl: string | null
  numeroAwb: string | null
  numeroContainer: string | null
  numeroDi: string | null
  numeroDuimp: string | null
  dataEmbarqueReal: string | null
  dataChegadaReal: string | null
  dataDesembaraco: string | null
  dataEntregaPrevista: string | null
  dataEntregaReal: string | null
  dataFinalizacao: string | null
  leadTimeDias: number | null
  desvioAbsoluto: number | null
  observacoes: string | null
  bloqueadoEm: string | null
  criadoPor: ResponsavelRef
  atualizadoPor: ResponsavelRef | null
  custosPrevistos: CustoPrevisto[]
  custosReais: CustoReal[]
  eventosLogisticos: EventoLogistico[]
  prestadores: PrestadorRef[]
  totalAnexos: number
}

// Processo de Importação - Formulário
export interface ProcessoImportacaoForm {
  id?: number
  numero?: string
  fornecedorId: number | null
  responsavelId: number | null
  paisOrigem: string
  modal: ModalTransporte
  incoterm: Incoterm | null
  moeda: Moeda
  valorFob: number | null
  taxaCambio: number | null
  portoOrigem: string | null
  portoDestino: string | null
  aeroportoOrigem: string | null
  aeroportoDestino: string | null
  numeroBl: string | null
  numeroContainer: string | null
  dataEmbarquePrevista: string | null
  dataChegadaPrevista: string | null
  dataEntregaPrevista: string | null
  observacoes: string | null
}

// Categoria de Custo
export interface CategoriaCusto {
  id: number
  nome: string
  codigo: string
  tipo: 'previsto' | 'real' | 'ambos'
  ativa: boolean
}

// Custo Previsto
export interface CustoPrevisto {
  id: number
  categoriaId: number
  categoria: RefSimples | null
  prestador: RefSimples | null
  descricao: string | null
  moeda: Moeda
  valor: number
  valorBrl: number
  taxaCambio: number | null
  dataPrevisao: string | null
  realizado?: boolean
  createdAt?: string
}

// Opção de Categoria para selects
export interface CategoriaOption {
  id: number
  nome: string
  codigo: string | null
  grupo: string | null
  grupoNome: string | null
  obrigatorio: boolean
}

// Custo Real
export interface CustoReal {
  id: number
  categoriaId: number
  categoria: RefSimples | null
  prestadorId: number | null
  prestador: RefSimples | null
  custoPrevistoId: number | null
  custoPrevisto: RefSimples | null
  descricao: string | null
  moeda: Moeda
  valor: number
  valorBrl: number
  taxaCambio: number | null
  dataLancamento: string | null
  numeroDocumento: string | null
  tipoDocumento: string | null
  dataVencimento: string | null
  dataPagamento: string | null
  statusPagamento: string | null
  statusLabel: string | null
  desvioValor: number | null
  desvioPercentual: number | null
  createdAt?: string
}

// Opcao de Prestador para selects
export interface PrestadorOption {
  id: number
  nome: string
  tipo: string
}

// Opcao de Custo Previsto para vinculacao
export interface CustoPrevistoOption {
  id: number
  categoriaId: number
  categoria: string
  valorBrl: number
  label: string
}

// Evento Logístico
export interface EventoLogistico {
  id: number
  tipo: string
  tipoLabel: string
  descricao: string | null
  dataEvento: string
  localEvento: string | null
  observacoes: string | null
  registradoPor: ResponsavelRef
  createdAt: string
}

// Prestador de Serviço
export interface PrestadorRef {
  id: number
  nome: string
  tipo: string
  cnpj: string | null
}

// Comparativo de Custos por Categoria
export interface ComparativoCusto {
  categoriaId: number
  categoria: string
  previsto: number
  real: number
  desvio: number
  desvioPercentual: number
}

// Métricas do Dashboard de Importação
export interface DashboardImportacaoKpis {
  processosAtivos: number
  processosEmTransito: number
  valorEmTransitoUsd: number
  variacaoMediaCusto: number
  alertasPendentes: number
  leadTimeMedio: number
}

// Processo por Status (para gráficos)
export interface ProcessoPorStatus {
  status: ProcessoStatus
  statusLabel: string
  total: number
  valorTotal: number
}

// Custo por Categoria (para gráficos)
export interface CustoPorCategoria {
  categoria: string
  previsto: number
  real: number
  variacao: number
}

// Processo Resumido (para tabelas do dashboard)
export interface ProcessoResumo {
  id: number
  numero: string
  fornecedor: string
  status: ProcessoStatus
  statusLabel: string
  dataChegadaPrevista: string | null
  diasParaChegada: number | null
  atrasado: boolean
  valorFob: number | null
}

// Métricas Completas do Dashboard
export interface DashboardImportacaoMetrics {
  periodo: { inicio: string; fim: string }
  kpis: DashboardImportacaoKpis
  processosPorStatus: ProcessoPorStatus[]
  custosComparativo: CustoPorCategoria[]
  proximasChegadas: ProcessoResumo[]
  processosAtrasados: ProcessoResumo[]
  ultimosProcessos: ProcessoResumo[]
}

// Filtros do Dashboard
export interface FiltrosDashboardImportacao {
  dataInicial: string
  dataFinal: string
  fornecedorId?: number | null
  modal?: ModalTransporte | null
  status?: ProcessoStatus | null
}

// Options para selects
export interface SelectOption {
  value: string | number
  label: string
  disabled?: boolean
}

// Props da página Index
export interface ProcessosImportacaoIndexProps {
  processos: ProcessoImportacaoList[]
  statusOptions: SelectOption[]
  modalOptions: SelectOption[]
  fornecedoresOptions: SelectOption[]
  pagination: PaginationConfig
  filters: {
    status?: string
    modal?: string
    fornecedorId?: number
    search?: string
  }
}

// Props da página Form
export interface ProcessosImportacaoFormProps {
  processo: ProcessoImportacao | null
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

// Props da página Show
export interface ProcessosImportacaoShowProps {
  processo: ProcessoImportacao
  comparativoCustos: ComparativoCusto[]
  podeEditar: boolean
  podeTransitar: boolean
  podeDesembaracar: boolean
  podeFinalizar: boolean
  podeCancelar: boolean
}

// Config de paginação
export interface PaginationConfig {
  page: number
  perPage: number
  total: number
  totalPages: number
}

// Resposta de transição de status
export interface TransicaoStatusResponse {
  success: boolean
  message: string
  processo?: ProcessoImportacaoList
}
