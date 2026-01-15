# frozen_string_literal: true

class BairrosController < ApplicationController
  before_action :set_bairro, only: [:edit, :update, :destroy]

  def index
    @bairros = Bairro.includes(cidade: :uf).ordered

    # Filtros
    if params[:nome].present?
      @bairros = @bairros.where('bairros.nome ILIKE ?', "%#{params[:nome]}%")
    end
    @bairros = @bairros.where(cidade_id: params[:cidade_id]) if params[:cidade_id].present?
    if params[:uf_id].present?
      @bairros = @bairros.joins(cidade: :uf).where(cidades: { uf_id: params[:uf_id] })
    end

    # Paginacao
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    total = @bairros.count
    @bairros = @bairros.offset((page - 1) * per_page).limit(per_page)

    render inertia: 'bairros/BairrosIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      bairros: @bairros.map { |b| bairro_list_json(b) },
      ufs: Uf.order(:nome).map { |u| { id: u.id, nome: u.nome, sigla: u.sigla } },
      pagination: {
        currentPage: page,
        perPage: per_page,
        total: total
      },
      filters: {
        nome: params[:nome],
        uf_id: params[:uf_id],
        cidade_id: params[:cidade_id]
      }
    }
  end

  def new
    render inertia: 'bairros/BairrosForm', props: form_props(nil)
  end

  def create
    @bairro = Bairro.new(bairro_params)

    begin
      @bairro.save!
      redirect_to bairros_path, notice: 'Bairro cadastrado com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_bairro_path, alert: e.record.errors.full_messages.join(', ')
    rescue StandardError => e
      redirect_to new_bairro_path, alert: "Erro ao salvar: #{e.message}"
    end
  end

  def edit
    render inertia: 'bairros/BairrosForm', props: form_props(@bairro)
  end

  def update
    begin
      @bairro.update!(bairro_params)
      redirect_to bairros_path, notice: 'Bairro alterado com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_bairro_path(@bairro), alert: e.record.errors.full_messages.join(', ')
    rescue StandardError => e
      redirect_to edit_bairro_path(@bairro), alert: "Erro ao salvar: #{e.message}"
    end
  end

  def destroy
    begin
      @bairro.destroy!
      redirect_to bairros_path, notice: 'Bairro deletado com sucesso.'
    rescue ActiveRecord::InvalidForeignKey
      redirect_to bairros_path, alert: 'Não é possível excluir! Existem registros vinculados a esse bairro.'
    rescue StandardError => e
      redirect_to bairros_path, alert: "Erro ao excluir: #{e.message}"
    end
  end

  # API endpoints para cascata de selects
  def cidades_by_uf
    cidades = Cidade.where(uf_id: params[:uf_id]).order(:nome)
    render json: cidades.map { |c| { id: c.id, nome: c.nome } }
  end

  private

  def set_bairro
    @bairro = Bairro.find(params[:id])
  end

  def bairro_params
    params.require(:bairro).permit(:nome, :cidade_id)
  end

  def form_props(bairro)
    uf_id = bairro&.cidade&.uf_id

    {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      bairro: bairro ? bairro_json(bairro) : nil,
      ufs: Uf.order(:nome).map { |u| { id: u.id, nome: u.nome, sigla: u.sigla } },
      cidades: uf_id ? Cidade.where(uf_id: uf_id).order(:nome).map { |c| { id: c.id, nome: c.nome } } : [],
      ufSelecionada: uf_id
    }
  end

  def bairro_list_json(bairro)
    {
      id: bairro.id,
      nome: bairro.nome,
      cidade: bairro.cidade&.nome,
      uf: bairro.cidade&.uf&.sigla
    }
  end

  def bairro_json(bairro)
    {
      id: bairro.id,
      nome: bairro.nome,
      cidade_id: bairro.cidade_id
    }
  end
end
