# frozen_string_literal: true

module Messaging
  # Facade de alto nível para envio de mensagens
  # Fornece uma interface simples para enfileirar emails e SMS
  #
  # @example Enviar email usando um Mailer existente
  #   Messaging::Messenger.send_email(
  #     to: 'user@example.com',
  #     mailer_class: 'ReciboMailer',
  #     mailer_method: 'recibo_individual',
  #     mailer_args: [{ reciclagem: r, destinatario: email }],
  #     deliverable: r
  #   )
  #
  # @example Enviar email simples
  #   Messaging::Messenger.send_email(
  #     to: 'user@example.com',
  #     subject: 'Assunto',
  #     body: 'Corpo do email'
  #   )
  #
  # @example Enviar SMS
  #   Messaging::Messenger.send_sms(
  #     to: '11999999999',
  #     message: 'Sua mensagem',
  #     deliverable: reciclagem
  #   )
  class Messenger
    class << self
      # Enfileira envio de email
      #
      # @param to [String] email do destinatário
      # @param subject [String, nil] assunto (para email simples)
      # @param body [String, nil] corpo do email (para email simples)
      # @param mailer_class [String, nil] classe do Mailer (ex: 'ReciboMailer')
      # @param mailer_method [String, Symbol, nil] método do Mailer (ex: 'recibo_individual')
      # @param mailer_args [Array, nil] argumentos para o método do Mailer
      # @param deliverable [ActiveRecord::Base, nil] objeto relacionado para tracking
      # @param provider [Symbol, nil] provider específico (default: :aws_ses)
      # @return [MessageDelivery] registro criado
      def send_email(to:, subject: nil, body: nil, mailer_class: nil, mailer_method: nil, mailer_args: nil, deliverable: nil, provider: nil)
        payload = if mailer_class.present?
                    {
                      mailer_class: mailer_class.to_s,
                      mailer_method: mailer_method.to_s,
                      mailer_args: mailer_args || []
                    }
                  else
                    {
                      subject: subject,
                      body: body
                    }
                  end

        MessageDelivery.enqueue(
          channel: :email,
          recipient: to,
          payload: payload,
          deliverable: deliverable,
          provider: provider
        )
      end

      # Enfileira envio de SMS
      #
      # @param to [String] número do celular
      # @param message [String] mensagem (máximo 160 caracteres)
      # @param deliverable [ActiveRecord::Base, nil] objeto relacionado para tracking
      # @param provider [Symbol, nil] provider específico (default: :zenvia)
      # @return [MessageDelivery] registro criado
      def send_sms(to:, message:, deliverable: nil, provider: nil)
        MessageDelivery.enqueue(
          channel: :sms,
          recipient: to,
          payload: { message: message },
          deliverable: deliverable,
          provider: provider
        )
      end

      # Envia email imediatamente (síncrono) - USE COM CUIDADO
      # Útil para casos onde precisa do resultado imediato
      #
      # @return [Messaging::Result] resultado do envio
      def send_email_now(to:, subject: nil, body: nil, mailer_class: nil, mailer_method: nil, mailer_args: nil)
        payload = if mailer_class.present?
                    { mailer_class: mailer_class.to_s, mailer_method: mailer_method.to_s, mailer_args: mailer_args || [] }
                  else
                    { subject: subject, body: body }
                  end

        adapter = AdapterResolver.resolve(:email)
        adapter.deliver(recipient: to, payload: payload)
      end

      # Envia SMS imediatamente (síncrono) - USE COM CUIDADO
      #
      # @return [Messaging::Result] resultado do envio
      def send_sms_now(to:, message:)
        adapter = AdapterResolver.resolve(:sms)
        adapter.deliver(recipient: to, payload: { message: message })
      end

      # Verifica se o canal de email está configurado
      def email_configured?
        AdapterResolver.configured?(:email)
      end

      # Verifica se o canal de SMS está configurado
      def sms_configured?
        AdapterResolver.configured?(:sms)
      end
    end
  end
end
