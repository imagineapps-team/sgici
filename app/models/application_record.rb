# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Multi-tenancy condicional
  #
  # Apenas aplicações com MULTI_TENANT_ENABLED=true usam shards.
  # - EcoEnel: usa shards (ecoenel_sp, ecoenel_ce)
  # - Light: usa apenas primary (single-tenant)
  #
  # O tenant é selecionado no login e armazenado na sessão.
  # O concern TenantSwitchable troca a conexão em cada request.
  if ENV["MULTI_TENANT_ENABLED"] == "true"
    connects_to shards: {
      default: { writing: :primary },
      ecoenel_sp: { writing: :ecoenel_sp },
      ecoenel_ce: { writing: :ecoenel_ce }
    }
  end
end
