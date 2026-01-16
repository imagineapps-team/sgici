# frozen_string_literal: true

# Prestador de serviço (despachante, freight forwarder, transportadora, etc.)
#
# @attr [String] nome Nome do prestador
# @attr [String] tipo Tipo de serviço prestado
# @attr [String] cnpj CNPJ
# @attr [Decimal] score Score de avaliação
# @attr [Boolean] ativo Status ativo/inativo
#
class PrestadorServico < ApplicationRecord
  # Associations
  has_many :processo_prestadores, dependent: :destroy
  has_many :processos_importacao, through: :processo_prestadores
  has_many :custos_reais, dependent: :restrict_with_error

  # Validations
  validates :nome, presence: true, length: { maximum: 255 }
  validates :tipo, presence: true, inclusion: { in: %w[freight_forwarder despachante seguradora transportadora armazem outro] }
  validates :cnpj, uniqueness: true, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  # Scopes
  scope :ativos, -> { where(ativo: true) }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :freight_forwarders, -> { where(tipo: 'freight_forwarder') }
  scope :despachantes, -> { where(tipo: 'despachante') }
  scope :seguradoras, -> { where(tipo: 'seguradora') }
  scope :transportadoras, -> { where(tipo: 'transportadora') }
  scope :armazens, -> { where(tipo: 'armazem') }

  # Callbacks
  before_save :normalizar_cnpj

  # Tipos de prestadores
  TIPOS = {
    'freight_forwarder' => 'Freight Forwarder',
    'despachante' => 'Despachante Aduaneiro',
    'seguradora' => 'Seguradora',
    'transportadora' => 'Transportadora',
    'armazem' => 'Armazém',
    'outro' => 'Outro'
  }.freeze

  # @return [String] Nome do tipo formatado
  def tipo_nome
    TIPOS[tipo] || tipo&.humanize
  end

  # @return [String] Nome completo com tipo
  def nome_completo
    "#{nome} (#{tipo_nome})"
  end

  # @return [String] Contato formatado
  def contato
    return nil if contato_nome.blank?

    parts = [contato_nome]
    parts << contato_email if contato_email.present?
    parts << contato_telefone if contato_telefone.present?
    parts.join(' - ')
  end

  # Atualiza estatísticas do prestador
  def recalcular_estatisticas!
    update_columns(
      total_servicos: processos_importacao.count,
      updated_at: Time.current
    )
  end

  private

  def normalizar_cnpj
    self.cnpj = cnpj.gsub(/\D/, '') if cnpj.present?
  end
end
