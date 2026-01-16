# frozen_string_literal: true

# Controller para Categorias de Custo
class CategoriasCustoController < InertiaController
  before_action :set_categoria, only: [:edit, :update, :destroy, :toggle_status]

  TIPOS = {
    'ambos' => 'Previsto e Real',
    'previsto' => 'Apenas Previsto',
    'real' => 'Apenas Real'
  }.freeze

  GRUPOS = {
    'fob' => 'Valor FOB',
    'frete' => 'Frete Internacional',
    'seguro' => 'Seguro',
    'impostos' => 'Impostos e Taxas',
    'armazenagem' => 'Armazenagem e Terminal',
    'servicos' => 'Servicos',
    'transporte' => 'Transporte Nacional',
    'outros' => 'Outros Custos'
  }.freeze

  def index
    @categorias = CategoriaCusto.order(:ordem, :nome)

    # Filtros
    @categorias = @categorias.where(ativo: params[:ativo] == 'true') if params[:ativo].present?
    @categorias = @categorias.where('nome ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @categorias = @categorias.where(grupo: params[:grupo]) if params[:grupo].present?

    render inertia: 'categorias_custo/CategoriasCustoIndex', props: {
      categorias: @categorias.map { |c| categoria_list_json(c) },
      filters: {
        search: params[:search],
        ativo: params[:ativo],
        grupo: params[:grupo]
      },
      tipoOptions: tipo_options,
      grupoOptions: grupo_options,
      statusOptions: status_options
    }
  end

  def new
    render inertia: 'categorias_custo/CategoriasCustoForm', props: form_props(CategoriaCusto.new)
  end

  def create
    @categoria = CategoriaCusto.new(categoria_params)

    if @categoria.save
      redirect_to categorias_custo_path, notice: 'Categoria criada com sucesso!'
    else
      redirect_to new_categoria_custo_path, inertia: { errors: @categoria.errors.to_hash }
    end
  end

  def edit
    render inertia: 'categorias_custo/CategoriasCustoForm', props: form_props(@categoria)
  end

  def update
    if @categoria.update(categoria_params)
      redirect_to categorias_custo_path, notice: 'Categoria atualizada com sucesso!'
    else
      redirect_to edit_categoria_custo_path(@categoria), inertia: { errors: @categoria.errors.to_hash }
    end
  end

  def destroy
    if CustoPrevisto.where(categoria_custo_id: @categoria.id).exists? ||
       CustoReal.where(categoria_custo_id: @categoria.id).exists?
      redirect_to categorias_custo_path, alert: 'Nao e possivel excluir categoria com custos vinculados.'
      return
    end

    @categoria.destroy
    redirect_to categorias_custo_path, notice: 'Categoria excluida com sucesso!'
  end

  # Toggle status ativo/inativo
  def toggle_status
    @categoria.update(ativo: !@categoria.ativo)
    redirect_to categorias_custo_path, notice: "Categoria #{@categoria.ativo ? 'ativada' : 'desativada'}!"
  end

  private

  def set_categoria
    @categoria = CategoriaCusto.find(params[:id])
  end

  def categoria_params
    params.require(:categoria_custo).permit(
      :nome, :codigo, :tipo, :grupo, :descricao, :ordem, :obrigatorio, :ativo
    )
  end

  def form_props(categoria)
    {
      categoria: categoria.persisted? ? categoria_form_json(categoria) : nil,
      tipoOptions: tipo_options,
      grupoOptions: grupo_options
    }
  end

  def categoria_list_json(categoria)
    {
      id: categoria.id,
      nome: categoria.nome,
      codigo: categoria.codigo,
      tipo: categoria.tipo,
      tipoLabel: TIPOS[categoria.tipo] || categoria.tipo,
      grupo: categoria.grupo,
      grupoLabel: GRUPOS[categoria.grupo] || categoria.grupo,
      ordem: categoria.ordem,
      obrigatorio: categoria.obrigatorio,
      ativo: categoria.ativo,
      ativoLabel: categoria.ativo ? 'Ativo' : 'Inativo'
    }
  end

  def categoria_form_json(categoria)
    {
      id: categoria.id,
      nome: categoria.nome,
      codigo: categoria.codigo,
      tipo: categoria.tipo,
      grupo: categoria.grupo,
      descricao: categoria.descricao,
      ordem: categoria.ordem,
      obrigatorio: categoria.obrigatorio,
      ativo: categoria.ativo
    }
  end

  def tipo_options
    TIPOS.map { |k, v| { value: k, label: v } }
  end

  def grupo_options
    GRUPOS.map { |k, v| { value: k, label: v } }
  end

  def status_options
    [
      { value: 'true', label: 'Ativo' },
      { value: 'false', label: 'Inativo' }
    ]
  end
end
