/**
 * Definição de uma coluna da tabela
 */
export interface DataTableColumn<T> {
  /** Chave do campo na entidade */
  key: keyof T | string
  /** Label exibido no header */
  label: string
  /** Se a coluna é ordenável */
  sortable?: boolean
  /** Largura da coluna (ex: 'w-32', '150px') */
  width?: string
  /** Alinhamento do conteúdo */
  align?: 'left' | 'center' | 'right'
  /** Função para formatar o valor exibido */
  format?: (value: T[keyof T], row: T) => string
  /** Nome do slot customizado para renderização */
  slot?: string
}

/**
 * Ação disponível para cada linha
 */
export interface DataTableAction<T> {
  /** Identificador único da ação */
  id: string
  /** Label do botão/tooltip */
  label: string
  /** Ícone (nome do heroicon) */
  icon?: string
  /** Variante de estilo */
  variant?: 'primary' | 'secondary' | 'danger' | 'warning'
  /** Callback executado ao clicar */
  handler: (row: T) => void
  /** Função que determina se a ação está visível para a linha */
  visible?: (row: T) => boolean
  /** Função que determina se a ação está desabilitada para a linha */
  disabled?: (row: T) => boolean
  /** Requer confirmação antes de executar */
  confirm?: {
    title: string
    message: string | ((row: T) => string)
  }
}

/**
 * Tipos de filtro disponíveis
 */
export type FilterType = 'text' | 'select' | 'date' | 'dateRange' | 'number' | 'boolean'

/**
 * Opção para filtros do tipo select
 */
export interface FilterOption {
  value: string | number | boolean
  label: string
}

/**
 * Definição de um filtro
 */
export interface DataTableFilter<T> {
  /** Chave do campo para filtrar */
  key: keyof T | string
  /** Label do filtro */
  label: string
  /** Tipo do filtro */
  type: FilterType
  /** Placeholder */
  placeholder?: string
  /** Opções para filtro tipo select */
  options?: FilterOption[]
  /** Valor padrão */
  defaultValue?: string | number | boolean | null
}

/**
 * Estado atual dos filtros
 */
export type FilterValues<T> = Partial<Record<keyof T | string, string | number | boolean | null | DateRange>>

/**
 * Range de datas para filtro dateRange
 */
export interface DateRange {
  start: string | null
  end: string | null
}

/**
 * Configuração de ordenação
 */
export interface SortConfig<T> {
  key: keyof T | string
  direction: 'asc' | 'desc'
}

/**
 * Configuração de paginação
 */
export interface PaginationConfig {
  currentPage: number
  perPage: number
  total: number
  perPageOptions?: number[]
}

/**
 * Props do componente DataTable
 */
export interface DataTableProps<T> {
  /** Dados da tabela */
  data: T[]
  /** Definição das colunas */
  columns: DataTableColumn<T>[]
  /** Chave única de cada registro */
  rowKey: keyof T
  /** Ações disponíveis */
  actions?: DataTableAction<T>[]
  /** Mostrar ações padrão (editar/remover) */
  defaultActions?: {
    edit?: boolean
    delete?: boolean
  }
  /** Filtros disponíveis */
  filters?: DataTableFilter<T>[]
  /** Configuração de paginação */
  pagination?: PaginationConfig
  /** Se está carregando */
  loading?: boolean
  /** Mensagem quando não há dados */
  emptyMessage?: string
  /** Se as linhas são selecionáveis */
  selectable?: boolean
  /** Linhas selecionadas (v-model) */
  selected?: T[]
}

/**
 * Eventos emitidos pelo DataTable
 */
export interface DataTableEmits<T> {
  (e: 'edit', row: T): void
  (e: 'delete', row: T): void
  (e: 'action', action: string, row: T): void
  (e: 'sort', sort: SortConfig<T>): void
  (e: 'filter', filters: FilterValues<T>): void
  (e: 'page-change', page: number): void
  (e: 'per-page-change', perPage: number): void
  (e: 'update:selected', selected: T[]): void
}
