# frozen_string_literal: true

class PermissoesMenuController < ApplicationController
  before_action :set_perfil, only: [:edit, :update]

  def index
    @perfis = Perfil.ativos.ordered

    render inertia: 'permissoes_menu/PermissoesMenuIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      perfis: @perfis.map { |p| perfil_json(p) }
    }
  end

  def edit
    @menus = Menu.ativos.raiz.ordered.includes(:submenus)
    @menu_ids_permitidos = @perfil.menu_ids

    render inertia: 'permissoes_menu/PermissoesMenuForm', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      perfil: perfil_json(@perfil),
      menus: build_menu_tree(@menus),
      menuIdsPermitidos: @menu_ids_permitidos
    }
  end

  def update
    menu_ids = params[:menu_ids] || []

    begin
      @perfil.menu_ids = menu_ids
      redirect_to permissoes_menu_index_path, notice: "Permissões do perfil #{@perfil.nome} atualizadas com sucesso."
    rescue StandardError => e
      redirect_to edit_permissoes_menu_path(@perfil), alert: "Erro ao salvar: #{e.message}"
    end
  end

  private

  def set_perfil
    @perfil = Perfil.find(params[:id])
  end

  def perfil_json(perfil)
    {
      id: perfil.id,
      nome: perfil.nome,
      status: perfil.status,
      statusLabel: perfil.status_label,
      acessoTotal: perfil.acesso_total?,
      menusCount: perfil.menus.where(ativo: true).count
    }
  end

  def build_menu_tree(menus)
    menus.map do |menu|
      {
        id: menu.id,
        nome: menu.nome,
        controller: menu.controller,
        action: menu.action,
        ordem: menu.ordem,
        children: menu.submenus.ativos.ordered.map do |submenu|
          {
            id: submenu.id,
            nome: submenu.nome,
            controller: submenu.controller,
            action: submenu.action,
            ordem: submenu.ordem,
            children: submenu.submenus.ativos.ordered.map do |sub2|
              {
                id: sub2.id,
                nome: sub2.nome,
                controller: sub2.controller,
                action: sub2.action,
                ordem: sub2.ordem,
                children: []
              }
            end
          }
        end
      }
    end
  end
end
