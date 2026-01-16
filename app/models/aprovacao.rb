# frozen_string_literal: true

# Aprovação - Workflow de aprovação para processos e custos
#
# @attr [String] tipo Tipo de aprovação
# @attr [String] status Status da aprovação
# @attr [DateTime] data_solicitacao Data da solicitação
# @attr [DateTime] data_resposta Data da resposta
#
class Aprovacao < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :solicitado_por, class_name: 'Usuario'
  belongs_to :aprovador, class_name: 'Usuario', optional: true
  belongs_to :custo_previsto, optional: true
  belongs_to :custo_real, optional: true

  # Validations
  validates :processo_importacao, presence: true
  validates :solicitado_por, presence: true
  validates :tipo, presence: true, inclusion: { in: %w[aprovacao_processo aprovacao_custo aprovacao_pagamento] }
  validates :status, presence: true, inclusion: { in: %w[pendente aprovado rejeitado cancelado] }
  validates :data_solicitacao, presence: true

  # Scopes
  scope :pendentes, -> { where(status: 'pendente') }
  scope :aprovadas, -> { where(status: 'aprovado') }
  scope :rejeitadas, -> { where(status: 'rejeitado') }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :por_aprovador, ->(aprovador_id) { where(aprovador_id: aprovador_id) }
  scope :aguardando_aprovador, ->(aprovador_id) { pendentes.where(aprovador_id: [nil, aprovador_id]) }
  scope :recentes, -> { order(data_solicitacao: :desc) }

  # Callbacks
  before_validation :definir_data_solicitacao, on: :create
  after_save :executar_acao_pos_aprovacao

  # Tipos de aprovação
  TIPOS = {
    'aprovacao_processo' => 'Aprovação de Processo',
    'aprovacao_custo' => 'Aprovação de Custo',
    'aprovacao_pagamento' => 'Aprovação de Pagamento'
  }.freeze

  # Status
  STATUSES = {
    'pendente' => 'Pendente',
    'aprovado' => 'Aprovado',
    'rejeitado' => 'Rejeitado',
    'cancelado' => 'Cancelado'
  }.freeze

  # @return [String] Tipo formatado
  def tipo_nome
    TIPOS[tipo] || tipo&.humanize
  end

  # @return [String] Status formatado
  def status_nome
    STATUSES[status] || status&.humanize
  end

  # @return [Boolean] Aguardando resposta?
  def pendente?
    status == 'pendente'
  end

  # @return [Integer, nil] Dias aguardando aprovação
  def dias_aguardando
    return nil unless pendente?

    (Time.current - data_solicitacao).to_i / 1.day
  end

  # @return [Integer, nil] Tempo de resposta em horas
  def tempo_resposta_horas
    return nil unless data_resposta.present?

    ((data_resposta - data_solicitacao) / 1.hour).round
  end

  # Aprova a solicitação
  def aprovar!(usuario, justificativa: nil)
    return false unless pendente?

    update!(
      status: 'aprovado',
      aprovador: usuario,
      data_resposta: Time.current,
      justificativa_resposta: justificativa
    )
  end

  # Rejeita a solicitação
  def rejeitar!(usuario, justificativa:)
    return false unless pendente?

    update!(
      status: 'rejeitado',
      aprovador: usuario,
      data_resposta: Time.current,
      justificativa_resposta: justificativa
    )
  end

  # Cancela a solicitação
  def cancelar!(motivo: nil)
    return false unless pendente?

    update!(
      status: 'cancelado',
      justificativa_resposta: motivo.presence || 'Cancelado pelo solicitante'
    )
  end

  private

  def definir_data_solicitacao
    self.data_solicitacao ||= Time.current
  end

  def executar_acao_pos_aprovacao
    return unless saved_change_to_status? && status == 'aprovado'

    case tipo
    when 'aprovacao_processo'
      processo_importacao.aprovar!(aprovador) if processo_importacao.status == 'planejado'
    when 'aprovacao_pagamento'
      custo_real&.registrar_pagamento! if custo_real.present?
    end
  end
end
