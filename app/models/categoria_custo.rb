# frozen_string_literal: true

# Categoria de custo para importação
#
# @attr [String] nome Nome da categoria
# @attr [String] codigo Código único (FOB, II, ICMS, etc.)
# @attr [String] tipo Tipo: previsto, real ou ambos
# @attr [String] grupo Grupo de custos (fob, frete, impostos, etc.)
# @attr [Integer] ordem Ordem de exibição
# @attr [Boolean] obrigatorio Se é obrigatório informar
# @attr [Boolean] ativo Status ativo/inativo
#
class CategoriaCusto < ApplicationRecord
  # Associations
  has_many :custos_previstos, dependent: :restrict_with_error
  has_many :custos_reais, dependent: :restrict_with_error

  # Validations
  validates :nome, presence: true, uniqueness: true
  validates :codigo, uniqueness: true, allow_blank: true
  validates :tipo, inclusion: { in: %w[previsto real ambos] }
  validates :grupo, inclusion: { in: %w[fob frete seguro impostos armazenagem servicos transporte outros] }, allow_blank: true

  # Scopes
  scope :ativos, -> { where(ativo: true) }
  scope :obrigatorios, -> { where(obrigatorio: true) }
  scope :por_grupo, ->(grupo) { where(grupo: grupo) }
  scope :para_previstos, -> { where(tipo: %w[previsto ambos]) }
  scope :para_reais, -> { where(tipo: %w[real ambos]) }
  scope :ordenados, -> { order(:ordem, :nome) }

  # Grupos de custos
  GRUPOS = {
    'fob' => 'Valor do Produto',
    'frete' => 'Frete e Transporte Internacional',
    'seguro' => 'Seguros',
    'impostos' => 'Impostos e Taxas',
    'armazenagem' => 'Armazenagem e Terminal',
    'servicos' => 'Serviços',
    'transporte' => 'Transporte Nacional',
    'outros' => 'Outros Custos'
  }.freeze

  # Tipos
  TIPOS = {
    'previsto' => 'Apenas Previsto',
    'real' => 'Apenas Real',
    'ambos' => 'Previsto e Real'
  }.freeze

  # @return [String] Nome do grupo formatado
  def grupo_nome
    GRUPOS[grupo] || grupo&.humanize
  end

  # @return [Boolean] Categoria pode ser usada em custos previstos?
  def para_previsto?
    tipo.in?(%w[previsto ambos])
  end

  # @return [Boolean] Categoria pode ser usada em custos reais?
  def para_real?
    tipo.in?(%w[real ambos])
  end

  # @return [String] Descrição completa para exibição
  def descricao_completa
    parts = [nome]
    parts << "(#{codigo})" if codigo.present?
    parts.join(' ')
  end

  # Retorna categorias agrupadas por grupo
  # @return [Hash<String, Array<CategoriaCusto>>]
  def self.agrupadas
    ativos.ordenados.group_by(&:grupo)
  end
end
