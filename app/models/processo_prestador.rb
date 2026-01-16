# frozen_string_literal: true

# Associação entre Processo de Importação e Prestador de Serviço
#
# @attr [String] funcao Função do prestador no processo
# @attr [Boolean] principal Se é o prestador principal para esta função
#
class ProcessoPrestador < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :prestador_servico

  # Validations
  validates :processo_importacao, presence: true
  validates :prestador_servico, presence: true
  validates :funcao, presence: true
  validates :prestador_servico_id, uniqueness: { scope: [:processo_importacao_id, :funcao],
                                                  message: 'já está associado a este processo com esta função' }

  # Scopes
  scope :principais, -> { where(principal: true) }
  scope :por_funcao, ->(funcao) { where(funcao: funcao) }

  # Funções possíveis
  FUNCOES = {
    'freight_forwarder' => 'Freight Forwarder',
    'despachante' => 'Despachante',
    'transportadora_internacional' => 'Transportadora Internacional',
    'transportadora_nacional' => 'Transportadora Nacional',
    'seguradora' => 'Seguradora',
    'armazem' => 'Armazém',
    'agente_carga' => 'Agente de Carga'
  }.freeze

  # @return [String] Nome da função formatado
  def funcao_nome
    FUNCOES[funcao] || funcao&.humanize
  end

  # @return [String] Descrição completa
  def descricao_completa
    "#{prestador_servico.nome} - #{funcao_nome}"
  end
end
