class ApplicationController < ActionController::Base
  include InertiaRails::Controller
  include Pundit::Authorization
  include TenantSwitchable

  before_action :authenticate_usuario!
  before_action :set_csrf_cookie
  before_action :authorize_menu_access

  inertia_share flash: -> { flash.to_hash }
  inertia_share do
    shared = {
      # Branding e identidade da aplicação (sempre disponível)
      branding: Branding.to_h,
      appProfile: AppProfile.to_h,

      # Multi-tenancy: regional atual
      tenant: current_tenant,
      tenantName: current_tenant_name,

      # Feature flags via Flipper (features habilitadas globalmente)
      features: enabled_features_hash
    }

    if current_usuario
      shared[:allowedPaths] = MenuPermissionService.allowed_paths_for(current_usuario)
    end

    shared
  end

  # Tratamento global de erros
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def record_not_found
    redirect_back fallback_location: root_path, alert: 'Registro não encontrado.'
  end

  def record_invalid(exception)
    redirect_back fallback_location: root_path, alert: exception.record.errors.full_messages.join(', ')
  end

  def parameter_missing(exception)
    redirect_back fallback_location: root_path, alert: 'Parâmetros inválidos.'
  end

  # Define cookie XSRF-TOKEN para o Axios ler automaticamente
  def set_csrf_cookie
    cookies['XSRF-TOKEN'] = {
      value: form_authenticity_token,
      same_site: :strict
    }
  end

  # Aceita o token via header X-XSRF-TOKEN (enviado pelo Axios)
  def request_authenticity_tokens
    super + [request.headers['X-XSRF-TOKEN']].compact
  end

  def user_not_authorized
    flash[:alert] = 'Você não tem permissão para acessar esta página.'
    redirect_to root_path
  end

  def authorize_menu_access
    return if skip_authorization?
    return if current_usuario&.perfil&.acesso_total?

    unless MenuPermissionService.can_access?(current_usuario, controller_name, action_name)
      flash[:alert] = 'Você não tem permissão para acessar esta página.'
      redirect_to root_path
    end
  end

  def skip_authorization?
    # Controllers que não precisam de verificação de menu
    %w[sessions dashboard rails].include?(controller_name)
  end

  # Retorna hash de features habilitadas via Flipper
  # @return [Hash<String, Boolean>]
  def enabled_features_hash
    return {} unless defined?(Flipper) && Flipper.respond_to?(:features)

    Flipper.features
           .select { |f| Flipper.enabled?(f.key) }
           .to_h { |f| [f.key.to_s, true] }
  rescue StandardError => e
    Rails.logger.warn("Flipper not available: #{e.message}")
    {}
  end
end
