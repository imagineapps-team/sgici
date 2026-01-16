# frozen_string_literal: true

# Dashboard Controller para SGICI
# Fornece metricas e KPIs de processos de importacao
class DashboardController < InertiaController
  def index
    render inertia: 'dashboard/DashboardIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      filtrosPadrao: {
        dataInicial: Date.current.beginning_of_month.to_s,
        dataFinal: Date.current.end_of_month.to_s
      }
    }
  end

  # Endpoint AJAX para buscar metricas do dashboard
  def metrics
    data_inicial = parse_date(params[:data_inicial]) || Date.current.beginning_of_month
    data_final = parse_date(params[:data_final]) || Date.current.end_of_month

    render json: {
      periodo: { inicio: data_inicial.iso8601, fim: data_final.iso8601 },
      kpis: calcular_kpis(data_inicial, data_final),
      processosPorStatus: processos_por_status,
      custosComparativo: custos_comparativo(data_inicial, data_final),
      proximasChegadas: proximas_chegadas,
      processosAtrasados: processos_atrasados,
      ultimosProcessos: ultimos_processos
    }
  end

  # Endpoint AJAX para buscar apenas KPIs (atualizacao parcial)
  def kpis
    data_inicial = parse_date(params[:data_inicial]) || Date.current.beginning_of_month
    data_final = parse_date(params[:data_final]) || Date.current.end_of_month

    render json: calcular_kpis(data_inicial, data_final)
  end

  # Mantido para compatibilidade, retorna dados vazios
  def indicadores_ambientais
    render json: {}
  end

  # Endpoint para dados de custos por categoria
  def por_categoria
    data_inicial = parse_date(params[:data_inicial]) || Date.current.beginning_of_month
    data_final = parse_date(params[:data_final]) || Date.current.end_of_month

    render json: custos_comparativo(data_inicial, data_final)
  end

  # Endpoint para evolucao temporal
  def evolucao
    meses = params[:meses]&.to_i || 6

    render json: evolucao_processos(meses)
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?

    if date_string.include?('/')
      Date.strptime(date_string, '%d/%m/%Y')
    else
      Date.parse(date_string)
    end
  rescue ArgumentError
    nil
  end

  # Calcula KPIs principais
  def calcular_kpis(data_inicial, data_final)
    processos_ativos = ProcessoImportacao.ativos.count
    processos_em_transito = ProcessoImportacao.em_transito.count

    # Valor em transito (FOB em USD)
    valor_transito = ProcessoImportacao.em_transito.sum(:valor_fob) || 0

    # Variacao media de custos (processos finalizados no periodo)
    processos_finalizados = ProcessoImportacao
                              .finalizados
                              .where(data_finalizacao: data_inicial..data_final)

    variacao_media = if processos_finalizados.any?
                       processos_finalizados.average(:desvio_percentual)&.to_f || 0
                     else
                       0
                     end

    # Alertas: processos atrasados
    alertas = ProcessoImportacao.ativos.select(&:atrasado?).count

    # Lead time medio (processos finalizados no periodo)
    lead_time = processos_finalizados.where.not(lead_time_dias: nil).average(:lead_time_dias)&.to_f || 0

    {
      processosAtivos: processos_ativos,
      processosEmTransito: processos_em_transito,
      valorEmTransitoUsd: valor_transito.to_f,
      variacaoMediaCusto: variacao_media.round(2),
      alertasPendentes: alertas,
      leadTimeMedio: lead_time.round(1)
    }
  end

  # Processos agrupados por status
  def processos_por_status
    statuses = ProcessoImportacao::STATUSES

    statuses.map do |key, label|
      processos = ProcessoImportacao.where(status: key)
      {
        status: key,
        statusLabel: label,
        total: processos.count,
        valorTotal: (processos.sum(:valor_fob) || 0).to_f
      }
    end
  end

  # Comparativo de custos por categoria
  def custos_comparativo(data_inicial, data_final)
    categorias = CategoriaCusto.where(ativo: true).order(:ordem)

    processos_ids = ProcessoImportacao
                      .where(created_at: data_inicial.beginning_of_day..data_final.end_of_day)
                      .pluck(:id)

    return [] if processos_ids.empty?

    categorias.filter_map do |cat|
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
  end

  # Proximas chegadas previstas
  def proximas_chegadas
    ProcessoImportacao
      .ativos
      .where.not(data_chegada_prevista: nil)
      .where('data_chegada_prevista >= ?', Date.current)
      .order(:data_chegada_prevista)
      .limit(5)
      .map { |p| processo_resumo(p) }
  end

  # Processos atrasados
  def processos_atrasados
    ProcessoImportacao
      .ativos
      .select(&:atrasado?)
      .sort_by { |p| p.dias_atraso || 0 }
      .reverse
      .first(5)
      .map { |p| processo_resumo(p) }
  end

  # Ultimos processos criados
  def ultimos_processos
    ProcessoImportacao
      .includes(:fornecedor)
      .order(created_at: :desc)
      .limit(5)
      .map { |p| processo_resumo(p) }
  end

  # Evolucao de processos por mes
  def evolucao_processos(meses)
    resultado = []
    meses.times do |i|
      mes_ref = i.months.ago.beginning_of_month
      mes_fim = mes_ref.end_of_month

      criados = ProcessoImportacao.where(created_at: mes_ref..mes_fim).count
      finalizados = ProcessoImportacao.finalizados.where(data_finalizacao: mes_ref..mes_fim).count

      resultado.unshift({
        periodo: mes_ref.strftime('%b/%y'),
        criados: criados,
        finalizados: finalizados
      })
    end

    resultado
  end

  # JSON resumido de processo
  def processo_resumo(processo)
    dias_para_chegada = if processo.data_chegada_prevista && !processo.data_chegada_real
                          (processo.data_chegada_prevista - Date.current).to_i
                        end

    {
      id: processo.id,
      numero: processo.numero,
      fornecedor: processo.fornecedor.nome,
      status: processo.status,
      statusLabel: ProcessoImportacao::STATUSES[processo.status],
      dataChegadaPrevista: processo.data_chegada_prevista&.iso8601,
      diasParaChegada: dias_para_chegada,
      atrasado: processo.atrasado?,
      valorFob: processo.valor_fob&.to_f
    }
  end
end
