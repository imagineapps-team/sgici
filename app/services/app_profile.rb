# frozen_string_literal: true

# Identifica qual aplicação está rodando
#
# Configurado via ENV:
#   APP_PROFILE=ecoenel_bahia
#   APP_NAME="EcoEnel Bahia"
#
# Uso:
#   AppProfile.current       # => :ecoenel_bahia
#   AppProfile.name          # => "EcoEnel Bahia"
#   AppProfile.is?(:ecoenel_bahia)  # => true
#
class AppProfile
  class << self
    # Retorna o identificador da aplicação atual
    # @return [Symbol]
    def current
      ENV.fetch("APP_PROFILE", "default").to_sym
    end

    # Verifica se é uma aplicação específica
    # @param profile_name [Symbol, String] nome do profile
    # @return [Boolean]
    def is?(profile_name)
      current == profile_name.to_sym
    end

    # Nome amigável da aplicação
    # @return [String]
    def name
      ENV.fetch("APP_NAME", "AVSI EcoEnel")
    end

    # Ambiente Rails
    # @return [String]
    def environment
      Rails.env
    end

    # Metadados da aplicação (para debug/logs)
    # @return [Hash]
    def metadata
      {
        profile: current,
        name: name,
        environment: environment,
        database_host: ENV["DATABASE_HOST"]
      }
    end

    # Para serialização (Inertia props)
    # @return [Hash]
    def to_h
      {
        profile: current,
        name: name,
        environment: environment
      }
    end
  end
end
