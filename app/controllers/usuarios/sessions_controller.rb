# frozen_string_literal: true

class Usuarios::SessionsController < Devise::SessionsController
  include TenantSwitchable

  skip_before_action :authenticate_usuario!, only: [:new, :create, :destroy]
  skip_around_action :switch_tenant, only: [:new, :create], if: :multi_tenant_app?

  def new
    render inertia: 'auth/login', props: {
      tenants: available_tenants
    }
  end

  def create
    if multi_tenant_app?
      authenticate_with_tenant
    else
      authenticate_single_tenant
    end
  end

  def destroy
    sign_out(resource_name)
    session.delete(:tenant) if multi_tenant_app?
    redirect_to new_usuario_session_path
  end

  private

  # Autenticação para aplicações multi-tenant (EcoEnel)
  def authenticate_with_tenant
    tenant = params[:tenant] || TenantSwitchable::DEFAULT_TENANT

    unless valid_tenant?(tenant)
      redirect_to new_usuario_session_path, inertia: { errors: { tenant: ['Regional inválida'] } }
      return
    end

    # Autentica no banco da regional selecionada
    ActiveRecord::Base.connected_to(shard: tenant.to_sym) do
      self.resource = warden.authenticate(auth_options)

      if resource
        set_current_tenant(tenant)
        sign_in(resource_name, resource)
        redirect_to after_sign_in_path_for(resource)
      else
        redirect_to new_usuario_session_path, inertia: { errors: { login: ['Login ou senha inválidos'] } }
      end
    end
  end

  # Autenticação para aplicações single-tenant (Light)
  def authenticate_single_tenant
    self.resource = warden.authenticate(auth_options)

    if resource
      sign_in(resource_name, resource)
      redirect_to after_sign_in_path_for(resource)
    else
      redirect_to new_usuario_session_path, inertia: { errors: { login: ['Login ou senha inválidos'] } }
    end
  end
end
