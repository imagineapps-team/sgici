# frozen_string_literal: true

class DashboardController < InertiaController
  def index
    render inertia: 'dashboard/DashboardIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      indicadores: indicadores_config,
      filtrosPadrao: {
        dataInicial: Date.current.beginning_of_month.to_s,
        dataFinal: Date.current.end_of_month.to_s
      }
    }
  end

  # Endpoint AJAX para buscar métricas do dashboard
  def metrics
    service = Dashboard::MetricsService.new(
      data_inicial: parse_date(params[:data_inicial]),
      data_final: parse_date(params[:data_final])
    )

    render json: service.call
  end

  # Endpoint AJAX para buscar apenas KPIs (atualização parcial)
  def kpis
    service = Dashboard::MetricsService.new(
      data_inicial: parse_date(params[:data_inicial]),
      data_final: parse_date(params[:data_final])
    )

    render json: service.calcular_kpis
  end

  # Endpoint AJAX para buscar indicadores ambientais
  def indicadores_ambientais
    service = Dashboard::MetricsService.new(
      data_inicial: parse_date(params[:data_inicial]),
      data_final: parse_date(params[:data_final])
    )

    render json: service.calcular_indicadores_ambientais
  end

  # Endpoint AJAX para buscar dados por categoria
  def por_categoria
    service = Dashboard::MetricsService.new(
      data_inicial: parse_date(params[:data_inicial]),
      data_final: parse_date(params[:data_final])
    )

    render json: service.dados_por_categoria
  end

  # Endpoint AJAX para buscar evolução temporal
  def evolucao
    service = Dashboard::MetricsService.new(
      data_inicial: parse_date(params[:data_inicial]),
      data_final: parse_date(params[:data_final])
    )

    render json: service.dados_evolucao(meses: params[:meses]&.to_i || 12)
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?

    # Aceita formato brasileiro (dd/mm/yyyy) ou ISO (yyyy-mm-dd)
    if date_string.include?('/')
      Date.strptime(date_string, '%d/%m/%Y')
    else
      Date.parse(date_string)
    end
  rescue ArgumentError
    nil
  end

  # Configuração dos indicadores para o frontend
  def indicadores_config
    {
      co2e: {
        icone: 'co2',
        label: 'CO₂ Evitado',
        descricao: 'evitados em emissão de CO2'
      },
      arvores: {
        icone: 'arvore',
        label: 'Árvores',
        descricao: 'seriam necessárias para sequestrar o CO2 evitado ao longo de 1 ano'
      },
      km_evitados: {
        icone: 'carro',
        label: 'KM Evitados',
        descricao: 'deixaram de ser percorridos por um automóvel padrão'
      },
      tempo_banho: {
        icone: 'chuveiro',
        label: 'Tempo de Banho',
        descricao: 'de banho poupado usando um chuveiro elétrico'
      },
      tempo_ar: {
        icone: 'ar-condicionado',
        label: 'Tempo AC',
        descricao: 'de uso poupados de um Ar Condicionado 9.000 BTU'
      },
      tempo_lampada: {
        icone: 'lampada-led',
        label: 'Tempo Lâmpada',
        descricao: 'de uso poupados de uma lâmpada LED acesa'
      },
      tempo_tv: {
        icone: 'televisao',
        label: 'Tempo TV',
        descricao: 'de uso poupados de uma TV'
      },
      agua_economizada: {
        icone: 'agua',
        label: 'Água Economizada',
        descricao: 'de água economizada na reciclagem de papel'
      },
      piscinas: {
        icone: 'piscina',
        label: 'Piscinas Olímpicas',
        descricao: 'piscinas olímpicas de água economizada'
      },
      carvao_evitado: {
        icone: 'carvao',
        label: 'Carvão Evitado',
        descricao: 'de carvão que deixaram de ser queimados'
      }
    }
  end
end
