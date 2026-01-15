# frozen_string_literal: true

class MenuPermissionService
  def self.allowed_paths_for(usuario)
    return nil if usuario.perfil&.acesso_total? # nil = tudo permitido

    Menu.joins(:perfils)
        .where(perfils: { id: usuario.perfil_id }, ativo: true)
        .pluck(:controller, :action)
        .map { |c, a| a.present? ? "/#{c}/#{a}" : "/#{c}" }
  end

  def self.can_access?(usuario, controller, _action = nil)
    return true if usuario.perfil&.acesso_total?

    Menu.joins(:perfils)
        .where(perfils: { id: usuario.perfil_id }, ativo: true)
        .where(controller: controller)
        .exists?
  end
end
