# frozen_string_literal: true

module Api
  # Controller base para toda a API
  # Herda de ActionController::API (sem views, sessão, CSRF)
  #
  class BaseController < ActionController::API
    include Pundit::Authorization

    # Tratamento padrão de erros
    rescue_from ActiveRecord::RecordNotFound do |e|
      json_error('Registro não encontrado', status: :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      json_error('Validação falhou', status: :unprocessable_entity, errors: e.record.errors.as_json)
    end

    rescue_from ActionController::ParameterMissing do |e|
      json_error("Parâmetro obrigatório: #{e.param}", status: :bad_request)
    end

    rescue_from Pundit::NotAuthorizedError do |_e|
      json_error('Acesso negado', status: :forbidden)
    end

    protected

    # Resposta de sucesso padronizada
    # @param data [Object] dados a serem retornados
    # @param status [Symbol] status HTTP (default: :ok)
    # @param meta [Hash, nil] metadados adicionais (paginação, etc)
    def json_success(data, status: :ok, meta: nil)
      response = { success: true, data: data }
      response[:meta] = meta if meta.present?
      render json: response, status: status
    end

    # Resposta de erro padronizada
    # @param message [String] mensagem de erro
    # @param status [Symbol] status HTTP (default: :unprocessable_entity)
    # @param errors [Array, Hash, nil] detalhes dos erros
    def json_error(message, status: :unprocessable_entity, errors: nil)
      response = { success: false, error: message }
      response[:errors] = errors if errors.present?
      render json: response, status: status
    end

    # Resposta paginada padronizada
    # @param records [ActiveRecord::Relation] registros paginados
    # @param serializer [Class, Proc] serializador para transformar registros
    # @param meta [Hash] metadados adicionais
    def json_paginated(records, serializer:, meta: {})
      data = records.map do |record|
        serializer.is_a?(Proc) ? serializer.call(record) : serializer.call(record)
      end

      render json: {
        success: true,
        data: data,
        meta: pagination_meta(records).merge(meta)
      }
    end

    private

    def pagination_meta(records)
      if records.respond_to?(:current_page)
        {
          current_page: records.current_page,
          total_pages: records.total_pages,
          total_count: records.total_count,
          per_page: records.limit_value
        }
      else
        {}
      end
    end
  end
end
