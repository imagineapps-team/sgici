# frozen_string_literal: true

# Ocorrência - Problemas e imprevistos no processo de importação
#
# @attr [String] tipo Tipo da ocorrência
# @attr [String] gravidade Nível de gravidade
# @attr [String] status Status atual
# @attr [Decimal] impacto_financeiro Impacto financeiro estimado
#
class Ocorrencia < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :criado_por, class_name: 'Usuario'
  belongs_to :responsavel, class_name: 'Usuario', optional: true

  has_many :anexos, as: :anexavel, dependent: :destroy

  # Validations
  validates :processo_importacao, presence: true
  validates :criado_por, presence: true
  validates :tipo, presence: true, inclusion: { in: %w[atraso avaria extravio documentacao aduaneira financeira outro] }
  validates :gravidade, presence: true, inclusion: { in: %w[baixa media alta critica] }
  validates :titulo, presence: true, length: { maximum: 255 }
  validates :descricao, presence: true
  validates :data_ocorrencia, presence: true
  validates :status, presence: true, inclusion: { in: %w[aberta em_analise resolvida cancelada] }
  validates :impacto_financeiro, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :abertas, -> { where(status: 'aberta') }
  scope :em_analise, -> { where(status: 'em_analise') }
  scope :resolvidas, -> { where(status: 'resolvida') }
  scope :ativas, -> { where(status: %w[aberta em_analise]) }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :por_gravidade, ->(gravidade) { where(gravidade: gravidade) }
  scope :criticas, -> { where(gravidade: 'critica') }
  scope :com_impacto_financeiro, -> { where.not(impacto_financeiro: nil).where('impacto_financeiro > 0') }
  scope :recentes, -> { order(data_ocorrencia: :desc) }

  # Callbacks
  after_create :notificar_responsaveis

  # Tipos de ocorrência
  TIPOS = {
    'atraso' => 'Atraso',
    'avaria' => 'Avaria/Dano',
    'extravio' => 'Extravio',
    'documentacao' => 'Problema de Documentação',
    'aduaneira' => 'Pendência Aduaneira',
    'financeira' => 'Problema Financeiro',
    'outro' => 'Outro'
  }.freeze

  # Níveis de gravidade
  GRAVIDADES = {
    'baixa' => 'Baixa',
    'media' => 'Média',
    'alta' => 'Alta',
    'critica' => 'Crítica'
  }.freeze

  # Status
  STATUSES = {
    'aberta' => 'Aberta',
    'em_analise' => 'Em Análise',
    'resolvida' => 'Resolvida',
    'cancelada' => 'Cancelada'
  }.freeze

  # @return [String] Tipo formatado
  def tipo_nome
    TIPOS[tipo] || tipo&.humanize
  end

  # @return [String] Gravidade formatada
  def gravidade_nome
    GRAVIDADES[gravidade] || gravidade&.humanize
  end

  # @return [String] Status formatado
  def status_nome
    STATUSES[status] || status&.humanize
  end

  # @return [Boolean] Ocorrência está ativa?
  def ativa?
    status.in?(%w[aberta em_analise])
  end

  # @return [Integer, nil] Dias em aberto
  def dias_aberto
    return nil if data_resolucao.present?

    (Date.current - data_ocorrencia).to_i
  end

  # @return [Integer, nil] Tempo de resolução em dias
  def tempo_resolucao
    return nil unless data_resolucao.present?

    (data_resolucao - data_ocorrencia).to_i
  end

  # Inicia análise da ocorrência
  def iniciar_analise!(responsavel_usuario)
    update!(status: 'em_analise', responsavel: responsavel_usuario)
  end

  # Resolve a ocorrência
  def resolver!(resolucao_texto)
    update!(
      status: 'resolvida',
      resolucao: resolucao_texto,
      data_resolucao: Date.current
    )
  end

  # Cancela a ocorrência
  def cancelar!(motivo = nil)
    update!(
      status: 'cancelada',
      resolucao: motivo.presence || 'Cancelada'
    )
  end

  private

  def notificar_responsaveis
    # TODO: Implementar notificação via Notificacao model
  end
end
