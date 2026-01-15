# frozen_string_literal: true

module Api
  module V1
    # Controller base para API v1
    # Inclui autenticação JWT obrigatória
    #
    class BaseController < Api::BaseController
      before_action :authenticate_api_user!

      attr_reader :current_api_user

      private

      # Autentica o usuário via token JWT
      def authenticate_api_user!
        token = extract_token_from_header
        return unauthorized_response('Token de autorização não fornecido') unless token

        payload = JwtService.decode(token)
        return unauthorized_response('Token inválido ou expirado') unless payload

        unless JwtService.valid_token_type?(payload, 'access')
          return unauthorized_response('Tipo de token inválido')
        end

        @current_api_user = Usuario.find_by(id: payload['sub'])
        return unauthorized_response('Usuário não encontrado') unless @current_api_user
        return unauthorized_response('Usuário inativo') unless @current_api_user.status == 'A'
      end

      # Extrai o token do header Authorization
      # Formato esperado: "Bearer <token>"
      def extract_token_from_header
        header = request.headers['Authorization']
        return nil unless header&.start_with?('Bearer ')

        header.split(' ').last
      end

      # Resposta de não autorizado
      def unauthorized_response(message)
        render json: {
          success: false,
          error: 'Não autorizado',
          message: message
        }, status: :unauthorized
      end

      # Verifica se o usuário tem acesso a uma ação via MenuPermissionService
      # Pode ser usado como before_action em controllers específicos
      def authorize_api_menu_access
        return if current_api_user&.perfil&.acesso_total?

        unless MenuPermissionService.can_access?(current_api_user, controller_name, action_name)
          json_error('Acesso negado a este recurso', status: :forbidden)
        end
      end
    end
  end
end
