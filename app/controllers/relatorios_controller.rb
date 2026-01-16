# frozen_string_literal: true

# Controller para Relatorios do SGICI
# Fornece visões analíticas de processos, custos e fornecedores
class RelatoriosController < InertiaController
  # Skip verify para endpoints AJAX e download (CSRF vem via header X-CSRF-Token)
  skip_before_action :verify_authenticity_token, only: [
    :processos_data, :custos_data, :fornecedores_data,
    :processos_excel, :custos_excel, :fornecedores_excel
  ]
  # GET /relatorios
  def index
    render inertia: 'relatorios/RelatoriosIndex', props: {
      relatorios: available_reports
    }
  end

  # GET /relatorios/processos
  def processos
    render inertia: 'relatorios/RelatoriosProcessos', props: {
      statusOptions: status_options,
      modalOptions: modal_options,
      fornecedoresOptions: fornecedores_options
    }
  end

  # POST /relatorios/processos/data
  def processos_data
    processos = ProcessoImportacao.includes(:fornecedor, :responsavel)

    # Filtros
    processos = processos.where(status: params[:status]) if params[:status].present?
    processos = processos.where(modal: params[:modal]) if params[:modal].present?
    processos = processos.where(fornecedor_id: params[:fornecedor_id]) if params[:fornecedor_id].present?

    if params[:data_inicio].present? && params[:data_fim].present?
      processos = processos.where(created_at: Date.parse(params[:data_inicio])..Date.parse(params[:data_fim]).end_of_day)
    end

    render json: {
      data: processos.map { |p| processo_json(p) },
      totais: calcular_totais(processos)
    }
  end

  # GET /relatorios/custos
  def custos
    render inertia: 'relatorios/RelatoriosCustos', props: {
      categoriaOptions: categoria_options,
      fornecedoresOptions: fornecedores_options
    }
  end

  # POST /relatorios/custos/data
  def custos_data
    categorias = CategoriaCusto.where(ativo: true).order(:ordem)

    # Filtros de período
    data_inicio = params[:data_inicio].present? ? Date.parse(params[:data_inicio]) : Date.current.beginning_of_year
    data_fim = params[:data_fim].present? ? Date.parse(params[:data_fim]) : Date.current

    processos_ids = ProcessoImportacao.where(created_at: data_inicio..data_fim.end_of_day).pluck(:id)

    dados = categorias.filter_map do |cat|
      previsto = CustoPrevisto.where(processo_importacao_id: processos_ids, categoria_custo_id: cat.id).sum(:valor_brl)
      real = CustoReal.where(processo_importacao_id: processos_ids, categoria_custo_id: cat.id).sum(:valor_brl)

      next if previsto.zero? && real.zero?

      variacao = previsto.positive? ? ((real - previsto) / previsto * 100).round(2) : 0.0

      {
        categoria: cat.nome,
        previsto: previsto.to_f,
        real: real.to_f,
        variacao: variacao.to_f
      }
    end

    render json: {
      data: dados,
      periodo: { inicio: data_inicio.iso8601, fim: data_fim.iso8601 }
    }
  end

  # GET /relatorios/fornecedores
  def fornecedores
    render inertia: 'relatorios/RelatoriosFornecedores', props: {
      paisOptions: pais_options
    }
  end

  # POST /relatorios/fornecedores/data
  def fornecedores_data
    fornecedores = Fornecedor.where(ativo: true).order(:nome)
    fornecedores = fornecedores.where(pais: params[:pais]) if params[:pais].present?

    # Agregacoes em uma unica query para evitar N+1
    stats = ProcessoImportacao
      .where(fornecedor_id: fornecedores.select(:id))
      .group(:fornecedor_id)
      .select(
        :fornecedor_id,
        'COUNT(*) as total_processos',
        "COUNT(*) FILTER (WHERE status NOT IN ('finalizado', 'cancelado')) as processos_ativos",
        'COALESCE(SUM(valor_fob), 0) as valor_total_fob',
        "AVG(lead_time_dias) FILTER (WHERE status = 'finalizado' AND lead_time_dias IS NOT NULL) as lead_time_medio",
        "AVG(desvio_percentual) FILTER (WHERE status = 'finalizado' AND desvio_percentual IS NOT NULL) as desvio_medio"
      )
      .index_by(&:fornecedor_id)

    dados = fornecedores.map do |f|
      s = stats[f.id]
      {
        id: f.id,
        nome: f.nome,
        pais: f.pais,
        totalProcessos: s&.total_processos || 0,
        processosAtivos: s&.processos_ativos || 0,
        valorTotalFob: s&.valor_total_fob.to_f,
        leadTimeMedio: s&.lead_time_medio&.to_f&.round(1) || 0,
        desvioMedio: s&.desvio_medio&.to_f&.round(2) || 0,
        score: f.score&.to_f || 0
      }
    end

    render json: dados
  end

  # =====================================================
  # Exportacao Excel
  # =====================================================

  # GET /relatorios/processos/excel
  def processos_excel
    processos = ProcessoImportacao.includes(:fornecedor, :responsavel)

    # Filtros
    processos = processos.where(status: params[:status]) if params[:status].present?
    processos = processos.where(modal: params[:modal]) if params[:modal].present?
    processos = processos.where(fornecedor_id: params[:fornecedor_id]) if params[:fornecedor_id].present?

    data_inicio = params[:data_inicio].present? ? Date.parse(params[:data_inicio]) : Date.current.beginning_of_year
    data_fim = params[:data_fim].present? ? Date.parse(params[:data_fim]) : Date.current

    processos = processos.where(created_at: data_inicio..data_fim.end_of_day)

    @dados = processos.map do |p|
      {
        numero: p.numero,
        fornecedor: p.fornecedor.nome,
        status_label: ProcessoImportacao::STATUSES[p.status],
        modal_label: ProcessoImportacao::MODAIS[p.modal],
        valor_fob: p.valor_fob,
        custo_previsto_total: p.custo_previsto_total,
        custo_real_total: p.custo_real_total,
        desvio_percentual: p.desvio_percentual,
        lead_time_dias: p.lead_time_dias,
        created_at: p.created_at
      }
    end

    @periodo = { inicio: data_inicio, fim: data_fim }

    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"relatorio_processos_#{Date.current.strftime('%Y%m%d')}.xlsx\""
      }
    end
  end

  # GET /relatorios/custos/excel
  def custos_excel
    categorias = CategoriaCusto.where(ativo: true).order(:ordem)

    data_inicio = params[:data_inicio].present? ? Date.parse(params[:data_inicio]) : Date.current.beginning_of_year
    data_fim = params[:data_fim].present? ? Date.parse(params[:data_fim]) : Date.current

    processos_ids = ProcessoImportacao.where(created_at: data_inicio..data_fim.end_of_day).pluck(:id)

    @dados = categorias.filter_map do |cat|
      previsto = CustoPrevisto.where(processo_importacao_id: processos_ids, categoria_custo_id: cat.id).sum(:valor_brl)
      real = CustoReal.where(processo_importacao_id: processos_ids, categoria_custo_id: cat.id).sum(:valor_brl)

      next if previsto.zero? && real.zero?

      variacao = previsto.positive? ? ((real - previsto) / previsto * 100).round(2) : 0.0

      {
        categoria: cat.nome,
        previsto: previsto.to_f,
        real: real.to_f,
        variacao: variacao.to_f
      }
    end

    @periodo = { inicio: data_inicio, fim: data_fim }

    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"relatorio_custos_#{Date.current.strftime('%Y%m%d')}.xlsx\""
      }
    end
  end

  # GET /relatorios/fornecedores/excel
  def fornecedores_excel
    fornecedores = Fornecedor.where(ativo: true).order(:nome)
    fornecedores = fornecedores.where(pais: params[:pais]) if params[:pais].present?

    @dados = fornecedores.map do |f|
      processos = f.processos_importacao
      finalizados = processos.where(status: 'finalizado')

      {
        nome: f.nome,
        pais: f.pais,
        total_processos: processos.count,
        processos_ativos: processos.where.not(status: ['finalizado', 'cancelado']).count,
        valor_total_fob: processos.sum(:valor_fob).to_f,
        lead_time_medio: finalizados.where.not(lead_time_dias: nil).average(:lead_time_dias)&.to_f&.round(1) || 0,
        desvio_medio: finalizados.where.not(desvio_percentual: nil).average(:desvio_percentual)&.to_f&.round(2) || 0,
        score: f.score
      }
    end

    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"relatorio_fornecedores_#{Date.current.strftime('%Y%m%d')}.xlsx\""
      }
    end
  end

  private

  def available_reports
    [
      { id: 'processos', nome: 'Relatorio de Processos', descricao: 'Visao geral dos processos de importacao', href: '/relatorios/processos' },
      { id: 'custos', nome: 'Analise de Custos', descricao: 'Comparativo de custos previstos vs reais', href: '/relatorios/custos' },
      { id: 'fornecedores', nome: 'Performance Fornecedores', descricao: 'Indicadores de desempenho por fornecedor', href: '/relatorios/fornecedores' }
    ]
  end

  def processo_json(processo)
    {
      id: processo.id,
      numero: processo.numero,
      fornecedor: processo.fornecedor.nome,
      status: processo.status,
      statusLabel: ProcessoImportacao::STATUSES[processo.status],
      modal: processo.modal,
      valorFob: processo.valor_fob&.to_f,
      custoPrevistoTotal: processo.custo_previsto_total&.to_f,
      custoRealTotal: processo.custo_real_total&.to_f,
      desvioPercentual: processo.desvio_percentual&.to_f,
      leadTimeDias: processo.lead_time_dias,
      createdAt: processo.created_at.iso8601
    }
  end

  def calcular_totais(processos)
    {
      quantidade: processos.count,
      valorFobTotal: processos.sum(:valor_fob).to_f,
      custoPrevistoTotal: processos.sum(:custo_previsto_total).to_f,
      custoRealTotal: processos.sum(:custo_real_total).to_f
    }
  end

  def status_options
    ProcessoImportacao::STATUSES.map { |k, v| { value: k, label: v } }
  end

  def modal_options
    ProcessoImportacao::MODAIS.map { |k, v| { value: k, label: v } }
  end

  def fornecedores_options
    Fornecedor.where(ativo: true).order(:nome).map { |f| { value: f.id, label: f.nome } }
  end

  def categoria_options
    CategoriaCusto.where(ativo: true).order(:ordem).map { |c| { value: c.id, label: c.nome } }
  end

  def pais_options
    Fornecedor.where(ativo: true).distinct.pluck(:pais).compact.sort.map { |p| { value: p, label: p } }
  end
end
