# frozen_string_literal: true

# Controller para Prestadores de Servico
class PrestadoresServicoController < InertiaController
  before_action :set_prestador, only: [:edit, :update, :destroy, :toggle_status]

  TIPOS = {
    'freight_forwarder' => 'Freight Forwarder',
    'despachante' => 'Despachante Aduaneiro',
    'seguradora' => 'Seguradora',
    'transportadora' => 'Transportadora',
    'armazem' => 'Armazem',
    'outro' => 'Outro'
  }.freeze

  def index
    @prestadores = PrestadorServico.order(:nome)

    # Filtros
    @prestadores = @prestadores.where(ativo: params[:ativo] == 'true') if params[:ativo].present?
    @prestadores = @prestadores.where('nome ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @prestadores = @prestadores.where(tipo: params[:tipo]) if params[:tipo].present?

    render inertia: 'prestadores_servico/PrestadoresServicoIndex', props: {
      prestadores: @prestadores.map { |p| prestador_list_json(p) },
      filters: {
        search: params[:search],
        ativo: params[:ativo],
        tipo: params[:tipo]
      },
      tipoOptions: tipo_options,
      statusOptions: status_options
    }
  end

  def new
    render inertia: 'prestadores_servico/PrestadoresServicoForm', props: form_props(PrestadorServico.new)
  end

  def create
    @prestador = PrestadorServico.new(prestador_params)

    if @prestador.save
      redirect_to prestadores_servico_path, notice: 'Prestador criado com sucesso!'
    else
      redirect_to new_prestador_servico_path, inertia: { errors: @prestador.errors.to_hash }
    end
  end

  def edit
    render inertia: 'prestadores_servico/PrestadoresServicoForm', props: form_props(@prestador)
  end

  def update
    if @prestador.update(prestador_params)
      redirect_to prestadores_servico_path, notice: 'Prestador atualizado com sucesso!'
    else
      redirect_to edit_prestador_servico_path(@prestador), inertia: { errors: @prestador.errors.to_hash }
    end
  end

  def destroy
    if @prestador.custos_reais.exists?
      redirect_to prestadores_servico_path, alert: 'Nao e possivel excluir prestador com custos vinculados.'
      return
    end

    @prestador.destroy
    redirect_to prestadores_servico_path, notice: 'Prestador excluido com sucesso!'
  end

  # Endpoint para autocomplete
  def autocomplete
    term = params[:term].to_s.strip
    prestadores = PrestadorServico.where(ativo: true)
                                  .where('nome ILIKE ?', "%#{term}%")
                                  .limit(10)
                                  .map { |p| { value: p.id, label: "#{p.nome} (#{TIPOS[p.tipo]})" } }
    render json: prestadores
  end

  # Toggle status ativo/inativo
  def toggle_status
    @prestador.update(ativo: !@prestador.ativo)
    redirect_to prestadores_servico_path, notice: "Prestador #{@prestador.ativo ? 'ativado' : 'desativado'}!"
  end

  private

  def set_prestador
    @prestador = PrestadorServico.find(params[:id])
  end

  def prestador_params
    params.require(:prestador_servico).permit(
      :nome, :nome_fantasia, :cnpj, :tipo, :email, :telefone, :website,
      :pais, :estado, :cidade, :endereco, :cep,
      :contato_nome, :contato_email, :contato_telefone,
      :observacoes, :servicos_oferecidos, :ativo
    )
  end

  def form_props(prestador)
    {
      prestador: prestador.persisted? ? prestador_form_json(prestador) : nil,
      tipoOptions: tipo_options
    }
  end

  def prestador_list_json(prestador)
    {
      id: prestador.id,
      nome: prestador.nome,
      nomeFantasia: prestador.nome_fantasia,
      cnpj: prestador.cnpj,
      tipo: prestador.tipo,
      tipoLabel: TIPOS[prestador.tipo] || prestador.tipo,
      cidade: prestador.cidade,
      email: prestador.email,
      telefone: prestador.telefone,
      ativo: prestador.ativo,
      ativoLabel: prestador.ativo ? 'Ativo' : 'Inativo',
      totalServicos: prestador.total_servicos || 0,
      score: prestador.score
    }
  end

  def prestador_form_json(prestador)
    {
      id: prestador.id,
      nome: prestador.nome,
      nomeFantasia: prestador.nome_fantasia,
      cnpj: prestador.cnpj,
      tipo: prestador.tipo,
      email: prestador.email,
      telefone: prestador.telefone,
      website: prestador.website,
      pais: prestador.pais,
      estado: prestador.estado,
      cidade: prestador.cidade,
      endereco: prestador.endereco,
      cep: prestador.cep,
      contatoNome: prestador.contato_nome,
      contatoEmail: prestador.contato_email,
      contatoTelefone: prestador.contato_telefone,
      observacoes: prestador.observacoes,
      servicosOferecidos: prestador.servicos_oferecidos,
      ativo: prestador.ativo
    }
  end

  def tipo_options
    TIPOS.map { |k, v| { value: k, label: v } }
  end

  def status_options
    [
      { value: 'true', label: 'Ativo' },
      { value: 'false', label: 'Inativo' }
    ]
  end
end
