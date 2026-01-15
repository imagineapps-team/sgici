# frozen_string_literal: true

# Job para processamento de envio de mensagens em background
# Processa MessageDelivery usando o adapter apropriado
#
# @example Enfileirar manualmente
#   SendMessageJob.perform_later(message_delivery.id)
#
# Normalmente é chamado automaticamente via MessageDelivery.enqueue
class SendMessageJob < ApplicationJob
  queue_as :messaging

  # Retry com backoff exponencial
  # Tentativas: imediato, 3s, 18s, 83s, ~6min (5 tentativas)
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Não faz retry se o adapter não está configurado
  discard_on Messaging::BaseAdapter::ConfigurationError do |job, error|
    delivery = MessageDelivery.find_by(id: job.arguments.first)
    delivery&.mark_as_failed!(error: error.message)
    Rails.logger.error "[SendMessageJob] Descartado: #{error.message}"
  end

  # Executa o envio da mensagem
  #
  # @param message_delivery_id [Integer] ID do MessageDelivery
  def perform(message_delivery_id)
    delivery = MessageDelivery.find(message_delivery_id)

    # Evita reprocessar mensagens já finalizadas
    return if delivery.delivered? || delivery.failed?

    # Marca como em processamento
    delivery.mark_as_processing!

    # Resolve o adapter apropriado
    adapter = Messaging::AdapterResolver.resolve(delivery.channel, delivery.provider)

    # Executa o envio
    result = adapter.deliver(
      recipient: delivery.recipient,
      payload: delivery.payload_for_adapter
    )

    # Atualiza status baseado no resultado
    if result.success?
      delivery.mark_as_delivered!(external_id: result.external_id)
      log_success(delivery, result)
    else
      handle_failure(delivery, result)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[SendMessageJob] MessageDelivery ##{message_delivery_id} não encontrado"
  rescue StandardError => e
    # Registra o erro mas deixa o retry_on lidar com a exception
    delivery&.record_error!(error: e.message)
    Rails.logger.error "[SendMessageJob] Erro: #{e.message} (delivery: #{message_delivery_id})"
    raise
  end

  private

  def log_success(delivery, result)
    Rails.logger.info(
      "[SendMessageJob] Sucesso: #{delivery.channel}/#{delivery.provider} " \
      "-> #{delivery.recipient[0..10]}... (external_id: #{result.external_id})"
    )
  end

  def handle_failure(delivery, result)
    # Se ainda tem tentativas disponíveis, deixa o retry_on fazer o trabalho
    if delivery.attempts < 5
      delivery.record_error!(error: result.error)
      raise Messaging::BaseAdapter::DeliveryError, result.error
    else
      # Marca como falha definitiva
      delivery.mark_as_failed!(error: result.error)
      Rails.logger.error(
        "[SendMessageJob] Falha definitiva: #{delivery.channel}/#{delivery.provider} " \
        "-> #{delivery.recipient} - #{result.error}"
      )
    end
  end
end
