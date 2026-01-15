# frozen_string_literal: true

require 'jwt'

# Service para gerenciamento de tokens JWT
# Usado para autenticação da API mobile
#
class JwtService
  ALGORITHM = 'HS256'
  ACCESS_TOKEN_EXPIRY = 24.hours
  REFRESH_TOKEN_EXPIRY = 30.days

  class << self
    # Codifica um payload em um token JWT
    # @param payload [Hash] dados a serem codificados
    # @param expiry [ActiveSupport::Duration] tempo de expiração (default: 24h)
    # @return [String] token JWT
    def encode(payload, expiry: ACCESS_TOKEN_EXPIRY)
      payload = payload.dup.with_indifferent_access
      payload[:exp] = expiry.from_now.to_i
      payload[:iat] = Time.current.to_i
      payload[:jti] = SecureRandom.uuid # ID único para possível revogação

      JWT.encode(payload, secret_key, ALGORITHM)
    end

    # Decodifica um token JWT
    # @param token [String] token JWT
    # @return [HashWithIndifferentAccess, nil] payload decodificado ou nil se inválido
    def decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
      decoded.first.with_indifferent_access
    rescue JWT::ExpiredSignature
      Rails.logger.warn('JWT: Token expirado')
      nil
    rescue JWT::DecodeError => e
      Rails.logger.warn("JWT: Erro ao decodificar token - #{e.message}")
      nil
    end

    # Gera par de tokens (access + refresh) para um usuário
    # @param usuario [Usuario] usuário autenticado
    # @param tenant [String, nil] tenant para multi-tenant (opcional)
    # @return [Hash] com access_token, refresh_token, expires_in, token_type
    def generate_tokens(usuario, tenant: nil)
      access_payload = { sub: usuario.id, type: 'access', login: usuario.login }
      access_payload[:tenant] = tenant if tenant.present?

      access_token = encode(access_payload, expiry: ACCESS_TOKEN_EXPIRY)

      refresh_payload = { sub: usuario.id, type: 'refresh' }
      refresh_payload[:tenant] = tenant if tenant.present?

      refresh_token = encode(refresh_payload, expiry: REFRESH_TOKEN_EXPIRY)

      {
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: ACCESS_TOKEN_EXPIRY.to_i,
        token_type: 'Bearer'
      }
    end

    # Valida se um token é do tipo esperado
    # @param payload [Hash] payload decodificado
    # @param expected_type [String] 'access' ou 'refresh'
    # @return [Boolean]
    def valid_token_type?(payload, expected_type)
      payload.present? && payload['type'] == expected_type
    end

    private

    def secret_key
      # Usa a secret_key_base do Rails ou variável de ambiente
      Rails.application.credentials.secret_key_base ||
        ENV.fetch('SECRET_KEY_BASE') { raise 'SECRET_KEY_BASE não configurado' }
    end
  end
end
