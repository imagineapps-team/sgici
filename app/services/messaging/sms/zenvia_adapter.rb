# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'

module Messaging
  module Sms
    # Adapter para envio de SMS via Zenvia API
    # Documentação: https://docs.zenvia.com/
    #
    # @example Envio de SMS
    #   adapter.deliver(
    #     recipient: '11999999999',
    #     payload: { message: 'Sua mensagem aqui' }
    #   )
    #
    # Configuração via ENV:
    # - ZENVIA_SMS_ACCOUNT: conta Zenvia
    # - ZENVIA_SMS_PASSWORD: senha Zenvia
    # - ZENVIA_AGGREGATE_ID: ID do agregado (opcional)
    class ZenviaAdapter < BaseAdapter
      BASE_URL = 'https://api-rest.zenvia.com/services/send-sms'
      SMS_MAX_LENGTH = 160
      SMS_SENDER = 'ECOENEL'

      def initialize
        @account = ENV.fetch('ZENVIA_SMS_ACCOUNT', nil)
        @password = ENV.fetch('ZENVIA_SMS_PASSWORD', nil)
        @aggregate_id = ENV.fetch('ZENVIA_AGGREGATE_ID', '1240363')
      end

      def deliver(recipient:, payload:)
        validate_configuration!

        numero = format_phone(recipient)
        validate_phone!(numero)

        mensagem = payload[:message].to_s.truncate(SMS_MAX_LENGTH)

        log_info "Enviando SMS para #{numero[0..5]}***"

        response = send_sms(numero, mensagem)

        if response[:success]
          log_info "SMS enviado com sucesso (id: #{response[:id]})"
          Result.success(external_id: response[:id])
        else
          log_error "Falha ao enviar SMS: #{response[:error]}"
          Result.failure(error: response[:error])
        end
      rescue StandardError => e
        log_error "Erro inesperado ao enviar SMS", error: e
        Result.failure(error: e.message)
      end

      def configured?
        @account.present? && @password.present?
      end

      def provider_name
        'zenvia'
      end

      private

      # Formata número para padrão Zenvia (55 + DDD + número)
      def format_phone(phone)
        numero = phone.to_s.gsub(/\D/, '')
        numero = "55#{numero}" unless numero.start_with?('55')
        numero
      end

      # Valida formato do número
      def validate_phone!(numero)
        return if numero.match?(/^55\d{10,11}$/)

        raise DeliveryError, "Número de celular inválido: #{numero}"
      end

      # Envia SMS via API Zenvia
      def send_sms(numero, mensagem)
        message_id = SecureRandom.uuid
        payload = build_payload(numero, mensagem, message_id)
        response = http_request(payload)

        process_response(response, message_id)
      end

      def build_payload(numero, mensagem, message_id)
        {
          sendSmsRequest: {
            from: SMS_SENDER,
            to: numero,
            msg: mensagem,
            callbackOption: 'NONE',
            id: message_id,
            aggregateId: @aggregate_id
          }
        }
      end

      def http_request(payload)
        uri = URI.parse(BASE_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 30

        request = Net::HTTP::Post.new(uri.path)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request['Authorization'] = authorization_header
        request.body = payload.to_json

        http.request(request)
      end

      def authorization_header
        "Basic #{Base64.strict_encode64("#{@account}:#{@password}")}"
      end

      def process_response(response, message_id)
        body = JSON.parse(response.body)
        status_code = body.dig('sendSmsResponse', 'statusCode')

        # Códigos de sucesso da Zenvia
        success_codes = %w[00 01 02 03]

        if success_codes.include?(status_code)
          { success: true, id: message_id }
        else
          detail = body.dig('sendSmsResponse', 'detailDescription') || "Status code: #{status_code}"
          { success: false, error: detail }
        end
      rescue JSON::ParserError => e
        { success: false, error: "Resposta inválida da API: #{e.message}" }
      end
    end
  end
end
