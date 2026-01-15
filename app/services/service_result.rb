# frozen_string_literal: true

# Padrão de retorno para Services
# Permite retornar sucesso ou falha de forma consistente
#
# Uso:
#   result = ServiceResult.success(data)
#   result = ServiceResult.failure(['Erro 1', 'Erro 2'])
#
#   if result.success?
#     # usar result.data
#   else
#     # usar result.errors
#   end
#
class ServiceResult
  attr_reader :data, :errors

  def initialize(success:, data: nil, errors: [])
    @success = success
    @data = data
    @errors = Array(errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # Retorna um resultado de sucesso com dados opcionais
  def self.success(data = nil)
    new(success: true, data: data)
  end

  # Retorna um resultado de falha com erros
  def self.failure(errors)
    new(success: false, errors: errors)
  end

  # Permite acessar dados como hash (para ServiceResult.success(records: x, total: y))
  def [](key)
    return nil unless @data.is_a?(Hash)

    @data[key]
  end
end
