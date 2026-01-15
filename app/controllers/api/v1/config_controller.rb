# frozen_string_literal: true

module Api
  module V1
    # Controller de configuração da aplicação
    #
    # Retorna informações sobre a aplicação para o mobile:
    # - Profile (ecoenel, light)
    # - Nome da app
    # - Se é multi-tenant
    # - Lista de tenants disponíveis
    # - Branding (cores, etc)
    #
    # == Uso no Mobile
    #
    # O app mobile deve:
    # 1. Buscar esse endpoint no boot
    # 2. Cachear no localStorage
    # 3. Usar fallback se offline
    #
    class ConfigController < Api::BaseController
      # Não requer autenticação
      skip_before_action :authenticate_api_user!, only: [:show], raise: false

      # GET /api/v1/config
      def show
        render json: {
          success: true,
          data: TenantConfig.to_api_response
        }
      end
    end
  end
end
