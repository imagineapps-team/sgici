# frozen_string_literal: true

# Concern para multi-tenancy por banco de dados
#
# Troca automaticamente a conexão do banco baseado no tenant
# armazenado na sessão do usuário.
#
# == Aplicações Multi-tenant
#
# Apenas algumas aplicações usam multi-tenancy:
# - EcoEnel (ecoenel): SP, CE
#
# Aplicações single-tenant (Light, etc.) usam o banco padrão.
#
# == Como funciona
#
# 1. No login, o usuário escolhe a regional (SP, CE) - apenas se multi-tenant
# 2. O SessionsController salva o tenant na sessão
# 3. Este concern intercepta cada request e troca a conexão
#
# == Configuração via ENV
#
# MULTI_TENANT_ENABLED=true
# TENANTS_CONFIG=ecoenel_sp:São Paulo:ecoenel,ecoenel_ce:Ceará:ecoenel_ce_local
#
# == Uso
#
#   class ApplicationController < ActionController::Base
#     include TenantSwitchable
#   end
#
module TenantSwitchable
  extend ActiveSupport::Concern

  included do
    around_action :switch_tenant, if: :multi_tenant_app?
    helper_method :current_tenant, :current_tenant_name, :multi_tenant_app?, :available_tenants
  end

  private

  # Verifica se a aplicação atual usa multi-tenancy
  # Delega para TenantConfig
  # @return [Boolean]
  def multi_tenant_app?
    TenantConfig.enabled?
  end

  # Executa o request no contexto do tenant correto
  def switch_tenant(&block)
    tenant = current_tenant

    if tenant.present? && TenantConfig.valid_tenant?(tenant)
      ActiveRecord::Base.connected_to(shard: tenant.to_sym, &block)
    else
      # Fallback para o default
      default = TenantConfig.default_tenant
      ActiveRecord::Base.connected_to(shard: default.to_sym, &block)
    end
  end

  # Retorna o tenant atual da sessão
  # @return [String, nil]
  def current_tenant
    return nil unless multi_tenant_app?

    session[:tenant] || TenantConfig.default_tenant
  end

  # Retorna o nome amigável do tenant atual
  # @return [String, nil]
  def current_tenant_name
    return nil unless multi_tenant_app?

    TenantConfig.label_for(current_tenant)
  end

  # Define o tenant na sessão
  # @param tenant [String] identificador do tenant
  def set_current_tenant(tenant)
    return unless multi_tenant_app?

    if TenantConfig.valid_tenant?(tenant.to_s)
      session[:tenant] = tenant.to_s
    else
      session[:tenant] = TenantConfig.default_tenant
    end
  end

  # Valida se um tenant é válido
  # @param tenant [String]
  # @return [Boolean]
  def valid_tenant?(tenant)
    return true unless multi_tenant_app?

    TenantConfig.valid_tenant?(tenant.to_s)
  end

  # Lista de tenants disponíveis para a aplicação atual
  # @return [Array<Hash>, nil]
  def available_tenants
    return nil unless multi_tenant_app?

    # Converte para formato esperado pelo frontend (value/label)
    TenantConfig.tenants.map { |t| { value: t[:key], label: t[:label] } }
  end
end
