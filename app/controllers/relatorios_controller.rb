

# frozen_string_literal: true

class RelatoriosController < ApplicationController
  before_action :set_filters, only: [
    :historico_eventos, :historico_eventos_data,
    :historico_participacao, :historico_participacao_data,
    :historico_residuos_data
  ]

  # GET /relatorios
  # Menu principal de relatórios
  def index
    render inertia: 'relatorios/RelatoriosIndex', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      relatorios: available_reports
    }
  end

  # GET /relatorios/historico_eventos
  # Página do relatório com filtros
  def historico_eventos
    render inertia: 'relatorios/HistoricoEventos', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      acoes: acoes_options,
      comunidades: comunidades_options,
      modelos: modelos_options,
      statusOptions: status_options
    }
  end

  # POST /relatorios/historico_eventos/data
  # Retorna dados JSON para o DataTable
  def historico_eventos_data
    result = Relatorios::HistoricoEventosQuery.new(@filters).execute
    render json: result
  end

  # GET /relatorios/historico_eventos/excel
  # Gera Excel
  def historico_eventos_excel
    @dados = Relatorios::HistoricoEventosQuery.new(filter_params).execute
    @titulo = 'Histórico por Ação'
    filename = "historico_por_acao_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/historico_eventos_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/historico_eventos/pdf
  # Gera PDF via Grover
  def historico_eventos_pdf
    @dados = Relatorios::HistoricoEventosQuery.new(filter_params).execute
    @titulo = 'Histórico por Ação'
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/historico_eventos_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "historico_por_acao_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ==================== HISTÓRICO DE PARTICIPAÇÃO ====================

  # GET /relatorios/historico_participacao
  def historico_participacao
    render inertia: 'relatorios/HistoricoParticipacao', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      eventos: eventos_options,
      modelos: participacao_modelos_options,
      statusOptions: status_options
    }
  end

  # POST /relatorios/historico_participacao/data
  def historico_participacao_data
    result = Relatorios::HistoricoParticipacaoQuery.new(participacao_filter_params).execute
    render json: result
  end

  # GET /relatorios/historico_participacao/excel
  def historico_participacao_excel
    @dados = Relatorios::HistoricoParticipacaoQuery.new(participacao_filter_params).execute
    @modelo = participacao_filter_params[:modelo] || 'DG'
    @titulo = @modelo == 'AR' ? 'Histórico de Participação - Agrupado por Resíduo' : 'Histórico de Participação - Dados Gerais'
    filename = "historico_participacao_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/historico_participacao_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/historico_participacao/pdf
  def historico_participacao_pdf
    @dados = Relatorios::HistoricoParticipacaoQuery.new(participacao_filter_params).execute
    @modelo = participacao_filter_params[:modelo] || 'DG'
    @titulo = @modelo == 'AR' ? 'Histórico de Participação - Agrupado por Resíduo' : 'Histórico de Participação - Dados Gerais'
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/historico_participacao_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao, modelo: @modelo }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "historico_participacao_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ==================== HISTÓRICO DE RESÍDUOS ====================

  # GET /relatorios/historico_residuos
  def historico_residuos
    render inertia: 'relatorios/HistoricoResiduos', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      acoes: acoes_options,
      comunidades: comunidades_options,
      recursos: recursos_options,
      modelos: residuos_modelos_options,
      statusOptions: status_options
    }
  end

  # POST /relatorios/historico_residuos/data
  def historico_residuos_data
    result = Relatorios::HistoricoResiduosQuery.new(residuos_filter_params).execute
    render json: result
  end

  # GET /relatorios/historico_residuos/excel
  def historico_residuos_excel
    @dados = Relatorios::HistoricoResiduosQuery.new(residuos_filter_params).execute
    @modelo = residuos_filter_params[:modelo] || 'RR'
    @titulo = @modelo == 'RT' ? 'Histórico de Resíduos - Por Tipologia' : 'Histórico de Resíduos - Detalhado'
    filename = "historico_residuos_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/historico_residuos_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/historico_residuos/pdf
  def historico_residuos_pdf
    @dados = Relatorios::HistoricoResiduosQuery.new(residuos_filter_params).execute
    @modelo = residuos_filter_params[:modelo] || 'RR'
    @titulo = @modelo == 'RT' ? 'Histórico de Resíduos - Por Tipologia' : 'Histórico de Resíduos - Detalhado'
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/historico_residuos_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao, modelo: @modelo }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "historico_residuos_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ==================== HISTÓRICO RECICLADOR POR EVENTO ====================

  # GET /relatorios/historico_reciclador_evento
  def historico_reciclador_evento
    render inertia: 'relatorios/HistoricoRecicladorEvento', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      eventos: eventos_options,
      recicladores: recicladores_options,
      statusOptions: status_options
    }
  end

  # POST /relatorios/historico_reciclador_evento/data
  def historico_reciclador_evento_data
    result = Relatorios::HistoricoRecicladorEventoQuery.new(reciclador_evento_filter_params).execute
    render json: result
  end

  # GET /relatorios/historico_reciclador_evento/excel
  def historico_reciclador_evento_excel
    result = Relatorios::HistoricoRecicladorEventoQuery.new(reciclador_evento_filter_params).execute
    @dados = result[:data]
    @totais = result[:totais]
    @titulo = 'Histórico Reciclador por Evento'
    filename = "historico_reciclador_evento_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/historico_reciclador_evento_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/historico_reciclador_evento/pdf
  def historico_reciclador_evento_pdf
    result = Relatorios::HistoricoRecicladorEventoQuery.new(reciclador_evento_filter_params).execute
    @dados = result[:data]
    @totais = result[:totais]
    @titulo = 'Histórico Reciclador por Evento'
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/historico_reciclador_evento_pdf',
      layout: 'pdf',
      locals: { dados: @dados, totais: @totais, titulo: @titulo, data_geracao: @data_geracao }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "historico_reciclador_evento_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ==================== FATURA DO RECICLADOR ====================

  # GET /relatorios/historico_fatura_reciclador
  def historico_fatura_reciclador
    render inertia: 'relatorios/HistoricoFaturaReciclador', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      recicladores: recicladores_options,
      recursos: recursos_options,
      modelos: fatura_reciclador_modelos_options
    }
  end

  # POST /relatorios/historico_fatura_reciclador/data
  def historico_fatura_reciclador_data
    result = Relatorios::HistoricoFaturaRecicladorQuery.new(fatura_reciclador_filter_params).execute
    render json: result
  end

  # GET /relatorios/historico_fatura_reciclador/excel
  def historico_fatura_reciclador_excel
    @dados = Relatorios::HistoricoFaturaRecicladorQuery.new(fatura_reciclador_filter_params).execute
    @modelo = fatura_reciclador_filter_params[:modelo] || 'TR'
    @titulo = @modelo == 'RC' ? 'Fatura do Reciclador - Repasse à Concessionária' : 'Fatura do Reciclador - Total por Resíduo'
    filename = "fatura_reciclador_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/historico_fatura_reciclador_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/historico_fatura_reciclador/pdf
  def historico_fatura_reciclador_pdf
    @dados = Relatorios::HistoricoFaturaRecicladorQuery.new(fatura_reciclador_filter_params).execute
    @modelo = fatura_reciclador_filter_params[:modelo] || 'TR'
    @titulo = @modelo == 'RC' ? 'Fatura do Reciclador - Repasse à Concessionária' : 'Fatura do Reciclador - Total por Resíduo'
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/historico_fatura_reciclador_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao, modelo: @modelo }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "fatura_reciclador_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ==================== CAMPANHAS ====================

  # GET /relatorios/campanhas
  def campanhas
    render inertia: 'relatorios/Campanhas', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      campanhas: campanhas_options,
      modelos: campanhas_modelos_options
    }
  end

  # POST /relatorios/campanhas/data
  def campanhas_data
    result = Relatorios::CampanhasQuery.new(campanhas_filter_params).execute
    render json: result
  end

  # GET /relatorios/campanhas/excel
  def campanhas_excel
    @dados = Relatorios::CampanhasQuery.new(campanhas_filter_params).execute
    @modelo = campanhas_filter_params[:modelo] || 'RT'
    @titulo = titulo_campanhas(@modelo)
    filename = "campanhas_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/campanhas_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/campanhas/pdf
  def campanhas_pdf
    @dados = Relatorios::CampanhasQuery.new(campanhas_filter_params).execute
    @modelo = campanhas_filter_params[:modelo] || 'RT'
    @titulo = titulo_campanhas(@modelo)
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/campanhas_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao, modelo: @modelo }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "campanhas_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # ========== Relatorio de Veiculos ==========

  # GET /relatorios/veiculos
  def veiculos
    render inertia: 'relatorios/Veiculos', props: {
      usuario: current_usuario.as_json(only: [:id, :login, :nome]),
      tipoVeiculos: tipo_veiculos_options,
      veiculosPlacas: veiculos_placas_options,
      tipoRecursos: tipo_recursos_options,
      locais: locais_options,
      modelos: veiculos_modelos_options,
      statusOptions: veiculos_status_options
    }
  end

  # POST /relatorios/veiculos/data
  def veiculos_data
    result = Relatorios::VeiculosQuery.new(veiculos_filter_params).execute
    render json: result
  end

  # GET /relatorios/veiculos/excel
  def veiculos_excel
    @dados = Relatorios::VeiculosQuery.new(veiculos_filter_params).execute
    @modelo = veiculos_filter_params[:modelo] || 'RG'
    @titulo = titulo_veiculos(@modelo)
    filename = "veiculos_#{Date.current.strftime('%Y%m%d')}.xlsx"

    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render template: 'relatorios/veiculos_excel',
           formats: [:xlsx],
           handlers: [:axlsx]
  end

  # GET /relatorios/veiculos/pdf
  def veiculos_pdf
    @dados = Relatorios::VeiculosQuery.new(veiculos_filter_params).execute
    @modelo = veiculos_filter_params[:modelo] || 'RG'
    @titulo = titulo_veiculos(@modelo)
    @data_geracao = Time.current.strftime('%d/%m/%Y às %H:%M')

    html = render_to_string(
      template: 'relatorios/veiculos_pdf',
      layout: 'pdf',
      locals: { dados: @dados, titulo: @titulo, data_geracao: @data_geracao, modelo: @modelo }
    )

    pdf = Grover.new(html, format: 'A4', print_background: true).to_pdf

    send_data pdf,
              filename: "veiculos_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  private

  def set_filters
    @filters = filter_params
  end

  def filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final, :status,
      acoes: [], locais: [], status: []
    ).to_h.symbolize_keys

    # Normalizar status para array
    if permitted[:status].is_a?(String)
      permitted[:status] = [permitted[:status]]
    end
    permitted[:status] ||= []

    # Garantir arrays vazios
    permitted[:acoes] ||= []
    permitted[:locais] ||= []

    permitted
  end

  def participacao_filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final, :contrato_numero, :codigo,
      eventos: [], status: []
    ).to_h.symbolize_keys

    # Normalizar status para array
    if permitted[:status].is_a?(String)
      permitted[:status] = [permitted[:status]]
    end
    permitted[:status] ||= []

    # Garantir arrays vazios
    permitted[:eventos] ||= []

    permitted
  end

  def available_reports
    [
      {
        id: 'historico_eventos',
        nome: 'Histórico por Ação',
        descricao: 'Relatório de reciclagens agrupadas por ação/evento',
        icone: 'DocumentChartBarIcon',
        path: '/relatorios/historico_eventos'
      },
      {
        id: 'historico_participacao',
        nome: 'Histórico por Participação',
        descricao: 'Relatório de participações em reciclagens por beneficiário',
        icone: 'UserGroupIcon',
        path: '/relatorios/historico_participacao'
      },
      {
        id: 'historico_residuos',
        nome: 'Histórico de Resíduos',
        descricao: 'Relatório detalhado de resíduos coletados',
        icone: 'ArchiveBoxIcon',
        path: '/relatorios/historico_residuos'
      },
      {
        id: 'historico_reciclador_evento',
        nome: 'Reciclador por Evento',
        descricao: 'Histórico de resíduos coletados por reciclador em cada evento',
        icone: 'TruckIcon',
        path: '/relatorios/historico_reciclador_evento'
      },
      {
        id: 'historico_fatura_reciclador',
        nome: 'Fatura do Reciclador',
        descricao: 'Fatura de resíduos por reciclador ou repasse à concessionária',
        icone: 'DocumentCurrencyDollarIcon',
        path: '/relatorios/historico_fatura_reciclador'
      },
      {
        id: 'campanhas',
        nome: 'Campanhas',
        descricao: 'Relatório de participantes e bônus por campanha',
        icone: 'MegaphoneIcon',
        path: '/relatorios/campanhas'
      }
    ]
  end

  def acoes_options
    Acao.includes(:projeto).order(:nome).map do |a|
      { value: a.id, label: "#{a.nome} (#{a.projeto&.nome})" }
    end
  end

  def comunidades_options
    Comunidade.ativos.order(:nome).map do |c|
      { value: c.id, label: c.nome }
    end
  end

  def modelos_options
    [
      { value: 'RT', label: 'Resumo de Totais' },
      { value: 'RD', label: 'Reciclagens Detalhadas' },
      { value: 'RML', label: 'Resumo de Totais Mensais Por Local' },
      { value: 'RMLT', label: 'Resumo de Totais Mensais Por Local/Tipologia' }
    ]
  end

  def status_options
    [
      { value: '-X', label: 'Todos exceto Cancelados' },
      { value: 'R', label: 'Recebidos' },
      { value: 'T', label: 'Transmitidos' },
      { value: 'P', label: 'Processados' },
      { value: 'X', label: 'Cancelados' }
    ]
  end

  def eventos_options
    Evento.includes(:acao, :comunidade)
          .order(data_inicial: :desc)
          .limit(500)
          .map do |e|
      label = "#{e.acao&.nome} - #{e.comunidade&.nome} (#{e.data_inicial&.strftime('%d/%m/%Y')})"
      { value: e.id, label: label }
    end
  end

  def participacao_modelos_options
    [
      { value: 'DG', label: 'Dados Gerais' },
      { value: 'AR', label: 'Agrupado por Resíduo' }
    ]
  end

  def residuos_filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final,
      acoes: [], locais: [], recursos: [], status: []
    ).to_h.symbolize_keys

    # Normalizar status para array
    if permitted[:status].is_a?(String)
      permitted[:status] = [permitted[:status]]
    end
    permitted[:status] ||= []

    # Garantir arrays vazios
    permitted[:acoes] ||= []
    permitted[:locais] ||= []
    permitted[:recursos] ||= []

    permitted
  end

  def recursos_options
    Recurso.where(status: 'A').order(:nome).map do |r|
      { value: r.id, label: r.nome }
    end
  end

  def residuos_modelos_options
    [
      { value: 'RR', label: 'Resíduos da Reciclagem (Detalhado)' },
      { value: 'RT', label: 'Resíduos por Tipologia (Agrupado)' }
    ]
  end

  def recicladores_options
    Reciclador.where(status: 'A').order(:nome).map do |r|
      { value: r.id, label: r.nome }
    end
  end

  def reciclador_evento_filter_params
    permitted = params.permit(
      :reciclador, :data_inicial, :data_final,
      eventos: [], status: []
    ).to_h.symbolize_keys

    # Normalizar status para array
    if permitted[:status].is_a?(String)
      permitted[:status] = [permitted[:status]]
    end
    permitted[:status] ||= []

    # Garantir arrays vazios
    permitted[:eventos] ||= []

    permitted
  end

  def fatura_options
    [
      { value: '', label: 'Todos' },
      { value: 'N', label: 'Não recebe' },
      { value: 'E', label: 'E-mail' },
      { value: 'W', label: 'Whatsapp' }
    ]
  end

  def projetos_options
    Projeto.where(status: 'A').order(:nome).map do |p|
      { value: p.id, label: p.nome }
    end
  end

  def tipos_acao_options
    TipoAcao.order(:nome).map do |t|
      { value: t.id, label: t.nome }
    end
  end

  def fatura_reciclador_modelos_options
    [
      { value: 'TR', label: 'Total por Resíduo' },
      { value: 'RC', label: 'Repasse à Concessionária' }
    ]
  end

  def fatura_reciclador_filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final,
      recicladores: [], recursos: []
    ).to_h.symbolize_keys

    # Garantir arrays vazios
    permitted[:recicladores] ||= []
    permitted[:recursos] ||= []

    permitted
  end

  def campanhas_options
    Campanha.order(:nome).map do |c|
      { value: c.id, label: c.nome }
    end
  end

  def campanhas_modelos_options
    [
      { value: 'RT', label: 'Resumo de Totais' },
      { value: 'PD', label: 'Participantes x Data de Inscrição' },
      { value: 'TP', label: 'Totais por Participante' }
    ]
  end

  def campanhas_filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final,
      campanhas: []
    ).to_h.symbolize_keys

    # Garantir arrays vazios
    permitted[:campanhas] ||= []

    permitted
  end

  def titulo_campanhas(modelo)
    case modelo
    when 'RT'
      'Campanhas - Resumo de Totais'
    when 'PD'
      'Campanhas - Participantes x Data de Inscrição'
    when 'TP'
      'Campanhas - Totais por Participante'
    else
      'Campanhas'
    end
  end

  # ========== Helpers Veiculos ==========

  def tipo_veiculos_options
    TipoVeiculo.ordered.map do |tv|
      { value: tv.id, label: tv.descricao }
    end
  end

  def veiculos_placas_options
    Veiculo.ordered.map do |v|
      { value: v.id, label: "#{v.placa} - #{v.tipo_veiculo&.descricao}" }
    end
  end

  def tipo_recursos_options
    TipoRecurso.order(:nome).map do |tr|
      { value: tr.id, label: tr.nome }
    end
  end

  def locais_options
    Comunidade.order(:nome).map do |c|
      { value: c.id, label: c.nome }
    end
  end

  def veiculos_modelos_options
    [
      { value: 'RG', label: 'Geral' },
      { value: 'RR', label: 'Por Tipo de Resíduo' },
      { value: 'RV', label: 'Por Veículo' },
      { value: 'RL', label: 'Por Local' }
    ]
  end

  def veiculos_status_options
    [
      { value: '-X', label: 'Todos (exceto Cancelados)' },
      { value: 'R', label: 'Recebidos' },
      { value: 'T', label: 'Transmitidos' },
      { value: 'P', label: 'Processados' },
      { value: 'X', label: 'Cancelados' }
    ]
  end

  def veiculos_filter_params
    permitted = params.permit(
      :modelo, :data_inicial, :data_final,
      tipo_veiculo: [], placa: [], recurso: [], local: [], status: []
    ).to_h.symbolize_keys

    # Normalizar status para array
    if permitted[:status].is_a?(String)
      permitted[:status] = [permitted[:status]]
    end
    permitted[:status] ||= []

    # Garantir arrays vazios
    permitted[:tipo_veiculo] ||= []
    permitted[:placa] ||= []
    permitted[:recurso] ||= []
    permitted[:local] ||= []

    permitted
  end

  def titulo_veiculos(modelo)
    case modelo
    when 'RG'
      'Veículos - Geral'
    when 'RR'
      'Veículos - Por Tipo de Resíduo'
    when 'RV'
      'Veículos - Por Veículo'
    when 'RL'
      'Veículos - Por Local'
    else
      'Veículos'
    end
  end
end
