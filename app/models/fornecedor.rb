# frozen_string_literal: true

# Fornecedor internacional de produtos
#
# @attr [String] nome Nome do fornecedor
# @attr [String] nome_fantasia Nome fantasia
# @attr [String] cnpj CNPJ (se brasileiro)
# @attr [String] pais País de origem
# @attr [String] moeda_padrao Moeda padrão (USD, EUR, CNY)
# @attr [Decimal] score Score de avaliação (0-5)
# @attr [Boolean] ativo Status ativo/inativo
#
class Fornecedor < ApplicationRecord
  # Associations
  has_many :processos_importacao, dependent: :restrict_with_error

  # Validations
  validates :nome, presence: true, length: { maximum: 255 }
  validates :pais, presence: true
  validates :cnpj, uniqueness: true, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :moeda_padrao, inclusion: { in: %w[USD EUR CNY BRL GBP JPY] }, allow_blank: true
  validates :prazo_pagamento_dias, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  # Scopes
  scope :ativos, -> { where(ativo: true) }
  scope :inativos, -> { where(ativo: false) }
  scope :por_pais, ->(pais) { where(pais: pais) }
  scope :com_processos, -> { joins(:processos_importacao).distinct }

  # Callbacks
  before_save :normalizar_cnpj

  # Países mais comuns
  PAISES_PRINCIPAIS = %w[China Estados\ Unidos Alemanha Japão Coreia\ do\ Sul Taiwan Índia Brasil].freeze

  # Moedas suportadas
  MOEDAS = {
    'USD' => 'Dólar Americano',
    'EUR' => 'Euro',
    'CNY' => 'Yuan Chinês',
    'BRL' => 'Real Brasileiro',
    'GBP' => 'Libra Esterlina',
    'JPY' => 'Iene Japonês'
  }.freeze

  # @return [String] Nome completo com país
  def nome_completo
    "#{nome} (#{pais})"
  end

  # @return [String] Contato comercial formatado
  def contato_comercial
    return nil if contato_comercial_nome.blank?

    parts = [contato_comercial_nome]
    parts << contato_comercial_email if contato_comercial_email.present?
    parts << contato_comercial_telefone if contato_comercial_telefone.present?
    parts.join(' - ')
  end

  # @return [String] Contato operacional formatado
  def contato_operacional
    return nil if contato_operacional_nome.blank?

    parts = [contato_operacional_nome]
    parts << contato_operacional_email if contato_operacional_email.present?
    parts << contato_operacional_telefone if contato_operacional_telefone.present?
    parts.join(' - ')
  end

  # Atualiza o score baseado nos processos
  def recalcular_score!
    # TODO: Implementar cálculo baseado em pontualidade, qualidade, etc.
    update_columns(
      total_processos: processos_importacao.count,
      updated_at: Time.current
    )
  end

  private

  def normalizar_cnpj
    self.cnpj = cnpj.gsub(/\D/, '') if cnpj.present?
  end
end
