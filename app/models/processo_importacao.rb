# frozen_string_literal: true

# Processo de Importação - Entidade central do SGICI
#
# @attr [String] numero Número único do processo (IMP-2026-0001)
# @attr [String] status Status atual do processo
# @attr [String] modal Modal de transporte (maritimo, aereo, rodoviario)
# @attr [String] incoterm Termo comercial (FOB, CIF, EXW, etc.)
# @attr [Decimal] valor_fob Valor FOB da mercadoria
# @attr [Decimal] custo_previsto_total Total de custos previstos
# @attr [Decimal] custo_real_total Total de custos reais
#
class ProcessoImportacao < ApplicationRecord
  # Associations
  belongs_to :fornecedor
  belongs_to :criado_por, class_name: 'Usuario'
  belongs_to :responsavel, class_name: 'Usuario', optional: true
  belongs_to :atualizado_por, class_name: 'Usuario', optional: true

  has_many :processo_prestadores, dependent: :destroy
  has_many :prestadores_servico, through: :processo_prestadores

  has_many :custos_previstos, dependent: :destroy
  has_many :custos_reais, dependent: :destroy
  has_many :eventos_logisticos, dependent: :destroy
  has_many :ocorrencias, dependent: :destroy
  has_many :aprovacoes, dependent: :destroy
  has_many :anexos, as: :anexavel, dependent: :destroy

  # Validations
  validates :numero, presence: true, uniqueness: true
  validates :fornecedor, presence: true
  validates :criado_por, presence: true
  validates :pais_origem, presence: true
  validates :modal, presence: true, inclusion: { in: %w[maritimo aereo rodoviario multimodal] }
  validates :status, presence: true, inclusion: { in: %w[planejado aprovado em_transito desembaracado finalizado cancelado] }
  validates :moeda, presence: true, inclusion: { in: %w[USD EUR CNY BRL GBP JPY] }
  validates :incoterm, inclusion: { in: %w[EXW FCA FAS FOB CFR CIF CPT CIP DAP DPU DDP] }, allow_blank: true
  validates :valor_fob, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :taxa_cambio, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :planejados, -> { where(status: 'planejado') }
  scope :aprovados, -> { where(status: 'aprovado') }
  scope :em_transito, -> { where(status: 'em_transito') }
  scope :desembaracados, -> { where(status: 'desembaracado') }
  scope :finalizados, -> { where(status: 'finalizado') }
  scope :cancelados, -> { where(status: 'cancelado') }
  scope :ativos, -> { where.not(status: %w[finalizado cancelado]) }
  scope :por_fornecedor, ->(fornecedor_id) { where(fornecedor_id: fornecedor_id) }
  scope :por_pais, ->(pais) { where(pais_origem: pais) }
  scope :por_modal, ->(modal) { where(modal: modal) }
  scope :por_periodo, ->(inicio, fim) { where(data_criacao: inicio..fim) }
  scope :com_atraso, -> { where('data_chegada_real > data_chegada_prevista') }
  scope :recentes, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :gerar_numero, on: :create
  before_save :calcular_desvios
  after_save :atualizar_estatisticas_fornecedor

  # Status do processo
  STATUSES = {
    'planejado' => 'Planejado',
    'aprovado' => 'Aprovado',
    'em_transito' => 'Em Trânsito',
    'desembaracado' => 'Desembaraçado',
    'finalizado' => 'Finalizado',
    'cancelado' => 'Cancelado'
  }.freeze

  # Modais de transporte
  MODAIS = {
    'maritimo' => 'Marítimo',
    'aereo' => 'Aéreo',
    'rodoviario' => 'Rodoviário',
    'multimodal' => 'Multimodal'
  }.freeze

  # Incoterms
  INCOTERMS = %w[EXW FCA FAS FOB CFR CIF CPT CIP DAP DPU DDP].freeze

  # @return [String] Status formatado
  def status_nome
    STATUSES[status] || status&.humanize
  end

  # @return [String] Modal formatado
  def modal_nome
    MODAIS[modal] || modal&.humanize
  end

  # @return [Boolean] Processo pode ser editado?
  def editavel?
    !status.in?(%w[finalizado cancelado]) && bloqueado_em.nil?
  end

  # @return [Boolean] Processo está atrasado?
  def atrasado?
    return false if data_chegada_prevista.nil?
    return data_chegada_real > data_chegada_prevista if data_chegada_real.present?

    Date.current > data_chegada_prevista && !status.in?(%w[desembaracado finalizado])
  end

  # @return [Integer, nil] Dias de atraso
  def dias_atraso
    return nil unless atrasado?

    data_referencia = data_chegada_real || Date.current
    (data_referencia - data_chegada_prevista).to_i
  end

  # @return [Integer, nil] Lead time em dias
  def lead_time
    return lead_time_dias if lead_time_dias.present?
    return nil if data_embarque_real.nil?

    data_fim = data_entrega_real || data_chegada_real || Date.current
    (data_fim - data_embarque_real).to_i
  end

  # @return [Decimal] Percentual de desvio de custos
  def percentual_desvio
    return 0 if custo_previsto_total.nil? || custo_previsto_total.zero?

    ((custo_real_total.to_f - custo_previsto_total.to_f) / custo_previsto_total.to_f * 100).round(2)
  end

  # @return [String] Origem formatada (porto ou aeroporto)
  def origem_formatada
    if modal == 'aereo'
      aeroporto_origem.presence || pais_origem
    else
      porto_origem.presence || pais_origem
    end
  end

  # @return [String] Destino formatado
  def destino_formatado
    if modal == 'aereo'
      aeroporto_destino.presence || 'Brasil'
    else
      porto_destino.presence || 'Brasil'
    end
  end

  # Transições de status
  def aprovar!(usuario)
    return false unless status == 'planejado'

    update!(status: 'aprovado', atualizado_por: usuario)
  end

  def iniciar_transito!(usuario)
    return false unless status == 'aprovado'

    update!(status: 'em_transito', atualizado_por: usuario, data_embarque_real: data_embarque_real || Date.current)
  end

  def registrar_desembaraco!(usuario, data: Date.current)
    return false unless status == 'em_transito'

    update!(status: 'desembaracado', atualizado_por: usuario, data_desembaraco: data, data_chegada_real: data_chegada_real || data)
  end

  def finalizar!(usuario)
    return false unless status == 'desembaracado'

    consolidar_custos!
    update!(
      status: 'finalizado',
      atualizado_por: usuario,
      data_finalizacao: Date.current,
      bloqueado_em: Time.current,
      lead_time_dias: lead_time
    )
  end

  def cancelar!(usuario, motivo: nil)
    return false if status == 'finalizado'

    update!(status: 'cancelado', atualizado_por: usuario, observacoes: [observacoes, "Cancelado: #{motivo}"].compact.join("\n"))
  end

  # Recalcula totais de custos
  def consolidar_custos!
    previsto = custos_previstos.sum(:valor_brl)
    real = custos_reais.sum(:valor_brl)

    update_columns(
      custo_previsto_total: previsto,
      custo_real_total: real,
      desvio_absoluto: real - previsto,
      desvio_percentual: previsto.positive? ? ((real - previsto) / previsto * 100).round(2) : 0
    )
  end

  private

  def gerar_numero
    return if numero.present?

    ano = Date.current.year
    ultimo = ProcessoImportacao.where('numero LIKE ?', "IMP-#{ano}-%").order(:numero).last
    sequencia = ultimo ? ultimo.numero.split('-').last.to_i + 1 : 1

    self.numero = format("IMP-%d-%04d", ano, sequencia)
  end

  def calcular_desvios
    return unless custo_previsto_total_changed? || custo_real_total_changed?

    self.desvio_absoluto = (custo_real_total || 0) - (custo_previsto_total || 0)
    self.desvio_percentual = if custo_previsto_total&.positive?
                               (desvio_absoluto / custo_previsto_total * 100).round(2)
                             else
                               0
                             end
  end

  def atualizar_estatisticas_fornecedor
    fornecedor.recalcular_score! if saved_change_to_status?
  end
end
