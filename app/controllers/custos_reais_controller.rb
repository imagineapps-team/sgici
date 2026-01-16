# frozen_string_literal: true

# Controller para Custos Reais
# Gerencia custos reais de forma standalone (listagem geral) e nested (por processo)
class CustosReaisController < InertiaController
  before_action :set_custo_real, only: [:edit, :update, :destroy]
  before_action :set_processo, only: [:new, :create], if: -> { params[:processo_importacao_id].present? }

  STATUS_PAGAMENTO = {
    'pendente' => 'Pendente',
    'aprovado' => 'Aprovado',
    'pago' => 'Pago',
    'cancelado' => 'Cancelado'
  }.freeze

  def index
    @custos = CustoReal.includes(:processo_importacao, :categoria_custo, :prestador_servico, :criado_por)
                       .order(created_at: :desc)

    # Filtros
    @custos = @custos.where(processo_importacao_id: params[:processo_id]) if params[:processo_id].present?
    @custos = @custos.where(categoria_custo_id: params[:categoria_id]) if params[:categoria_id].present?
    @custos = @custos.where(status_pagamento: params[:status]) if params[:status].present?

    render inertia: 'custos_reais/CustosReaisIndex', props: {
      custos: @custos.limit(100).map { |c| custo_list_json(c) },
      filters: {
        processoId: params[:processo_id],
        categoriaId: params[:categoria_id],
        status: params[:status]
      },
      processoOptions: processo_options,
      categoriaOptions: categoria_options,
      statusOptions: status_options
    }
  end

  def new
    @custo = CustoReal.new(processo_importacao: @processo)
    render inertia: 'custos_reais/CustosReaisForm', props: form_props(@custo)
  end

  def create
    @custo = CustoReal.new(custo_params)
    @custo.criado_por = current_usuario

    # Calcular valor_brl se taxa informada
    if @custo.valor.present? && @custo.taxa_cambio.present? && @custo.taxa_cambio.positive?
      @custo.valor_brl = @custo.valor * @custo.taxa_cambio
    end

    # Calcular desvio se custo previsto vinculado
    calculate_desvio(@custo)

    if @custo.save
      redirect_path = @custo.processo_importacao_id ? processo_importacao_path(@custo.processo_importacao_id) : custos_reais_path
      redirect_to redirect_path, notice: 'Custo real criado com sucesso!'
    else
      redirect_to new_custo_real_path(processo_importacao_id: @custo.processo_importacao_id),
                  inertia: { errors: @custo.errors.to_hash }
    end
  end

  def edit
    render inertia: 'custos_reais/CustosReaisForm', props: form_props(@custo)
  end

  def update
    attrs = custo_params

    # Calcular valor_brl se taxa informada
    if attrs[:valor].present? && attrs[:taxa_cambio].present? && attrs[:taxa_cambio].to_f.positive?
      attrs[:valor_brl] = attrs[:valor].to_f * attrs[:taxa_cambio].to_f
    end

    if @custo.update(attrs)
      calculate_desvio(@custo)
      @custo.save

      redirect_path = @custo.processo_importacao_id ? processo_importacao_path(@custo.processo_importacao_id) : custos_reais_path
      redirect_to redirect_path, notice: 'Custo real atualizado com sucesso!'
    else
      redirect_to edit_custo_real_path(@custo), inertia: { errors: @custo.errors.to_hash }
    end
  end

  def destroy
    processo_id = @custo.processo_importacao_id
    @custo.destroy
    redirect_path = processo_id ? processo_importacao_path(processo_id) : custos_reais_path
    redirect_to redirect_path, notice: 'Custo real excluido com sucesso!'
  end

  # =====================================================
  # AJAX Endpoints para Custos Reais
  # =====================================================

  # GET /processos_importacao/:processo_importacao_id/custos_reais/ajax_list
  def ajax_list
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    custos = @processo.custos_reais
                      .includes(:categoria_custo, :prestador_servico, :custo_previsto)
                      .order('categorias_custo.ordem', 'categorias_custo.nome')

    render json: {
      custos: custos.map { |c| custo_ajax_json(c) },
      total: custos.sum(:valor_brl).to_f,
      categorias: categorias_para_reais,
      prestadores: prestadores_para_select,
      custosPrevistos: custos_previstos_para_select(@processo.id)
    }
  end

  # POST /processos_importacao/:processo_importacao_id/custos_reais/ajax_create
  def ajax_create
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_reais.new(custo_params)
    @custo.criado_por = current_usuario
    @custo.data_lancamento ||= Date.current

    calculate_desvio(@custo)

    if @custo.save
      @processo.consolidar_custos!
      render json: {
        success: true,
        message: 'Custo real adicionado.',
        custo: custo_ajax_json(@custo),
        totais: totais_processo(@processo)
      }
    else
      render json: {
        success: false,
        message: @custo.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # PATCH /processos_importacao/:processo_importacao_id/custos_reais/:id/ajax_update
  def ajax_update
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_reais.find(params[:id])

    if @custo.update(custo_params)
      calculate_desvio(@custo)
      @custo.save
      @processo.consolidar_custos!

      render json: {
        success: true,
        message: 'Custo atualizado.',
        custo: custo_ajax_json(@custo),
        totais: totais_processo(@processo)
      }
    else
      render json: {
        success: false,
        message: @custo.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # DELETE /processos_importacao/:processo_importacao_id/custos_reais/:id/ajax_destroy
  def ajax_destroy
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_reais.find(params[:id])

    @custo.destroy!
    @processo.consolidar_custos!

    render json: {
      success: true,
      message: 'Custo removido.',
      totais: totais_processo(@processo)
    }
  end

  # POST /processos_importacao/:processo_importacao_id/custos_reais/:id/registrar_pagamento
  def registrar_pagamento
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_reais.find(params[:id])

    data_pagamento = params[:data_pagamento].present? ? Date.parse(params[:data_pagamento]) : Date.current

    if @custo.update(data_pagamento: data_pagamento, status_pagamento: 'pago')
      render json: {
        success: true,
        message: 'Pagamento registrado.',
        custo: custo_ajax_json(@custo)
      }
    else
      render json: {
        success: false,
        message: @custo.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # GET /processos_importacao/:processo_importacao_id/custos_reais/categorias_disponiveis
  def categorias_disponiveis
    render json: categorias_para_reais
  end

  private

  def set_custo_real
    @custo = CustoReal.find(params[:id])
  end

  def set_processo
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
  end

  def custo_params
    params.require(:custo_real).permit(
      :processo_importacao_id, :categoria_custo_id, :prestador_servico_id, :custo_previsto_id,
      :descricao, :valor, :moeda, :taxa_cambio, :valor_brl,
      :data_lancamento, :data_vencimento, :data_pagamento, :status_pagamento,
      :numero_documento, :tipo_documento, :observacoes
    )
  end

  def calculate_desvio(custo)
    return unless custo.custo_previsto_id.present? && custo.valor_brl.present?

    previsto = custo.custo_previsto
    return unless previsto&.valor_brl.present? && previsto.valor_brl.positive?

    custo.desvio_valor = custo.valor_brl - previsto.valor_brl
    custo.desvio_percentual = ((custo.valor_brl - previsto.valor_brl) / previsto.valor_brl * 100).round(2)
  end

  def form_props(custo)
    {
      custo: custo.persisted? ? custo_form_json(custo) : { processoImportacaoId: custo.processo_importacao_id },
      processoOptions: processo_options,
      categoriaOptions: categoria_options,
      prestadorOptions: prestador_options,
      moedaOptions: moeda_options,
      statusOptions: status_options,
      custoPrevistoOptions: custo.processo_importacao_id ? custo_previsto_options(custo.processo_importacao_id) : []
    }
  end

  def custo_list_json(custo)
    {
      id: custo.id,
      processoNumero: custo.processo_importacao&.numero,
      processoId: custo.processo_importacao_id,
      categoria: custo.categoria_custo&.nome,
      categoriaId: custo.categoria_custo_id,
      prestador: custo.prestador_servico&.nome,
      descricao: custo.descricao,
      valor: custo.valor&.to_f,
      moeda: custo.moeda,
      valorBrl: custo.valor_brl&.to_f,
      statusPagamento: custo.status_pagamento,
      statusLabel: STATUS_PAGAMENTO[custo.status_pagamento] || custo.status_pagamento,
      dataVencimento: custo.data_vencimento&.iso8601,
      dataPagamento: custo.data_pagamento&.iso8601,
      desvioPercentual: custo.desvio_percentual&.to_f,
      criadoPor: custo.criado_por&.nome,
      createdAt: custo.created_at.iso8601
    }
  end

  def custo_form_json(custo)
    {
      id: custo.id,
      processoImportacaoId: custo.processo_importacao_id,
      categoriaCustoId: custo.categoria_custo_id,
      prestadorServicoId: custo.prestador_servico_id,
      custoPrevistoId: custo.custo_previsto_id,
      descricao: custo.descricao,
      valor: custo.valor&.to_f,
      moeda: custo.moeda,
      taxaCambio: custo.taxa_cambio&.to_f,
      valorBrl: custo.valor_brl&.to_f,
      dataLancamento: custo.data_lancamento&.iso8601,
      dataVencimento: custo.data_vencimento&.iso8601,
      dataPagamento: custo.data_pagamento&.iso8601,
      statusPagamento: custo.status_pagamento,
      numeroDocumento: custo.numero_documento,
      tipoDocumento: custo.tipo_documento,
      observacoes: custo.observacoes
    }
  end

  def processo_options
    ProcessoImportacao.ativos.order(:numero).map { |p| { value: p.id, label: p.numero } }
  end

  def categoria_options
    CategoriaCusto.where(ativo: true).order(:ordem).map { |c| { value: c.id, label: c.nome } }
  end

  def prestador_options
    PrestadorServico.where(ativo: true).order(:nome).map { |p| { value: p.id, label: p.nome } }
  end

  def custo_previsto_options(processo_id)
    CustoPrevisto.where(processo_importacao_id: processo_id)
                 .includes(:categoria_custo)
                 .map { |c| { value: c.id, label: "#{c.categoria_custo&.nome} - R$ #{c.valor_brl&.round(2)}" } }
  end

  def moeda_options
    [
      { value: 'USD', label: 'USD - Dolar' },
      { value: 'EUR', label: 'EUR - Euro' },
      { value: 'BRL', label: 'BRL - Real' }
    ]
  end

  def status_options
    STATUS_PAGAMENTO.map { |k, v| { value: k, label: v } }
  end

  # JSON para endpoints AJAX
  def custo_ajax_json(custo)
    {
      id: custo.id,
      categoriaId: custo.categoria_custo_id,
      categoria: {
        id: custo.categoria_custo.id,
        nome: custo.categoria_custo.nome,
        codigo: custo.categoria_custo.codigo,
        grupo: custo.categoria_custo.grupo
      },
      prestadorId: custo.prestador_servico_id,
      prestador: custo.prestador_servico ? {
        id: custo.prestador_servico.id,
        nome: custo.prestador_servico.nome
      } : nil,
      custoPrevistoId: custo.custo_previsto_id,
      descricao: custo.descricao,
      moeda: custo.moeda,
      valor: custo.valor.to_f,
      valorBrl: custo.valor_brl.to_f,
      taxaCambio: custo.taxa_cambio&.to_f,
      dataLancamento: custo.data_lancamento&.iso8601,
      dataVencimento: custo.data_vencimento&.iso8601,
      dataPagamento: custo.data_pagamento&.iso8601,
      statusPagamento: custo.status_pagamento,
      statusLabel: STATUS_PAGAMENTO[custo.status_pagamento] || custo.status_pagamento,
      numeroDocumento: custo.numero_documento,
      tipoDocumento: custo.tipo_documento,
      desvioValor: custo.desvio_valor&.to_f,
      desvioPercentual: custo.desvio_percentual&.to_f,
      createdAt: custo.created_at.iso8601
    }
  end

  # Categorias disponíveis para custos reais
  def categorias_para_reais
    CategoriaCusto
      .ativos
      .para_reais
      .ordenados
      .map do |cat|
        {
          id: cat.id,
          nome: cat.nome,
          codigo: cat.codigo,
          grupo: cat.grupo,
          grupoNome: cat.grupo_nome,
          obrigatorio: cat.obrigatorio
        }
      end
  end

  # Prestadores para select
  def prestadores_para_select
    PrestadorServico.where(ativo: true).order(:nome).map do |p|
      {
        id: p.id,
        nome: p.nome,
        tipo: p.tipo
      }
    end
  end

  # Custos previstos para vinculação
  def custos_previstos_para_select(processo_id)
    CustoPrevisto.where(processo_importacao_id: processo_id)
                 .includes(:categoria_custo)
                 .where.not(id: CustoReal.where(processo_importacao_id: processo_id).select(:custo_previsto_id))
                 .map do |c|
                   {
                     id: c.id,
                     categoriaId: c.categoria_custo_id,
                     categoria: c.categoria_custo.nome,
                     valorBrl: c.valor_brl.to_f,
                     label: "#{c.categoria_custo.nome} - R$ #{c.valor_brl&.round(2)}"
                   }
                 end
  end

  # Totais do processo para atualização de UI
  def totais_processo(processo)
    processo.reload
    {
      custoPrevistoTotal: processo.custo_previsto_total.to_f,
      custoRealTotal: processo.custo_real_total.to_f,
      desvioAbsoluto: processo.desvio_absoluto.to_f,
      desvioPercentual: processo.desvio_percentual.to_f
    }
  end
end
