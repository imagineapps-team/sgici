# frozen_string_literal: true

class UsuariosController < ApplicationController
  before_action :set_usuario_record, only: [:edit, :update, :destroy]

  def index
    @usuarios = Usuario.includes(:perfil).ordered

    # Filtros
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @usuarios = @usuarios.where(
        'usuarios.nome ILIKE ? OR usuarios.login ILIKE ?',
        search_term, search_term
      )
    end
    @usuarios = @usuarios.where(perfil_id: params[:perfil_id]) if params[:perfil_id].present?
    @usuarios = @usuarios.where(status: params[:status]) if params[:status].present?

    # Paginacao
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    total = @usuarios.count
    @usuarios = @usuarios.offset((page - 1) * per_page).limit(per_page)

    render inertia: 'usuarios/UsuariosIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      usuarios: @usuarios.map { |u| usuario_list_json(u) },
      perfis: Perfil.ativos.ordered.map { |p| { id: p.id, nome: p.nome } },
      statusOptions: Usuario::STATUSES.map { |value, label| { value: value, label: label } },
      pagination: {
        currentPage: page,
        perPage: per_page,
        total: total
      },
      filters: {
        search: params[:search],
        perfil_id: params[:perfil_id],
        status: params[:status]
      }
    }
  end

  def new
    render inertia: 'usuarios/UsuariosForm', props: form_props(nil)
  end

  def create
    @usuario_record = Usuario.new(usuario_params_create)

    begin
      @usuario_record.save!
      redirect_to usuarios_path, notice: 'Usuário cadastrado com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_usuario_path, alert: e.record.errors.full_messages.join(', ')
    rescue StandardError => e
      redirect_to new_usuario_path, alert: "Erro ao salvar: #{e.message}"
    end
  end

  def edit
    render inertia: 'usuarios/UsuariosForm', props: form_props(@usuario_record)
  end

  def update
    begin
      update_params = usuario_params_update
      # Remove password if blank (optional on edit)
      update_params.delete(:password) if update_params[:password].blank?

      @usuario_record.update!(update_params)
      redirect_to usuarios_path, notice: 'Usuário alterado com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_usuario_path(@usuario_record), alert: e.record.errors.full_messages.join(', ')
    rescue StandardError => e
      redirect_to edit_usuario_path(@usuario_record), alert: "Erro ao salvar: #{e.message}"
    end
  end

  def destroy
    begin
      @usuario_record.destroy!
      redirect_to usuarios_path, notice: 'Usuário deletado com sucesso.'
    rescue ActiveRecord::InvalidForeignKey
      redirect_to usuarios_path, alert: 'Não é possível excluir! Existem registros vinculados a esse usuário.'
    rescue StandardError => e
      redirect_to usuarios_path, alert: "Erro ao excluir: #{e.message}"
    end
  end

  private

  def set_usuario_record
    @usuario_record = Usuario.find(params[:id])
  end

  def usuario_params_create
    params.require(:usuario).permit(:nome, :login, :perfil_id, :status, :password)
  end

  def usuario_params_update
    params.require(:usuario).permit(:nome, :login, :perfil_id, :status, :password)
  end

  def form_props(usuario_record)
    {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      usuarioData: usuario_record ? usuario_json(usuario_record) : nil,
      perfis: Perfil.ativos.ordered.map { |p| { id: p.id, nome: p.nome } },
      statusOptions: Usuario::STATUSES.map { |value, label| { value: value, label: label } }
    }
  end

  def usuario_list_json(usuario_record)
    {
      id: usuario_record.id,
      nome: usuario_record.nome,
      login: usuario_record.login,
      perfil: usuario_record.perfil&.nome,
      contexto: usuario_record.contexto,
      status: usuario_record.status,
      statusLabel: usuario_record.status_label
    }
  end

  def usuario_json(usuario_record)
    {
      id: usuario_record.id,
      nome: usuario_record.nome,
      login: usuario_record.login,
      perfil_id: usuario_record.perfil_id,
      status: usuario_record.status
    }
  end
end
