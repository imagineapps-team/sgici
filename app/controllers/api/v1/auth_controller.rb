# frozen_string_literal: true

module Api
  module V1
    # Controller de autenticação para API
    # Endpoints: login, refresh, me, logout
    #
    # == Multi-tenancy
    #
    # Quando MULTI_TENANT_ENABLED=true, o login aceita um parâmetro `tenant`
    # que é armazenado no JWT. O BaseController usa esse tenant para
    # conectar ao banco correto em cada request.
    #
    class AuthController < Api::BaseController
      # Login e refresh não requerem autenticação prévia
      skip_before_action :authenticate_api_user!, only: [:login, :refresh], raise: false

      # POST /api/v1/auth/login
      # Body: { login: "usuario", password: "senha", tenant: "ecoenel_sp" }
      # O tenant é obrigatório apenas se MULTI_TENANT_ENABLED=true
      def login
        login_param = params[:login]&.to_s&.strip&.downcase
        password_param = params[:password]&.to_s
        tenant_param = params[:tenant]&.to_s&.strip

        if login_param.blank? || password_param.blank?
          return json_error('Login e senha são obrigatórios', status: :bad_request)
        end

        # Valida tenant se multi-tenant habilitado
        if TenantConfig.enabled?
          if tenant_param.blank?
            return json_error('Tenant é obrigatório', status: :bad_request)
          end

          unless TenantConfig.valid_tenant?(tenant_param)
            return json_error('Tenant inválido', status: :bad_request)
          end
        end

        # Executa no contexto do tenant (se multi-tenant)
        execute_in_tenant(tenant_param) do
          usuario = Usuario.find_by(login: login_param)

          unless usuario&.valid_password?(password_param)
            return json_error('Login ou senha inválidos', status: :unauthorized)
          end

          unless usuario.status == 'A'
            return json_error('Usuário inativo', status: :unauthorized)
          end

          # Inclui tenant no token se multi-tenant
          tenant_for_token = TenantConfig.enabled? ? tenant_param : nil
          tokens = JwtService.generate_tokens(usuario, tenant: tenant_for_token)

          render json: {
            success: true,
            data: {
              user: user_json(usuario, tenant_param),
              tokens: tokens
            }
          }
        end
      end

      # POST /api/v1/auth/refresh
      # Body: { refresh_token: "eyJ..." }
      def refresh
        refresh_token = params[:refresh_token]

        if refresh_token.blank?
          return json_error('Refresh token é obrigatório', status: :bad_request)
        end

        payload = JwtService.decode(refresh_token)

        unless payload && JwtService.valid_token_type?(payload, 'refresh')
          return json_error('Refresh token inválido ou expirado', status: :unauthorized)
        end

        # Extrai tenant do token original
        tenant_from_token = payload['tenant']

        execute_in_tenant(tenant_from_token) do
          usuario = Usuario.find_by(id: payload['sub'])

          unless usuario&.status == 'A'
            return json_error('Usuário não encontrado ou inativo', status: :unauthorized)
          end

          tokens = JwtService.generate_tokens(usuario, tenant: tenant_from_token)

          render json: {
            success: true,
            data: { tokens: tokens }
          }
        end
      end

      # GET /api/v1/auth/me
      # Header: Authorization: Bearer <access_token>
      def me
        render json: {
          success: true,
          data: { user: user_json(current_api_user, current_tenant) }
        }
      end

      # POST /api/v1/auth/logout
      # Em uma implementação mais robusta, o token seria adicionado a uma blacklist
      def logout
        # TODO: Implementar blacklist de tokens se necessário
        render json: {
          success: true,
          message: 'Logout realizado com sucesso'
        }
      end

      private

      # Serializa usuário para resposta JSON
      def user_json(usuario, tenant = nil)
        response = {
          id: usuario.id,
          login: usuario.login,
          nome: usuario.nome,
          email: usuario.email,
          perfil: perfil_json(usuario.perfil),
          allowedPaths: MenuPermissionService.allowed_paths_for(usuario)
        }

        # Inclui tenant se multi-tenant
        if TenantConfig.enabled? && tenant.present?
          response[:tenant] = tenant
          response[:tenantLabel] = TenantConfig.label_for(tenant)
        end

        response
      end

      def perfil_json(perfil)
        return nil unless perfil

        {
          id: perfil.id,
          nome: perfil.nome,
          acessoTotal: perfil.acesso_total?
        }
      end

      # Executa bloco no contexto do tenant
      # @param tenant [String, nil] identificador do tenant
      def execute_in_tenant(tenant, &block)
        if TenantConfig.enabled? && tenant.present? && TenantConfig.valid_tenant?(tenant)
          ActiveRecord::Base.connected_to(shard: tenant.to_sym, &block)
        else
          yield
        end
      end

      # Autenticação manual para /me e /logout
      def authenticate_api_user!
        token = extract_token_from_header
        return unauthorized_response('Token não fornecido') unless token

        payload = JwtService.decode(token)
        return unauthorized_response('Token inválido') unless payload

        # Extrai tenant do token e salva para uso posterior
        @current_tenant = payload['tenant']

        # Busca usuário no contexto do tenant
        execute_in_tenant(@current_tenant) do
          @current_api_user = Usuario.find_by(id: payload['sub'])
          return unauthorized_response('Usuário não encontrado') unless @current_api_user
        end
      end

      def extract_token_from_header
        header = request.headers['Authorization']
        return nil unless header&.start_with?('Bearer ')

        header.split(' ').last
      end

      def unauthorized_response(message)
        render json: { success: false, error: message }, status: :unauthorized
      end

      attr_reader :current_api_user, :current_tenant
    end
  end
end
