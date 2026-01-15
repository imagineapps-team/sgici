# frozen_string_literal: true

# Model para rastreamento de envio de mensagens (email, SMS, push)
# Armazena histórico completo de todas as tentativas de envio
class MessageDelivery < ApplicationRecord
  # Canais suportados
  CHANNELS = %w[email sms push].freeze

  # Status possíveis
  STATUSES = %w[pending processing delivered failed].freeze

  # Associação polimórfica - permite vincular a qualquer model
  # Ex: deliverable_type: 'Reciclagem', deliverable_id: 123
  belongs_to :deliverable, polymorphic: true, optional: true

  # Validações
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :provider, presence: true
  validates :recipient, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes por status
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }

  # Scopes por canal
  scope :emails, -> { where(channel: 'email') }
  scope :sms, -> { where(channel: 'sms') }
  scope :push, -> { where(channel: 'push') }

  # Scopes úteis
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Time.current.all_day) }

  # Status helpers
  def pending?
    status == 'pending'
  end

  def processing?
    status == 'processing'
  end

  def delivered?
    status == 'delivered'
  end

  def failed?
    status == 'failed'
  end

  # Pode ser reenviado?
  def retriable?
    failed? && attempts < 5
  end

  # Marca como em processamento
  def mark_as_processing!
    update!(
      status: 'processing',
      attempts: attempts + 1
    )
  end

  # Marca como entregue com sucesso
  def mark_as_delivered!(external_id: nil)
    update!(
      status: 'delivered',
      external_id: external_id,
      delivered_at: Time.current,
      error_message: nil
    )
  end

  # Marca como falha
  def mark_as_failed!(error:)
    update!(
      status: 'failed',
      error_message: error,
      failed_at: Time.current
    )
  end

  # Registra erro sem marcar como falha definitiva (para retries)
  def record_error!(error:)
    update!(error_message: error)
  end

  # Payload formatado para o adapter
  def payload_for_adapter
    base_payload = {
      subject: subject,
      message: body
    }

    # Merge com metadata (pode conter mailer_class, mailer_method, etc)
    base_payload.merge(metadata.symbolize_keys)
  end

  # Factory method para criar e enfileirar uma mensagem
  # @param channel [Symbol] :email, :sms, :push
  # @param recipient [String] email ou telefone
  # @param payload [Hash] dados da mensagem
  # @param deliverable [ActiveRecord::Base] objeto relacionado (opcional)
  # @param provider [Symbol] provider específico (opcional, usa default)
  # @return [MessageDelivery] registro criado
  def self.enqueue(channel:, recipient:, payload:, deliverable: nil, provider: nil)
    # Resolve provider padrão se não especificado
    provider ||= Messaging::AdapterResolver.default_provider_for(channel)

    delivery = create!(
      channel: channel.to_s,
      provider: provider.to_s,
      recipient: recipient,
      subject: payload[:subject],
      body: payload[:body] || payload[:message],
      metadata: payload.except(:subject, :body, :message),
      deliverable: deliverable,
      status: 'pending'
    )

    # Enfileira o job para processamento em background
    SendMessageJob.perform_later(delivery.id)

    delivery
  end

  # Reenvia uma mensagem que falhou
  def retry!
    return unless retriable?

    update!(status: 'pending', error_message: nil, failed_at: nil)
    SendMessageJob.perform_later(id)
  end
end
