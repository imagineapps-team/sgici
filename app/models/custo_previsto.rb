# frozen_string_literal: true

# Custo Previsto/Estimado para um processo de importação
#
# @attr [Decimal] valor Valor na moeda original
# @attr [String] moeda Moeda do valor (USD, BRL, etc.)
# @attr [Decimal] taxa_cambio Taxa de câmbio aplicada
# @attr [Decimal] valor_brl Valor convertido para BRL
#
class CustoPrevisto < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :categoria_custo
  belongs_to :criado_por, class_name: 'Usuario'

  has_one :custo_real, dependent: :nullify

  # Validations
  validates :processo_importacao, presence: true
  validates :categoria_custo, presence: true
  validates :criado_por, presence: true
  validates :valor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :moeda, presence: true, inclusion: { in: %w[USD EUR CNY BRL GBP JPY] }
  validates :taxa_cambio, numericality: { greater_than: 0 }, allow_nil: true
  validate :categoria_permite_previsto

  # Scopes
  scope :por_categoria, ->(categoria_id) { where(categoria_custo_id: categoria_id) }
  scope :por_grupo, ->(grupo) { joins(:categoria_custo).where(categorias_custo: { grupo: grupo }) }
  scope :em_brl, -> { where(moeda: 'BRL') }
  scope :em_moeda_estrangeira, -> { where.not(moeda: 'BRL') }

  # Callbacks
  before_save :calcular_valor_brl
  after_save :atualizar_totais_processo
  after_destroy :atualizar_totais_processo

  # @return [Decimal] Valor em BRL (calculado ou armazenado)
  def valor_em_brl
    valor_brl || calcular_valor_brl_interno
  end

  # @return [Boolean] Tem custo real correspondente?
  def realizado?
    custo_real.present?
  end

  # @return [Decimal, nil] Desvio em relação ao custo real
  def desvio
    return nil unless realizado?

    custo_real.valor_brl - valor_brl
  end

  # @return [Decimal, nil] Percentual de desvio
  def percentual_desvio
    return nil unless realizado? && valor_brl&.positive?

    ((custo_real.valor_brl - valor_brl) / valor_brl * 100).round(2)
  end

  private

  def categoria_permite_previsto
    return if categoria_custo.nil?

    unless categoria_custo.para_previsto?
      errors.add(:categoria_custo, 'não permite custos previstos')
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

  def atualizar_totais_processo
    processo_importacao.consolidar_custos!
  end
end
