# frozen_string_literal: true

# Controller para Custos Previstos
# Gerencia custos previstos de forma standalone (listagem geral) e nested (por processo)
class CustosPrevistosController < InertiaController
  before_action :set_custo_previsto, only: [:edit, :update, :destroy]
  before_action :set_processo, only: [:new, :create], if: -> { params[:processo_importacao_id].present? }

  def index
    @custos = CustoPrevisto.includes(:processo_importacao, :categoria_custo, :criado_por)
                           .order(created_at: :desc)

    # Filtros
    @custos = @custos.where(processo_importacao_id: params[:processo_id]) if params[:processo_id].present?
    @custos = @custos.where(categoria_custo_id: params[:categoria_id]) if params[:categoria_id].present?

    render inertia: 'custos_previstos/CustosPrevistosIndex', props: {
      custos: @custos.limit(100).map { |c| custo_list_json(c) },
      filters: {
        processoId: params[:processo_id],
        categoriaId: params[:categoria_id]
      },
      processoOptions: processo_options,
      categoriaOptions: categoria_options
    }
  end

  def new
    @custo = CustoPrevisto.new(processo_importacao: @processo)
    render inertia: 'custos_previstos/CustosPrevistosForm', props: form_props(@custo)
  end

  def create
    @custo = CustoPrevisto.new(custo_params)
    @custo.criado_por = current_usuario

    # Calcular valor_brl se taxa informada
    if @custo.valor.present? && @custo.taxa_cambio.present? && @custo.taxa_cambio.positive?
      @custo.valor_brl = @custo.valor * @custo.taxa_cambio
    end

    if @custo.save
      redirect_path = @custo.processo_importacao_id ? processo_importacao_path(@custo.processo_importacao_id) : custos_previstos_path
      redirect_to redirect_path, notice: 'Custo previsto criado com sucesso!'
    else
      redirect_to new_custo_previsto_path(processo_importacao_id: @custo.processo_importacao_id),
                  inertia: { errors: @custo.errors.to_hash }
    end
  end

  def edit
    render inertia: 'custos_previstos/CustosPrevistosForm', props: form_props(@custo)
  end

  def update
    # Calcular valor_brl se taxa informada
    attrs = custo_params
    if attrs[:valor].present? && attrs[:taxa_cambio].present? && attrs[:taxa_cambio].to_f.positive?
      attrs[:valor_brl] = attrs[:valor].to_f * attrs[:taxa_cambio].to_f
    end

    if @custo.update(attrs)
      redirect_path = @custo.processo_importacao_id ? processo_importacao_path(@custo.processo_importacao_id) : custos_previstos_path
      redirect_to redirect_path, notice: 'Custo previsto atualizado com sucesso!'
    else
      redirect_to edit_custo_previsto_path(@custo), inertia: { errors: @custo.errors.to_hash }
    end
  end

  def destroy
    processo_id = @custo.processo_importacao_id
    @custo.destroy
    redirect_path = processo_id ? processo_importacao_path(processo_id) : custos_previstos_path
    redirect_to redirect_path, notice: 'Custo previsto excluido com sucesso!'
  end

  # =====================================================
  # AJAX Endpoints para Custos Previstos
  # =====================================================

  # POST /processos_importacao/:processo_importacao_id/custos_previstos/ajax_create
  # Cria custo previsto via AJAX
  def ajax_create
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_previstos.new(custo_params)
    @custo.criado_por = current_usuario

    if @custo.save
      render json: {
        success: true,
        message: 'Custo previsto adicionado.',
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

  # PATCH /processos_importacao/:processo_importacao_id/custos_previstos/:id/ajax_update
  # Atualiza custo previsto via AJAX
  def ajax_update
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_previstos.find(params[:id])

    if @custo.update(custo_params)
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

  # DELETE /processos_importacao/:processo_importacao_id/custos_previstos/:id/ajax_destroy
  # Remove custo previsto via AJAX
  def ajax_destroy
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    @custo = @processo.custos_previstos.find(params[:id])

    if @custo.realizado?
      render json: {
        success: false,
        message: 'Não é possível excluir: custo já possui lançamento real vinculado.'
      }, status: :unprocessable_entity
      return
    end

    @custo.destroy!
    render json: {
      success: true,
      message: 'Custo removido.',
      totais: totais_processo(@processo)
    }
  end

  # GET /processos_importacao/:processo_importacao_id/custos_previstos/ajax_list
  # Lista custos previstos via AJAX
  def ajax_list
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
    custos = @processo.custos_previstos
                      .includes(:categoria_custo)
                      .order('categorias_custo.ordem', 'categorias_custo.nome')

    render json: {
      custos: custos.map { |c| custo_ajax_json(c) },
      total: custos.sum(:valor_brl).to_f,
      categorias: categorias_para_previstos
    }
  end

  # POST /processos_importacao/:processo_importacao_id/custos_previstos/calcular_impostos
  # Calcula impostos automaticamente com base em FOB, frete e seguro (preview)
  def calcular_impostos
    fob = params[:fob].to_d
    frete = params[:frete].to_d
    seguro = params[:seguro].to_d
    taxa_cambio = params[:taxa_cambio].to_d

    if fob.zero?
      render json: { success: false, message: 'FOB é obrigatório' }, status: :unprocessable_entity
      return
    end

    calculadora = CalculadoraImpostosService.new(
      fob: fob,
      frete: frete,
      seguro: seguro,
      taxa_cambio: taxa_cambio,
      aliquotas: aliquotas_params
    )

    render json: {
      success: true,
      calculo: calculadora.calcular
    }
  end

  # POST /processos_importacao/:processo_importacao_id/custos_previstos/gerar_impostos
  # Gera custos previstos de impostos automaticamente e salva no banco
  def gerar_impostos
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])

    fob = params[:fob].to_d
    frete = params[:frete].to_d
    seguro = params[:seguro].to_d
    taxa_cambio = params[:taxa_cambio].to_d

    if fob.zero?
      render json: { success: false, message: 'FOB é obrigatório para calcular impostos' }, status: :unprocessable_entity
      return
    end

    calculadora = CalculadoraImpostosService.new(
      fob: fob,
      frete: frete,
      seguro: seguro,
      taxa_cambio: taxa_cambio,
      aliquotas: aliquotas_params
    )

    custos_data = calculadora.custos_previstos_para_criar(@processo, current_usuario)

    ActiveRecord::Base.transaction do
      # Remove impostos calculados anteriormente (para recalcular)
      codigos_impostos = %w[II IPI PIS_COFINS ICMS]
      @processo.custos_previstos
               .joins(:categoria_custo)
               .where(categorias_custo: { codigo: codigos_impostos })
               .destroy_all

      # Cria novos custos de impostos
      custos_data.each do |custo_attrs|
        @processo.custos_previstos.create!(custo_attrs)
      end
    end

    @processo.consolidar_custos!

    render json: {
      success: true,
      message: 'Impostos calculados e adicionados com sucesso.',
      custos: @processo.custos_previstos.includes(:categoria_custo).map { |c| custo_ajax_json(c) },
      totais: totais_processo(@processo),
      calculo: calculadora.calcular
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      success: false,
      message: "Erro ao gerar impostos: #{e.message}"
    }, status: :unprocessable_entity
  end

  # GET /processos_importacao/:processo_importacao_id/custos_previstos/categorias_disponiveis
  # Retorna categorias disponíveis para custos previstos
  def categorias_disponiveis
    render json: categorias_para_previstos
  end

  private

  def set_custo_previsto
    @custo = CustoPrevisto.find(params[:id])
  end

  def set_processo
    @processo = ProcessoImportacao.find(params[:processo_importacao_id])
  end

  def custo_params
    params.require(:custo_previsto).permit(
      :processo_importacao_id, :categoria_custo_id, :descricao,
      :valor, :moeda, :taxa_cambio, :valor_brl,
      :data_previsao, :observacoes, :base_calculo, :percentual, :valor_referencia
    )
  end

  def form_props(custo)
    {
      custo: custo.persisted? ? custo_form_json(custo) : { processoImportacaoId: custo.processo_importacao_id },
      processoOptions: processo_options,
      categoriaOptions: categoria_options,
      moedaOptions: moeda_options
    }
  end

  def custo_list_json(custo)
    {
      id: custo.id,
      processoNumero: custo.processo_importacao&.numero,
      processoId: custo.processo_importacao_id,
      categoria: custo.categoria_custo&.nome,
      categoriaId: custo.categoria_custo_id,
      descricao: custo.descricao,
      valor: custo.valor&.to_f,
      moeda: custo.moeda,
      taxaCambio: custo.taxa_cambio&.to_f,
      valorBrl: custo.valor_brl&.to_f,
      dataPrevisao: custo.data_previsao&.iso8601,
      criadoPor: custo.criado_por&.nome,
      createdAt: custo.created_at.iso8601
    }
  end

  def custo_form_json(custo)
    {
      id: custo.id,
      processoImportacaoId: custo.processo_importacao_id,
      categoriaCustoId: custo.categoria_custo_id,
      descricao: custo.descricao,
      valor: custo.valor&.to_f,
      moeda: custo.moeda,
      taxaCambio: custo.taxa_cambio&.to_f,
      valorBrl: custo.valor_brl&.to_f,
      dataPrevisao: custo.data_previsao&.iso8601,
      observacoes: custo.observacoes,
      baseCalculo: custo.base_calculo,
      percentual: custo.percentual&.to_f,
      valorReferencia: custo.valor_referencia&.to_f
    }
  end

  def processo_options
    ProcessoImportacao.ativos.order(:numero).map { |p| { value: p.id, label: p.numero } }
  end

  def categoria_options
    CategoriaCusto.where(ativo: true).order(:ordem).map { |c| { value: c.id, label: c.nome } }
  end

  def moeda_options
    [
      { value: 'USD', label: 'USD - Dolar' },
      { value: 'EUR', label: 'EUR - Euro' },
      { value: 'BRL', label: 'BRL - Real' },
      { value: 'CNY', label: 'CNY - Yuan' },
      { value: 'GBP', label: 'GBP - Libra' },
      { value: 'JPY', label: 'JPY - Yen' }
    ]
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
      descricao: custo.descricao,
      moeda: custo.moeda,
      valor: custo.valor.to_f,
      valorBrl: custo.valor_brl.to_f,
      taxaCambio: custo.taxa_cambio&.to_f,
      dataPrevisao: custo.data_previsao&.iso8601,
      realizado: custo.realizado?,
      createdAt: custo.created_at.iso8601
    }
  end

  # Categorias disponíveis para custos previstos
  def categorias_para_previstos
    CategoriaCusto
      .ativos
      .para_previstos
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

  # Parâmetros de alíquotas para cálculo de impostos
  def aliquotas_params
    return {} unless params[:aliquotas].present?

    params[:aliquotas].permit(:ii, :ipi, :pis_cofins, :icms).to_h.transform_values(&:to_d)
  end
end
