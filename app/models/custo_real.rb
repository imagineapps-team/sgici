# frozen_string_literal: true

# Custo Real/Efetivo de um processo de importação
#
# @attr [Decimal] valor Valor na moeda original
# @attr [String] moeda Moeda do valor
# @attr [Decimal] valor_brl Valor convertido para BRL
# @attr [Date] data_lancamento Data do lançamento
# @attr [String] status_pagamento Status do pagamento
#
class CustoReal < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :categoria_custo
  belongs_to :prestador_servico, optional: true
  belongs_to :criado_por, class_name: 'Usuario'
  belongs_to :custo_previsto, optional: true

  has_many :anexos, as: :anexavel, dependent: :destroy

  # Validations
  validates :processo_importacao, presence: true
  validates :categoria_custo, presence: true
  validates :criado_por, presence: true
  validates :valor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :moeda, presence: true, inclusion: { in: %w[USD EUR CNY BRL GBP JPY] }
  validates :data_lancamento, presence: true
  validates :status_pagamento, inclusion: { in: %w[pendente pago cancelado] }
  validates :taxa_cambio, numericality: { greater_than: 0 }, allow_nil: true
  validate :categoria_permite_real
  validate :processo_editavel

  # Scopes
  scope :por_categoria, ->(categoria_id) { where(categoria_custo_id: categoria_id) }
  scope :por_grupo, ->(grupo) { joins(:categoria_custo).where(categorias_custo: { grupo: grupo }) }
  scope :por_prestador, ->(prestador_id) { where(prestador_servico_id: prestador_id) }
  scope :pendentes, -> { where(status_pagamento: 'pendente') }
  scope :pagos, -> { where(status_pagamento: 'pago') }
  scope :cancelados, -> { where(status_pagamento: 'cancelado') }
  scope :por_periodo, ->(inicio, fim) { where(data_lancamento: inicio..fim) }
  scope :vencidos, -> { pendentes.where('data_vencimento < ?', Date.current) }

  # Callbacks
  before_save :calcular_valor_brl
  before_save :calcular_desvio
  after_save :atualizar_totais_processo
  after_destroy :atualizar_totais_processo

  # Status de pagamento
  STATUS_PAGAMENTO = {
    'pendente' => 'Pendente',
    'pago' => 'Pago',
    'cancelado' => 'Cancelado'
  }.freeze

  # Tipos de documento
  TIPOS_DOCUMENTO = {
    'nota_fiscal' => 'Nota Fiscal',
    'fatura' => 'Fatura',
    'boleto' => 'Boleto',
    'recibo' => 'Recibo',
    'outro' => 'Outro'
  }.freeze

  # @return [String] Status formatado
  def status_pagamento_nome
    STATUS_PAGAMENTO[status_pagamento] || status_pagamento&.humanize
  end

  # @return [Decimal] Valor em BRL
  def valor_em_brl
    valor_brl || calcular_valor_brl_interno
  end

  # @return [Boolean] Está vencido?
  def vencido?
    status_pagamento == 'pendente' && data_vencimento.present? && data_vencimento < Date.current
  end

  # @return [Integer, nil] Dias até vencimento (ou dias vencido)
  def dias_vencimento
    return nil if data_vencimento.nil?

    (data_vencimento - Date.current).to_i
  end

  # Registra pagamento
  def registrar_pagamento!(data: Date.current)
    update!(status_pagamento: 'pago', data_pagamento: data)
  end

  # Cancela o custo
  def cancelar!
    update!(status_pagamento: 'cancelado')
  end

  private

  def categoria_permite_real
    return if categoria_custo.nil?

    unless categoria_custo.para_real?
      errors.add(:categoria_custo, 'não permite custos reais')
    end
  end

  def processo_editavel
    return if processo_importacao.nil?

    unless processo_importacao.editavel?
      errors.add(:processo_importacao, 'não pode ser editado')
    end
  end

  def calcular_valor_brl
    self.valor_brl = calcular_valor_brl_interno
  end

  def calcular_valor_brl_interno
    return valor if moeda == 'BRL'
    return nil if taxa_cambio.nil?

    (valor * taxa_cambio).round(2)
  end

  def calcular_desvio
    return unless custo_previsto.present?

    self.desvio_valor = valor_brl - custo_previsto.valor_brl
    self.desvio_percentual = if custo_previsto.valor_brl&.positive?
                               (desvio_valor / custo_previsto.valor_brl * 100).round(2)
                             else
                               0
                             end
  end

  def atualizar_totais_processo
    processo_importacao.consolidar_custos!
  end
end
