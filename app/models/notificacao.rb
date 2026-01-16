# frozen_string_literal: true

# Notificação - Sistema de notificações para usuários
#
# @attr [String] tipo Tipo da notificação
# @attr [String] titulo Título
# @attr [String] prioridade Nível de prioridade
# @attr [String] canal Canal de envio
# @attr [String] status Status da notificação
#
class Notificacao < ApplicationRecord
  # Associations
  belongs_to :usuario
  belongs_to :notificavel, polymorphic: true, optional: true

  # Validations
  validates :usuario, presence: true
  validates :tipo, presence: true, inclusion: { in: %w[alerta_eta alerta_custo aprovacao_pendente processo_atrasado ocorrencia sistema] }
  validates :titulo, presence: true, length: { maximum: 255 }
  validates :prioridade, inclusion: { in: %w[baixa normal alta urgente] }
  validates :canal, inclusion: { in: %w[in_app email sms push] }
  validates :status, inclusion: { in: %w[pendente enviada lida arquivada] }

  # Scopes
  scope :nao_lidas, -> { where(lida_em: nil).where.not(status: 'arquivada') }
  scope :lidas, -> { where.not(lida_em: nil) }
  scope :pendentes, -> { where(status: 'pendente') }
  scope :enviadas, -> { where(status: 'enviada') }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :por_prioridade, ->(prioridade) { where(prioridade: prioridade) }
  scope :urgentes, -> { where(prioridade: 'urgente') }
  scope :in_app, -> { where(canal: 'in_app') }
  scope :recentes, -> { order(created_at: :desc) }
  scope :do_usuario, ->(usuario_id) { where(usuario_id: usuario_id) }

  # Callbacks
  after_create :enviar_notificacao

  # Tipos
  TIPOS = {
    'alerta_eta' => 'Alerta de ETA',
    'alerta_custo' => 'Alerta de Custo',
    'aprovacao_pendente' => 'Aprovação Pendente',
    'processo_atrasado' => 'Processo Atrasado',
    'ocorrencia' => 'Nova Ocorrência',
    'sistema' => 'Notificação do Sistema'
  }.freeze

  # Prioridades
  PRIORIDADES = {
    'baixa' => 'Baixa',
    'normal' => 'Normal',
    'alta' => 'Alta',
    'urgente' => 'Urgente'
  }.freeze

  # Canais
  CANAIS = {
    'in_app' => 'Aplicativo',
    'email' => 'E-mail',
    'sms' => 'SMS',
    'push' => 'Push'
  }.freeze

  # @return [String] Tipo formatado
  def tipo_nome
    TIPOS[tipo] || tipo&.humanize
  end

  # @return [String] Prioridade formatada
  def prioridade_nome
    PRIORIDADES[prioridade] || prioridade&.humanize
  end

  # @return [String] Canal formatado
  def canal_nome
    CANAIS[canal] || canal&.humanize
  end

  # @return [Boolean] Notificação foi lida?
  def lida?
    lida_em.present?
  end

  # @return [Boolean] Notificação é urgente?
  def urgente?
    prioridade == 'urgente'
  end

  # Marca como lida
  def marcar_como_lida!
    update!(lida_em: Time.current, status: 'lida') unless lida?
  end

  # Arquiva a notificação
  def arquivar!
    update!(status: 'arquivada')
  end

  # Cria notificação para usuário
  #
  # @param usuario [Usuario] Destinatário
  # @param tipo [String] Tipo da notificação
  # @param titulo [String] Título
  # @param mensagem [String] Mensagem (opcional)
  # @param notificavel [ApplicationRecord] Entidade relacionada (opcional)
  # @param prioridade [String] Prioridade (default: normal)
  # @param canal [String] Canal (default: in_app)
  def self.criar_para!(usuario, tipo:, titulo:, mensagem: nil, notificavel: nil, prioridade: 'normal', canal: 'in_app')
    create!(
      usuario: usuario,
      tipo: tipo,
      titulo: titulo,
      mensagem: mensagem,
      notificavel: notificavel,
      prioridade: prioridade,
      canal: canal,
      status: 'pendente'
    )
  end

  # Conta notificações não lidas do usuário
  def self.contar_nao_lidas(usuario_id)
    do_usuario(usuario_id).nao_lidas.count
  end

  private

  def enviar_notificacao
    case canal
    when 'email'
      # TODO: Implementar envio de email
      update_columns(enviada_em: Time.current, status: 'enviada')
    when 'sms'
      # TODO: Implementar envio de SMS
      update_columns(enviada_em: Time.current, status: 'enviada')
    when 'push'
      # TODO: Implementar push notification
      update_columns(enviada_em: Time.current, status: 'enviada')
    else
      update_columns(enviada_em: Time.current, status: 'enviada')
    end
  end
end
