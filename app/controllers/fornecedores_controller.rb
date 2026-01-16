# frozen_string_literal: true

# Controller para Fornecedores
class FornecedoresController < InertiaController
  before_action :set_fornecedor, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @fornecedores = Fornecedor.order(:nome)

    # Filtros
    @fornecedores = @fornecedores.where(ativo: params[:ativo] == 'true') if params[:ativo].present?
    @fornecedores = @fornecedores.where('nome ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @fornecedores = @fornecedores.where(pais: params[:pais]) if params[:pais].present?

    render inertia: 'fornecedores/FornecedoresIndex', props: {
      fornecedores: @fornecedores.map { |f| fornecedor_list_json(f) },
      filters: {
        search: params[:search],
        ativo: params[:ativo],
        pais: params[:pais]
      },
      paisOptions: pais_options,
      statusOptions: status_options
    }
  end

  def show
    processos = @fornecedor.processos_importacao
                           .includes(:responsavel)
                           .order(created_at: :desc)
                           .limit(10)

    render inertia: 'fornecedores/FornecedoresShow', props: {
      fornecedor: fornecedor_detail_json(@fornecedor),
      processosRecentes: processos.map { |p| processo_resumo_json(p) },
      estatisticas: calcular_estatisticas(@fornecedor)
    }
  end

  def new
    render inertia: 'fornecedores/FornecedoresForm', props: form_props(Fornecedor.new)
  end

  def create
    @fornecedor = Fornecedor.new(fornecedor_params)

    if @fornecedor.save
      redirect_to fornecedores_path, notice: 'Fornecedor criado com sucesso!'
    else
      redirect_to new_fornecedor_path, inertia: { errors: @fornecedor.errors.to_hash }
    end
  end

  def edit
    render inertia: 'fornecedores/FornecedoresForm', props: form_props(@fornecedor)
  end

  def update
    if @fornecedor.update(fornecedor_params)
      redirect_to fornecedores_path, notice: 'Fornecedor atualizado com sucesso!'
    else
      redirect_to edit_fornecedor_path(@fornecedor), inertia: { errors: @fornecedor.errors.to_hash }
    end
  end

  def destroy
    if @fornecedor.processos_importacao.exists?
      redirect_to fornecedores_path, alert: 'Nao e possivel excluir fornecedor com processos vinculados.'
      return
    end

    @fornecedor.destroy
    redirect_to fornecedores_path, notice: 'Fornecedor excluido com sucesso!'
  end

  # Endpoint para autocomplete
  def autocomplete
    term = params[:term].to_s.strip
    fornecedores = Fornecedor.where(ativo: true)
                             .where('nome ILIKE ?', "%#{term}%")
                             .limit(10)
                             .map { |f| { value: f.id, label: f.nome } }
    render json: fornecedores
  end

  # Toggle status ativo/inativo
  def toggle_status
    @fornecedor.update(ativo: !@fornecedor.ativo)
    redirect_to fornecedores_path, notice: "Fornecedor #{@fornecedor.ativo ? 'ativado' : 'desativado'}!"
  end

  private

  def set_fornecedor
    @fornecedor = Fornecedor.find(params[:id])
  end

  def fornecedor_params
    params.require(:fornecedor).permit(
      :nome, :nome_fantasia, :cnpj, :email, :telefone, :website,
      :pais, :estado, :cidade, :endereco, :cep,
      :contato_comercial_nome, :contato_comercial_email, :contato_comercial_telefone,
      :contato_operacional_nome, :contato_operacional_email, :contato_operacional_telefone,
      :observacoes, :moeda_padrao, :prazo_pagamento_dias, :ativo
    )
  end

  def form_props(fornecedor)
    {
      fornecedor: fornecedor.persisted? ? fornecedor_form_json(fornecedor) : nil,
      paisOptions: pais_options,
      moedaOptions: moeda_options
    }
  end

  def fornecedor_list_json(fornecedor)
    {
      id: fornecedor.id,
      nome: fornecedor.nome,
      nomeFantasia: fornecedor.nome_fantasia,
      cnpj: fornecedor.cnpj,
      pais: fornecedor.pais,
      cidade: fornecedor.cidade,
      email: fornecedor.email,
      telefone: fornecedor.telefone,
      ativo: fornecedor.ativo,
      ativoLabel: fornecedor.ativo ? 'Ativo' : 'Inativo',
      totalProcessos: fornecedor.total_processos || 0,
      score: fornecedor.score
    }
  end

  def fornecedor_form_json(fornecedor)
    {
      id: fornecedor.id,
      nome: fornecedor.nome,
      nomeFantasia: fornecedor.nome_fantasia,
      cnpj: fornecedor.cnpj,
      email: fornecedor.email,
      telefone: fornecedor.telefone,
      website: fornecedor.website,
      pais: fornecedor.pais,
      estado: fornecedor.estado,
      cidade: fornecedor.cidade,
      endereco: fornecedor.endereco,
      cep: fornecedor.cep,
      contatoComercialNome: fornecedor.contato_comercial_nome,
      contatoComercialEmail: fornecedor.contato_comercial_email,
      contatoComercialTelefone: fornecedor.contato_comercial_telefone,
      contatoOperacionalNome: fornecedor.contato_operacional_nome,
      contatoOperacionalEmail: fornecedor.contato_operacional_email,
      contatoOperacionalTelefone: fornecedor.contato_operacional_telefone,
      observacoes: fornecedor.observacoes,
      moedaPadrao: fornecedor.moeda_padrao,
      prazoPagamentoDias: fornecedor.prazo_pagamento_dias,
      ativo: fornecedor.ativo
    }
  end

  def pais_options
    [
      { value: 'China', label: 'China' },
      { value: 'Estados Unidos', label: 'Estados Unidos' },
      { value: 'Alemanha', label: 'Alemanha' },
      { value: 'Japao', label: 'Japao' },
      { value: 'Coreia do Sul', label: 'Coreia do Sul' },
      { value: 'Italia', label: 'Italia' },
      { value: 'Franca', label: 'Franca' },
      { value: 'Reino Unido', label: 'Reino Unido' },
      { value: 'India', label: 'India' },
      { value: 'Mexico', label: 'Mexico' },
      { value: 'Argentina', label: 'Argentina' },
      { value: 'Chile', label: 'Chile' }
    ]
  end

  def moeda_options
    [
      { value: 'USD', label: 'USD - Dolar Americano' },
      { value: 'EUR', label: 'EUR - Euro' },
      { value: 'CNY', label: 'CNY - Yuan Chines' },
      { value: 'GBP', label: 'GBP - Libra Esterlina' },
      { value: 'JPY', label: 'JPY - Iene Japones' }
    ]
  end

  def status_options
    [
      { value: 'true', label: 'Ativo' },
      { value: 'false', label: 'Inativo' }
    ]
  end

  def fornecedor_detail_json(fornecedor)
    processos = fornecedor.processos_importacao
    processos_finalizados = processos.finalizados

    # Calcular metricas
    valor_total_fob = processos.sum(:valor_fob)&.to_f || 0
    lead_times = processos_finalizados.where.not(lead_time_dias: nil).pluck(:lead_time_dias)
    lead_time_medio = lead_times.any? ? (lead_times.sum.to_f / lead_times.size) : nil
    desvios = processos_finalizados.where.not(desvio_percentual: nil).pluck(:desvio_percentual)
    desvio_medio = desvios.any? ? (desvios.sum.to_f / desvios.size) : nil

    fornecedor_form_json(fornecedor).merge(
      ativo: fornecedor.ativo,
      ativoLabel: fornecedor.ativo ? 'Ativo' : 'Inativo',
      totalProcessos: fornecedor.total_processos || 0,
      processosAtivos: processos.ativos.count,
      valorTotalFob: valor_total_fob,
      score: fornecedor.score&.to_f,
      leadTimeMedio: lead_time_medio,
      desvioMedio: desvio_medio,
      createdAt: fornecedor.created_at.iso8601,
      updatedAt: fornecedor.updated_at.iso8601
    )
  end

  def processo_resumo_json(processo)
    {
      id: processo.id,
      numero: processo.numero,
      status: processo.status,
      statusLabel: ProcessoImportacao::STATUSES[processo.status],
      modal: processo.modal,
      valorFob: processo.valor_fob&.to_f,
      moeda: processo.moeda,
      dataChegadaPrevista: processo.data_chegada_prevista&.iso8601,
      createdAt: processo.created_at.iso8601
    }
  end

  def calcular_estatisticas(fornecedor)
    processos = fornecedor.processos_importacao

    {
      totalProcessos: processos.count,
      processosAtivos: processos.ativos.count,
      processosPorStatus: ProcessoImportacao::STATUSES.keys.map do |status|
        { status: status, label: ProcessoImportacao::STATUSES[status], total: processos.where(status: status).count }
      end.select { |s| s[:total] > 0 },
      valorTotalFob: processos.sum(:valor_fob)&.to_f || 0,
      custoPrevistoTotal: processos.sum(:custo_previsto_total)&.to_f || 0,
      custoRealTotal: processos.sum(:custo_real_total)&.to_f || 0
    }
  end
end
