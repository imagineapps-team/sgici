# frozen_string_literal: true

module Messaging
  module Email
    # Adapter para envio de emails via AWS SES
    # Utiliza Action Mailer configurado com delivery_method :ses
    #
    # @example Envio via mailer existente
    #   adapter.deliver(
    #     recipient: 'user@example.com',
    #     payload: {
    #       mailer_class: 'ReciboMailer',
    #       mailer_method: 'recibo_individual',
    #       mailer_args: [{ reciclagem: reciclagem, destinatario: email }]
    #     }
    #   )
    #
    # @example Envio de email simples
    #   adapter.deliver(
    #     recipient: 'user@example.com',
    #     payload: {
    #       subject: 'Assunto',
    #       body: 'Corpo do email'
    #     }
    #   )
    class AwsSesAdapter < BaseAdapter
      def deliver(recipient:, payload:)
        validate_configuration!

        log_info "Enviando email para #{recipient}"

        response = if payload[:mailer_class]
                     deliver_via_mailer(payload)
                   else
                     deliver_simple_email(recipient, payload)
                   end

        log_info "Email enviado com sucesso (message_id: #{response&.message_id})"

        Result.success(
          external_id: response&.message_id,
          raw_response: response
        )
      rescue StandardError => e
        log_error "Falha ao enviar email para #{recipient}", error: e
        Result.failure(error: e.message)
      end

      def configured?
        ENV['AWS_SES_KEY'].present? && ENV['AWS_SES_SECRET'].present?
      end

      def provider_name
        'aws_ses'
      end

      private

      # Envia email usando um Mailer existente do Rails
      def deliver_via_mailer(payload)
        mailer_class = payload[:mailer_class].constantize
        mailer_method = payload[:mailer_method].to_sym
        mailer_args = payload[:mailer_args] || []

        log_debug "Usando #{mailer_class}##{mailer_method}"

        # Se o único argumento for um hash, usa keyword arguments (Ruby 3+)
        # .symbolize_keys necessário porque JSONB serializa chaves como strings
        if mailer_args.size == 1 && mailer_args.first.is_a?(Hash)
          mailer_class.public_send(mailer_method, **mailer_args.first.symbolize_keys).deliver_now
        else
          mailer_class.public_send(mailer_method, *mailer_args).deliver_now
        end
      end

      # Envia email simples usando ApplicationMailer
      def deliver_simple_email(recipient, payload)
        subject = payload[:subject]
        body = payload[:message] || payload[:body]

        log_debug "Enviando email simples: #{subject}"

        # Usa um mailer genérico para emails simples
        GenericMailer.simple_email(
          to: recipient,
          subject: subject,
          body: body
        ).deliver_now
      end
    end
  end
end
