# frozen_string_literal: true

class UnidadeMedidasController < ApplicationController
  before_action :set_unidade_medida, only: [:edit, :update, :destroy]

  def index
    @unidade_medidas = UnidadeMedida.ordered

    # Filtros
    if params[:nome].present?
      @unidade_medidas = @unidade_medidas.where('nome ILIKE ?', "%#{params[:nome]}%")
    end

    # Paginacao
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    total = @unidade_medidas.count
    @unidade_medidas = @unidade_medidas.offset((page - 1) * per_page).limit(per_page)

    render inertia: 'unidade_medidas/UnidadeMedidasIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      unidadeMedidas: @unidade_medidas.map { |u| unidade_medida_json(u) },
      pagination: {
        currentPage: page,
        perPage: per_page,
        total: total
      },
      filters: {
        nome: params[:nome]
      }
    }
  end

  def new
    render inertia: 'unidade_medidas/UnidadeMedidasForm', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      unidadeMedida: nil
    }
  end

  def create
    @unidade_medida = UnidadeMedida.new(unidade_medida_params)

    begin
      @unidade_medida.save!
      redirect_to unidade_medidas_path, notice: 'Unidade de Medida cadastrada com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_unidade_medida_path, alert: e.record.errors.full_messages.join(', ')
    rescue ActiveRecord::RecordNotUnique
      redirect_to new_unidade_medida_path, alert: 'Nome ou sigla já utilizado. Escolha outro!'
    rescue StandardError => e
      redirect_to new_unidade_medida_path, alert: "Erro ao salvar: #{e.message}"
    end
  end

  def edit
    render inertia: 'unidade_medidas/UnidadeMedidasForm', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      unidadeMedida: unidade_medida_json(@unidade_medida)
    }
  end

  def update
    begin
      @unidade_medida.update!(unidade_medida_params)
      redirect_to unidade_medidas_path, notice: 'Unidade de Medida alterada com sucesso.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_unidade_medida_path(@unidade_medida), alert: e.record.errors.full_messages.join(', ')
    rescue ActiveRecord::RecordNotUnique
      redirect_to edit_unidade_medida_path(@unidade_medida), alert: 'Nome ou sigla já utilizado. Escolha outro!'
    rescue StandardError => e
      redirect_to edit_unidade_medida_path(@unidade_medida), alert: "Erro ao salvar: #{e.message}"
    end
  end

  def destroy
    begin
      @unidade_medida.destroy!
      redirect_to unidade_medidas_path, notice: 'Unidade de Medida deletada com sucesso.'
    rescue ActiveRecord::InvalidForeignKey
      redirect_to unidade_medidas_path, alert: 'Não é possível excluir! Existe Resíduo cadastrado com essa Unidade de Medida.'
    rescue StandardError => e
      redirect_to unidade_medidas_path, alert: "Erro ao excluir: #{e.message}"
    end
  end

  private

  def set_unidade_medida
    @unidade_medida = UnidadeMedida.find(params[:id])
  end

  def unidade_medida_params
    params.require(:unidade_medida).permit(:nome, :sigla)
  end

  def unidade_medida_json(unidade_medida)
    {
      id: unidade_medida.id,
      nome: unidade_medida.nome,
      sigla: unidade_medida.sigla
    }
  end
end
