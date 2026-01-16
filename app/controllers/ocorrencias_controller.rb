# frozen_string_literal: true

# Controller para Ocorrencias de Processos de Importacao
# CRUD completo com transicoes de status
class OcorrenciasController < InertiaController
  before_action :set_ocorrencia, only: [:show, :edit, :update, :destroy, :iniciar_analise, :resolver, :cancelar]

  # GET /ocorrencias
  def index
    @ocorrencias = Ocorrencia
                     .includes(:processo_importacao, :criado_por, :responsavel)
                     .order(data_ocorrencia: :desc)

    # Filtros
    @ocorrencias = @ocorrencias.where(status: params[:status]) if params[:status].present?
    @ocorrencias = @ocorrencias.where(tipo: params[:tipo]) if params[:tipo].present?
    @ocorrencias = @ocorrencias.where(gravidade: params[:gravidade]) if params[:gravidade].present?
    @ocorrencias = @ocorrencias.where(processo_importacao_id: params[:processo_id]) if params[:processo_id].present?

    if params[:search].present?
      search = "%#{params[:search]}%"
      @ocorrencias = @ocorrencias.where('titulo ILIKE ? OR descricao ILIKE ?', search, search)
    end

    # Paginacao
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    total = @ocorrencias.count
    @ocorrencias = @ocorrencias.offset((page - 1) * per_page).limit(per_page)

    render inertia: 'ocorrencias/OcorrenciasIndex', props: {
      usuario: usuario_json,
      ocorrencias: @ocorrencias.map { |o| ocorrencia_list_json(o) },
      statusOptions: status_options,
      tipoOptions: tipo_options,
      gravidadeOptions: gravidade_options,
      processosOptions: processos_options,
      pagination: {
        currentPage: page,
        perPage: per_page,
        total: total,
        totalPages: (total.to_f / per_page).ceil
      },
      filters: {
        status: params[:status],
        tipo: params[:tipo],
        gravidade: params[:gravidade],
        processoId: params[:processo_id]&.to_i,
        search: params[:search]
      },
      kpis: calcular_kpis
    }
  end

  # GET /ocorrencias/:id
  def show
    render inertia: 'ocorrencias/OcorrenciasShow', props: {
      usuario: usuario_json,
      ocorrencia: ocorrencia_detail_json(@ocorrencia),
      podeEditar: @ocorrencia.ativa?,
      podeIniciarAnalise: @ocorrencia.status == 'aberta',
      podeResolver: @ocorrencia.status == 'em_analise',
      podeCancelar: @ocorrencia.ativa?
    }
  end

  # GET /ocorrencias/new
  def new
    render inertia: 'ocorrencias/OcorrenciasForm', props: form_props(nil)
  end

  # GET /ocorrencias/:id/edit
  def edit
    unless @ocorrencia.ativa?
      flash[:alert] = 'Esta ocorrencia nao pode mais ser editada.'
      return redirect_to ocorrencias_path
    end

    render inertia: 'ocorrencias/OcorrenciasForm', props: form_props(@ocorrencia)
  end

  # POST /ocorrencias
  def create
    @ocorrencia = Ocorrencia.new(ocorrencia_params)
    @ocorrencia.criado_por = current_usuario
    @ocorrencia.status = 'aberta'

    if @ocorrencia.save
      flash[:notice] = 'Ocorrencia registrada com sucesso.'
      redirect_to ocorrencia_path(@ocorrencia)
    else
      flash[:alert] = "Erro ao criar ocorrencia: #{@ocorrencia.errors.full_messages.join(', ')}"
      redirect_to new_ocorrencia_path
    end
  end

  # PATCH/PUT /ocorrencias/:id
  def update
    unless @ocorrencia.ativa?
      flash[:alert] = 'Esta ocorrencia nao pode mais ser editada.'
      return redirect_to ocorrencias_path
    end

    if @ocorrencia.update(ocorrencia_params)
      flash[:notice] = 'Ocorrencia atualizada com sucesso.'
      redirect_to ocorrencia_path(@ocorrencia)
    else
      flash[:alert] = "Erro ao atualizar ocorrencia: #{@ocorrencia.errors.full_messages.join(', ')}"
      redirect_to edit_ocorrencia_path(@ocorrencia)
    end
  end

  # DELETE /ocorrencias/:id
  def destroy
    if @ocorrencia.status == 'resolvida'
      flash[:alert] = 'Nao e possivel excluir uma ocorrencia resolvida.'
      return redirect_to ocorrencias_path
    end

    @ocorrencia.destroy!
    flash[:notice] = 'Ocorrencia excluida com sucesso.'
    redirect_to ocorrencias_path
  end

  # =====================================================
  # Transicoes de Status
  # =====================================================

  # POST /ocorrencias/:id/iniciar_analise
  def iniciar_analise
    @ocorrencia.iniciar_analise!(current_usuario)
    render json: { success: true, message: 'Analise iniciada.', ocorrencia: ocorrencia_list_json(@ocorrencia.reload) }
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  # POST /ocorrencias/:id/resolver
  def resolver
    resolucao = params[:resolucao].presence || 'Resolvido'
    @ocorrencia.resolver!(resolucao)
    render json: { success: true, message: 'Ocorrencia resolvida.', ocorrencia: ocorrencia_list_json(@ocorrencia.reload) }
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  # POST /ocorrencias/:id/cancelar
  def cancelar
    motivo = params[:motivo].presence || 'Cancelada pelo usuario'
    @ocorrencia.cancelar!(motivo)
    render json: { success: true, message: 'Ocorrencia cancelada.', ocorrencia: ocorrencia_list_json(@ocorrencia.reload) }
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  private

  def set_ocorrencia
    @ocorrencia = Ocorrencia.find(params[:id])
  end

  def ocorrencia_params
    params.require(:ocorrencia).permit(
      :processo_importacao_id, :responsavel_id, :tipo, :gravidade,
      :titulo, :descricao, :data_ocorrencia, :impacto_financeiro
    )
  end

  # =====================================================
  # Helpers de Props
  # =====================================================

  def form_props(ocorrencia)
    {
      usuario: usuario_json,
      ocorrencia: ocorrencia ? ocorrencia_form_json(ocorrencia) : nil,
      processosOptions: processos_options,
      responsaveisOptions: responsaveis_options,
      tipoOptions: tipo_options,
      gravidadeOptions: gravidade_options
    }
  end

  # =====================================================
  # Helpers de JSON
  # =====================================================

  def usuario_json
    current_usuario.as_json(only: [:id, :login, :nome])
  end

  def ocorrencia_list_json(ocorrencia)
    {
      id: ocorrencia.id,
      titulo: ocorrencia.titulo,
      tipo: ocorrencia.tipo,
      tipoLabel: Ocorrencia::TIPOS[ocorrencia.tipo],
      gravidade: ocorrencia.gravidade,
      gravidadeLabel: Ocorrencia::GRAVIDADES[ocorrencia.gravidade],
      status: ocorrencia.status,
      statusLabel: Ocorrencia::STATUSES[ocorrencia.status],
      processo: {
        id: ocorrencia.processo_importacao.id,
        numero: ocorrencia.processo_importacao.numero
      },
      criadoPor: {
        id: ocorrencia.criado_por.id,
        nome: ocorrencia.criado_por.nome
      },
      responsavel: ocorrencia.responsavel ? {
        id: ocorrencia.responsavel.id,
        nome: ocorrencia.responsavel.nome
      } : nil,
      dataOcorrencia: ocorrencia.data_ocorrencia.iso8601,
      impactoFinanceiro: ocorrencia.impacto_financeiro&.to_f,
      diasAberto: ocorrencia.dias_aberto,
      createdAt: ocorrencia.created_at.iso8601
    }
  end

  def ocorrencia_form_json(ocorrencia)
    {
      id: ocorrencia.id,
      processoImportacaoId: ocorrencia.processo_importacao_id,
      responsavelId: ocorrencia.responsavel_id,
      tipo: ocorrencia.tipo,
      gravidade: ocorrencia.gravidade,
      titulo: ocorrencia.titulo,
      descricao: ocorrencia.descricao,
      dataOcorrencia: ocorrencia.data_ocorrencia.iso8601,
      impactoFinanceiro: ocorrencia.impacto_financeiro&.to_f
    }
  end

  def ocorrencia_detail_json(ocorrencia)
    ocorrencia_list_json(ocorrencia).merge(
      descricao: ocorrencia.descricao,
      resolucao: ocorrencia.resolucao,
      dataResolucao: ocorrencia.data_resolucao&.iso8601,
      tempoResolucao: ocorrencia.tempo_resolucao
    )
  end

  # =====================================================
  # Helpers de Options
  # =====================================================

  def status_options
    Ocorrencia::STATUSES.map { |k, v| { value: k, label: v } }
  end

  def tipo_options
    Ocorrencia::TIPOS.map { |k, v| { value: k, label: v } }
  end

  def gravidade_options
    Ocorrencia::GRAVIDADES.map { |k, v| { value: k, label: v } }
  end

  def processos_options
    ProcessoImportacao
      .where.not(status: 'cancelado')
      .order(numero: :desc)
      .limit(100)
      .map { |p| { value: p.id, label: "#{p.numero} - #{p.fornecedor.nome}" } }
  end

  def responsaveis_options
    Usuario.where(status: 'A').order(:nome).map do |u|
      { value: u.id, label: u.nome }
    end
  end

  def calcular_kpis
    {
      totalAbertas: Ocorrencia.abertas.count,
      totalEmAnalise: Ocorrencia.em_analise.count,
      totalCriticas: Ocorrencia.ativas.criticas.count,
      impactoTotal: Ocorrencia.ativas.com_impacto_financeiro.sum(:impacto_financeiro).to_f
    }
  end
end
