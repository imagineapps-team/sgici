# frozen_string_literal: true

# Evento Logístico - Timeline de eventos do processo de importação
#
# @attr [String] tipo Tipo do evento (embarque, chegada, etc.)
# @attr [DateTime] data_evento Data e hora do evento
# @attr [String] local Local do evento
# @attr [String] fonte Fonte da informação (manual, api)
#
class EventoLogistico < ApplicationRecord
  # Associations
  belongs_to :processo_importacao
  belongs_to :criado_por, class_name: 'Usuario'

  # Validations
  validates :processo_importacao, presence: true
  validates :criado_por, presence: true
  validates :tipo, presence: true, inclusion: { in: %w[embarque transbordo chegada_porto desembaraco liberacao entrega outro] }
  validates :data_evento, presence: true

  # Scopes
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :cronologico, -> { order(data_evento: :asc) }
  scope :recentes, -> { order(data_evento: :desc) }
  scope :do_periodo, ->(inicio, fim) { where(data_evento: inicio..fim) }
  scope :manuais, -> { where(fonte: 'manual') }
  scope :automaticos, -> { where.not(fonte: 'manual') }

  # Callbacks
  after_create :verificar_atualizacao_eta
  after_create :atualizar_status_processo

  # Tipos de evento
  TIPOS = {
    'embarque' => 'Embarque',
    'transbordo' => 'Transbordo',
    'chegada_porto' => 'Chegada ao Porto/Aeroporto',
    'desembaraco' => 'Desembaraço Aduaneiro',
    'liberacao' => 'Liberação da Carga',
    'entrega' => 'Entrega Final',
    'outro' => 'Outro'
  }.freeze

  # Fontes de dados
  FONTES = {
    'manual' => 'Manual',
    'sistema' => 'Sistema (Automático)',
    'api_armador' => 'API Armador',
    'api_cia_aerea' => 'API Cia Aérea',
    'siscomex' => 'Siscomex'
  }.freeze

  # @return [String] Tipo formatado
  def tipo_nome
    TIPOS[tipo] || tipo&.humanize
  end

  # @return [String] Fonte formatada
  def fonte_nome
    FONTES[fonte] || fonte&.humanize || 'Manual'
  end

  # @return [String] Descrição completa do evento
  def descricao_completa
    parts = [tipo_nome]
    parts << "em #{local}" if local.present?
    parts << "(#{data_evento.strftime('%d/%m/%Y %H:%M')})"
    parts.join(' ')
  end

  # @return [Boolean] Evento causou atraso?
  def causou_atraso?
    dias_atraso.present? && dias_atraso.positive?
  end

  # @return [Boolean] ETA foi atualizado neste evento?
  def eta_atualizado?
    eta_anterior.present? && eta_atualizado.present? && eta_anterior != eta_atualizado
  end

  private

  def verificar_atualizacao_eta
    return unless eta_atualizado.present? && eta_anterior.present?

    self.dias_atraso = (eta_atualizado - eta_anterior).to_i if eta_atualizado > eta_anterior
  end

  def atualizar_status_processo
    case tipo
    when 'embarque'
      processo_importacao.update(data_embarque_real: data_evento.to_date) if processo_importacao.data_embarque_real.nil?
    when 'chegada_porto'
      processo_importacao.update(data_chegada_real: data_evento.to_date) if processo_importacao.data_chegada_real.nil?
    when 'desembaraco'
      processo_importacao.update(data_desembaraco: data_evento.to_date) if processo_importacao.data_desembaraco.nil?
    when 'entrega'
      processo_importacao.update(data_entrega_real: data_evento.to_date) if processo_importacao.data_entrega_real.nil?
    end
  end
end
