# frozen_string_literal: true

module Messaging
  # Classe base abstrata para adapters de envio de mensagens
  # Todos os adapters (Email, SMS, Push) devem herdar desta classe
  #
  # @example Implementação de um adapter
  #   class MyAdapter < Messaging::BaseAdapter
  #     def deliver(recipient:, payload:)
  #       # lógica de envio
  #       Result.new(success: true, external_id: 'xxx')
  #     end
  #
  #     def configured?
  #       ENV['MY_API_KEY'].present?
  #     end
  #
  #     def provider_name
  #       'my_provider'
  #     end
  #   end
  class BaseAdapter
    # Erro lançado quando há falha na entrega
    class DeliveryError < StandardError; end

    # Erro lançado quando o adapter não está configurado
    class ConfigurationError < StandardError; end

    # Envia uma mensagem
    #
    # @param recipient [String] destinatário (email, telefone, etc)
    # @param payload [Hash] dados da mensagem (subject, body, etc)
    # @return [Messaging::Result] resultado do envio
    # @raise [NotImplementedError] se não implementado pela subclasse
    def deliver(recipient:, payload:)
      raise NotImplementedError, "#{self.class} must implement #deliver"
    end

    # Verifica se o adapter está configurado corretamente
    #
    # @return [Boolean] true se configurado
    # @raise [NotImplementedError] se não implementado pela subclasse
    def configured?
      raise NotImplementedError, "#{self.class} must implement #configured?"
    end

    # Nome do provider (usado para identificação e logging)
    #
    # @return [String] nome do provider (ex: 'aws_ses', 'zenvia')
    # @raise [NotImplementedError] se não implementado pela subclasse
    def provider_name
      raise NotImplementedError, "#{self.class} must implement #provider_name"
    end

    protected

    # Valida se o adapter está configurado, lança erro se não
    #
    # @raise [ConfigurationError] se não configurado
    def validate_configuration!
      return if configured?

      raise ConfigurationError, "#{self.class} is not properly configured"
    end

    # Log de debug
    def log_debug(message)
      Rails.logger.debug { "[Messaging::#{provider_name}] #{message}" }
    end

    # Log de info
    def log_info(message)
      Rails.logger.info "[Messaging::#{provider_name}] #{message}"
    end

    # Log de erro
    def log_error(message, error: nil)
      full_message = "[Messaging::#{provider_name}] #{message}"
      full_message += " - #{error.class}: #{error.message}" if error
      Rails.logger.error full_message
    end
  end
end
