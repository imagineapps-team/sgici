# frozen_string_literal: true

# Controller para Eventos Logisticos
class EventosLogisticosController < InertiaController
  before_action :set_evento, only: [:show, :destroy]

  TIPOS = {
    'embarque' => 'Embarque',
    'transito' => 'Em Transito',
    'chegada_porto' => 'Chegada ao Porto',
    'desembaraco' => 'Desembaraco Aduaneiro',
    'liberacao' => 'Liberacao',
    'entrega' => 'Entrega',
    'atraso' => 'Atraso',
    'avaria' => 'Avaria',
    'outros' => 'Outros'
  }.freeze

  def index
    @eventos = EventoLogistico.includes(:processo_importacao, :criado_por)
                              .order(data_evento: :desc)

    # Filtros
    @eventos = @eventos.where(processo_importacao_id: params[:processo_id]) if params[:processo_id].present?
    @eventos = @eventos.where(tipo: params[:tipo]) if params[:tipo].present?

    render inertia: 'eventos_logisticos/EventosLogisticosIndex', props: {
      eventos: @eventos.limit(100).map { |e| evento_list_json(e) },
      filters: {
        processoId: params[:processo_id],
        tipo: params[:tipo]
      },
      processoOptions: processo_options,
      tipoOptions: tipo_options
    }
  end

  def show
    render inertia: 'eventos_logisticos/EventosLogisticosShow', props: {
      evento: evento_detail_json(@evento)
    }
  end

  def create
    @evento = EventoLogistico.new(evento_params)
    @evento.criado_por = current_usuario

    if @evento.save
      redirect_path = @evento.processo_importacao_id ? processo_importacao_path(@evento.processo_importacao_id) : eventos_logisticos_path
      redirect_to redirect_path, notice: 'Evento registrado com sucesso!'
    else
      redirect_to eventos_logisticos_path, alert: @evento.errors.full_messages.join(', ')
    end
  end

  def destroy
    processo_id = @evento.processo_importacao_id
    @evento.destroy
    redirect_path = processo_id ? processo_importacao_path(processo_id) : eventos_logisticos_path
    redirect_to redirect_path, notice: 'Evento excluido com sucesso!'
  end

  private

  def set_evento
    @evento = EventoLogistico.find(params[:id])
  end

  def evento_params
    params.require(:evento_logistico).permit(
      :processo_importacao_id, :tipo, :data_evento, :local, :codigo_local,
      :descricao, :observacoes, :fonte, :numero_tracking,
      :eta_anterior, :eta_atualizado, :dias_atraso
    )
  end

  def evento_list_json(evento)
    {
      id: evento.id,
      processoNumero: evento.processo_importacao&.numero,
      processoId: evento.processo_importacao_id,
      tipo: evento.tipo,
      tipoLabel: TIPOS[evento.tipo] || evento.tipo,
      dataEvento: evento.data_evento&.iso8601,
      local: evento.local,
      descricao: evento.descricao,
      diasAtraso: evento.dias_atraso,
      criadoPor: evento.criado_por&.nome,
      createdAt: evento.created_at.iso8601
    }
  end

  def evento_detail_json(evento)
    evento_list_json(evento).merge(
      codigoLocal: evento.codigo_local,
      observacoes: evento.observacoes,
      fonte: evento.fonte,
      numeroTracking: evento.numero_tracking,
      etaAnterior: evento.eta_anterior&.iso8601,
      etaAtualizado: evento.eta_atualizado&.iso8601,
      dadosRastreamento: evento.dados_rastreamento
    )
  end

  def processo_options
    ProcessoImportacao.ativos.order(:numero).map { |p| { value: p.id, label: p.numero } }
  end

  def tipo_options
    TIPOS.map { |k, v| { value: k, label: v } }
  end
end
