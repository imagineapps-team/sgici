# frozen_string_literal: true

module Messaging
  # Value object que representa o resultado de uma operação de envio
  # Encapsula sucesso/falha, ID externo e detalhes do erro
  #
  # @example Resultado de sucesso
  #   Result.new(success: true, external_id: 'msg-123')
  #
  # @example Resultado de falha
  #   Result.new(success: false, error: 'Connection timeout')
  class Result
    attr_reader :success, :external_id, :error, :raw_response

    # @param success [Boolean] se a operação foi bem sucedida
    # @param external_id [String, nil] ID retornado pelo provider (message_id, etc)
    # @param error [String, nil] mensagem de erro se falhou
    # @param raw_response [Object, nil] resposta bruta do provider (para debug)
    def initialize(success:, external_id: nil, error: nil, raw_response: nil)
      @success = success
      @external_id = external_id
      @error = error
      @raw_response = raw_response
    end

    # @return [Boolean] true se a operação foi bem sucedida
    def success?
      @success == true
    end

    # @return [Boolean] true se a operação falhou
    def failed?
      !success?
    end

    # Representação para logs
    def to_s
      if success?
        "Success (external_id: #{external_id || 'none'})"
      else
        "Failed: #{error}"
      end
    end

    # Converte para hash (útil para serialização)
    def to_h
      {
        success: success,
        external_id: external_id,
        error: error
      }.compact
    end

    # Factory methods para criar resultados
    class << self
      # Cria um resultado de sucesso
      def success(external_id: nil, raw_response: nil)
        new(success: true, external_id: external_id, raw_response: raw_response)
      end

      # Cria um resultado de falha
      def failure(error:, raw_response: nil)
        new(success: false, error: error, raw_response: raw_response)
      end

      # Cria um resultado a partir de uma exception
      def from_exception(exception)
        new(success: false, error: "#{exception.class}: #{exception.message}")
      end
    end
  end
end
