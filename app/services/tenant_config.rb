# frozen_string_literal: true

# Configuração dinâmica de tenants via ENV
#
# == Configuração
#
# ENV vars:
#   MULTI_TENANT_ENABLED=true
#   TENANTS_CONFIG=ecoenel_sp:São Paulo:ecoenel,ecoenel_ce:Ceará:ecoenel_ce_local
#
# Formato TENANTS_CONFIG:
#   key:label:database,key:label:database,...
#
# == Uso
#
#   TenantConfig.enabled?          # => true
#   TenantConfig.tenants           # => [{ key: 'ecoenel_sp', label: 'São Paulo', database: 'ecoenel' }, ...]
#   TenantConfig.valid_tenant?('ecoenel_sp')  # => true
#   TenantConfig.database_for('ecoenel_sp')   # => 'ecoenel'
#
class TenantConfig
  class << self
    # Verifica se multi-tenancy está habilitado
    # @return [Boolean]
    def enabled?
      ENV["MULTI_TENANT_ENABLED"] == "true"
    end

    # Lista de tenants configurados
    # @return [Array<Hash>] array de { key:, label:, database: }
    def tenants
      return [] unless enabled?

      @tenants ||= parse_tenants_config
    end

    # Lista de tenants para resposta da API (sem database)
    # @return [Array<Hash>] array de { key:, label: }
    def tenants_for_api
      tenants.map { |t| { key: t[:key], label: t[:label] } }
    end

    # Chaves válidas de tenants
    # @return [Array<String>]
    def valid_keys
      tenants.map { |t| t[:key] }
    end

    # Verifica se um tenant é válido
    # @param key [String]
    # @return [Boolean]
    def valid_tenant?(key)
      valid_keys.include?(key.to_s)
    end

    # Retorna o database de um tenant
    # @param key [String]
    # @return [String, nil]
    def database_for(key)
      tenant = tenants.find { |t| t[:key] == key.to_s }
      tenant&.dig(:database)
    end

    # Retorna o label de um tenant
    # @param key [String]
    # @return [String, nil]
    def label_for(key)
      tenant = tenants.find { |t| t[:key] == key.to_s }
      tenant&.dig(:label)
    end

    # Tenant padrão (primeiro da lista)
    # @return [String, nil]
    def default_tenant
      tenants.first&.dig(:key)
    end

    # Retorna configuração completa para API /config
    # @return [Hash]
    def to_api_response
      {
        appProfile: AppProfile.current,
        appName: AppProfile.name,
        multiTenant: enabled?,
        tenants: tenants_for_api,
        branding: Branding.to_h
      }
    end

    # Limpa cache (útil para testes)
    def reset!
      @tenants = nil
    end

    private

    # Parse da ENV TENANTS_CONFIG
    # Formato: key:label:database,key:label:database
    def parse_tenants_config
      config = ENV.fetch("TENANTS_CONFIG", "")
      return [] if config.blank?

      config.split(",").map do |tenant_str|
        parts = tenant_str.strip.split(":")
        next nil if parts.length < 2

        {
          key: parts[0].strip,
          label: parts[1].strip,
          database: parts[2]&.strip || parts[0].strip
        }
      end.compact
    end
  end
end
